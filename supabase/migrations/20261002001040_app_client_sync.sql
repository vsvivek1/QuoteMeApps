-- 1040 Small contract additions for the Flutter app:
--   a) messages.client_id: idempotent retries of queued messages
--   b) chats.request_title / orders.request_title: denormalised request title
--      (sellers cannot read requests under RLS), kept in sync by triggers
--   c) orders in the supabase_realtime publication (RLS-filtered)
--   d) public settings web_purchase_links_allowed, paywall_default_period,
--      whatsapp_notifications (returned by get_app_settings)
--   e) payment method 'check' (USA) for record_payment
--   f) categories.field_schema has one shape: {"version": 1, "fields": [...]}
set search_path = public, extensions;

-- a) messages.client_id ---------------------------------------------------------------------------------
-- The app generates a uuid per outgoing message and retries with
--   from('messages').upsert({..., client_id}, onConflict: 'chat_id,client_id', ignoreDuplicates: true)
-- i.e. INSERT ... ON CONFLICT (chat_id, client_id) DO NOTHING. NULLs stay distinct,
-- so rows without a client_id (system messages, older clients) are unaffected.
alter table public.messages add column client_id uuid;
create unique index messages_chat_client_uidx on public.messages (chat_id, client_id);
grant insert (chat_id, sender_id, type, body, attachment_path, client_id) on public.messages to authenticated;

-- b) request_title on chats and orders --------------------------------------------------------------------
alter table public.chats add column request_title text;
alter table public.orders add column request_title text;
update public.chats c set request_title = r.title from public.requests r where r.id = c.request_id;
update public.orders o set request_title = r.title from public.requests r where r.id = o.request_id;

-- request_title always mirrors the request: set on insert, and on update it can only
-- become the request's current title (the sync trigger below), so it cannot be edited.
create or replace function private.set_request_title()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.request_id is not distinct from old.request_id
     and new.request_title is not distinct from old.request_title then
    return new;
  end if;
  new.request_title := (select r.title from public.requests r where r.id = new.request_id);
  return new;
end $$;

create trigger chats_request_title before insert or update on public.chats
  for each row execute function private.set_request_title();
create trigger orders_request_title before insert or update on public.orders
  for each row execute function private.set_request_title();

create or replace function private.sync_request_title()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.chats set request_title = new.title where request_id = new.id and request_title is distinct from new.title;
  update public.orders set request_title = new.title where request_id = new.id and request_title is distinct from new.title;
  return null;
end $$;

create trigger requests_sync_title after update of title on public.requests
  for each row when (new.title is distinct from old.title)
  execute function private.sync_request_title();

-- c) orders in realtime ----------------------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
  if not exists (select 1 from pg_publication_tables
                  where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'orders') then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;

-- d) public settings ------------------------------------------------------------------------------------
insert into public.app_settings (key, value, is_public, description) values
  ('web_purchase_links_allowed', 'false', true,
   'Show external web purchase links (Stripe / Razorpay checkout) in the apps; keep false unless store rules allow it'),
  ('paywall_default_period', '"annual"', true, 'Plan period preselected on the paywall: monthly | annual'),
  ('whatsapp_notifications', 'false', true, 'Offer opted-in WhatsApp notifications (approved templates only)')
on conflict (key) do nothing;

-- admin_set_setting validation for the new keys (1010 version + these checks)
create or replace function private.validate_app_setting(p_key text, p_value jsonb)
returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if p_key in ('web_purchase_links_allowed','whatsapp_notifications') and jsonb_typeof(p_value) <> 'boolean' then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;
  if p_key = 'paywall_default_period'
     and (jsonb_typeof(p_value) <> 'string' or (p_value #>> '{}') not in ('monthly','annual')) then
    perform private.raise_error('invalid_setting_value', 400, p_key);
  end if;
end $$;

create or replace function private.app_settings_validate()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  perform private.validate_app_setting(new.key, new.value);
  return new;
end $$;

create trigger app_settings_validate before insert or update of value on public.app_settings
  for each row execute function private.app_settings_validate();

-- e) payment method 'check' ---------------------------------------------------------------------------
alter table public.orders drop constraint if exists orders_payment_method_check;
alter table public.orders add constraint orders_payment_method_check
  check (payment_method in ('cash','upi','card','bank_transfer','zelle','check','seller_link','other'));

create or replace function public.record_payment(p_order_id uuid, p_method text, p_amount_minor bigint)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_uid not in (v_order.buyer_id, v_order.seller_id) then
    perform private.raise_error('order_not_found', 404);
  end if;
  if v_order.status = 'cancelled' then
    perform private.raise_error('order_cancelled', 409);
  end if;
  if p_method is null or p_method not in ('cash','upi','card','bank_transfer','zelle','check','seller_link','other') then
    perform private.raise_error('invalid_payment_method', 400);
  end if;
  if p_amount_minor is null or p_amount_minor < 0 then
    perform private.raise_error('invalid_amount', 400);
  end if;
  update public.orders
     set payment_method = p_method, payment_amount_minor = p_amount_minor, payment_recorded_at = now()
   where id = p_order_id returning * into v_order;
  insert into public.order_events (order_id, status, actor_id, note)
  values (p_order_id, 'payment_recorded', v_uid, p_method || ':' || p_amount_minor);
  return v_order;
end $$;

-- f) field_schema shape ------------------------------------------------------------------------------
-- One shape everywhere (private.validate_fields, seeds, admin editor, app):
--   {"version": 1, "fields": [{"key", "type", "label", "required", "scope", "options", "min", "max", "unit"}]}
-- A bare array is rejected (the app mapper still reads both).
alter table public.categories add constraint categories_field_schema_shape check (
  field_schema is null
  or (jsonb_typeof(field_schema) = 'object' and jsonb_typeof(field_schema -> 'fields') = 'array'));

revoke all on function private.set_request_title(), private.sync_request_title(),
  private.app_settings_validate() from public, anon, authenticated;
revoke all on function private.validate_app_setting(text, jsonb) from public, anon;
