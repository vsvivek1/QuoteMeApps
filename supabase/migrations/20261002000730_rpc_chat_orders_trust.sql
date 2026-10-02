-- 0730 Chat, notifications inbox, orders, reviews, reports, account deletion.
set search_path = public, extensions;

-- Chat -----------------------------------------------------------------------------------------
-- Buyer: pass p_seller_id (a seller who quoted or was invited).
-- Seller: omit p_seller_id; allowed once they have quoted on the request.
create or replace function public.get_or_create_chat(p_request_id uuid, p_seller_id uuid default null)
returns public.chats
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_req public.requests;
  v_seller uuid;
  v_chat public.chats;
begin
  select * into v_req from public.requests where id = p_request_id;
  if not found then perform private.raise_error('request_not_found', 404); end if;

  if v_req.buyer_id = v_uid then
    v_seller := p_seller_id;
    if v_seller is null then perform private.raise_error('seller_required', 400); end if;
  else
    v_seller := v_uid;
  end if;

  if not (exists (select 1 from public.quotes q where q.request_id = p_request_id and q.seller_id = v_seller)
          or v_req.inviting_seller_id = v_seller) then
    perform private.raise_error('chat_not_allowed', 403, 'Seller has not quoted on this request');
  end if;
  if private.is_blocked_between(v_req.buyer_id, v_seller) then
    perform private.raise_error('blocked', 403);
  end if;

  perform private.ensure_chat(p_request_id, v_seller);
  select * into v_chat from public.chats where request_id = p_request_id and seller_id = v_seller;
  return v_chat;
end $$;

-- Alias kept for readability in the app ("open chat").
create or replace function public.open_chat(p_request_id uuid, p_seller_id uuid default null)
returns public.chats
language sql
security definer
set search_path = ''
as $$
  select * from public.get_or_create_chat(p_request_id, p_seller_id)
$$;

-- Marks the other party's messages as read; returns how many changed.
create or replace function public.mark_read(p_chat_id uuid, p_up_to timestamptz default null)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_n int;
begin
  if not private.is_chat_member(p_chat_id) then
    perform private.raise_error('chat_not_found', 404);
  end if;
  update public.messages set read_at = now()
   where chat_id = p_chat_id and read_at is null
     and (sender_id is distinct from v_uid)
     and created_at <= coalesce(p_up_to, now());
  get diagnostics v_n = row_count;
  return v_n;
end $$;

-- Before insert: flag phone numbers / emails shared before acceptance (warn, don't block).
create or replace function private.messages_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_awarded boolean;
begin
  if new.type = 'text' and new.body is not null then
    select (r.status = 'awarded') into v_awarded
      from public.chats c join public.requests r on r.id = c.request_id where c.id = new.chat_id;
    new.contains_contact := not coalesce(v_awarded, false) and (
      new.body ~* '[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}'
      or regexp_replace(new.body, '[\s().-]', '', 'g') ~ '(\+?\d{10,13})');
  end if;
  new.read_at := null;
  new.hidden := false;
  return new;
end $$;

create or replace trigger messages_before_insert
  before insert on public.messages
  for each row execute function private.messages_before_insert();

-- After insert: bump chat, notify the other party (merged per chat).
create or replace function private.messages_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_chat public.chats;
  v_to uuid;
begin
  update public.chats
     set last_message_at = new.created_at,
         last_message_preview = case when new.type = 'text' then left(new.body, 120) else '[' || new.type || ']' end
   where id = new.chat_id
  returning * into v_chat;
  if new.sender_id is not null then
    v_to := case when new.sender_id = v_chat.buyer_id then v_chat.seller_id else v_chat.buyer_id end;
    perform private.notify(v_to, 'message',
      jsonb_build_object('chat_id', new.chat_id, 'request_id', v_chat.request_id, 'message_id', new.id,
                         'preview', case when new.type = 'text' then left(new.body, 80) end,
                         'route', '/chat/' || new.chat_id),
      'chat:' || new.chat_id);
  end if;
  return null;
end $$;

create or replace trigger messages_after_insert
  after insert on public.messages
  for each row execute function private.messages_after_insert();

-- Notifications inbox -------------------------------------------------------------------------------
create or replace function public.mark_notifications_read(p_ids uuid[] default null)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare v_n int;
begin
  update public.notifications set read_at = now()
   where user_id = auth.uid() and read_at is null and (p_ids is null or id = any(p_ids));
  get diagnostics v_n = row_count;
  return v_n;
end $$;

-- Orders ---------------------------------------------------------------------------------------------
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
  if p_method not in ('cash','upi','card','bank_transfer','zelle','seller_link','other') then
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

-- Allowed transitions. Seller drives fulfilment; either party may complete
-- once delivered (buyer may also confirm completion earlier) or cancel
-- before dispatch.
create or replace function public.update_order_status(
  p_order_id uuid, p_status text, p_note text default null, p_scheduled_for timestamptz default null)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_order public.orders;
  v_is_seller boolean;
  v_ok boolean;
  v_other uuid;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or v_uid not in (v_order.buyer_id, v_order.seller_id) then
    perform private.raise_error('order_not_found', 404);
  end if;
  v_is_seller := v_uid = v_order.seller_id;
  v_ok := case
    when v_order.status in ('completed','cancelled') then false
    when p_status = 'scheduled' then v_is_seller and v_order.status = 'accepted'
    when p_status = 'dispatched' then v_is_seller and v_order.status in ('accepted','scheduled')
    when p_status = 'delivered' then v_is_seller and v_order.status in ('accepted','scheduled','dispatched')
    when p_status = 'completed' then
      (v_is_seller and v_order.status = 'delivered')
      or (not v_is_seller and v_order.status in ('accepted','scheduled','dispatched','delivered'))
    when p_status = 'cancelled' then v_order.status in ('accepted','scheduled')
    else false end;
  if not v_ok then
    perform private.raise_error('invalid_status_transition', 409, v_order.status || '->' || p_status);
  end if;
  update public.orders
     set status = p_status,
         scheduled_for = coalesce(p_scheduled_for, scheduled_for),
         completed_at = case when p_status = 'completed' then now() else completed_at end,
         cancelled_reason = case when p_status = 'cancelled' then left(p_note, 500) else cancelled_reason end
   where id = p_order_id returning * into v_order;
  insert into public.order_events (order_id, status, actor_id, note)
  values (p_order_id, p_status, v_uid, left(p_note, 500));
  v_other := case when v_is_seller then v_order.buyer_id else v_order.seller_id end;
  perform private.notify(v_other, 'order_status',
    jsonb_build_object('order_id', p_order_id, 'status', p_status, 'request_id', v_order.request_id,
                       'route', '/orders/' || p_order_id));
  if p_status = 'completed' then
    perform private.notify(v_order.buyer_id, 'review_reminder',
      jsonb_build_object('order_id', p_order_id, 'route', '/orders/' || p_order_id || '/review'),
      null, now() + interval '2 hours');
  end if;
  return v_order;
end $$;

-- Contact details unlocked by acceptance (both directions).
create or replace function public.get_order_contacts(p_order_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id;
  if not found or v_uid not in (v_order.buyer_id, v_order.seller_id) or v_order.status = 'cancelled' then
    perform private.raise_error('order_not_found', 404);
  end if;
  return jsonb_build_object(
    'buyer', (select jsonb_build_object('name', p.name, 'phone', coalesce(rp.buyer_phone, p.phone),
                                        'full_address', rp.full_address)
                from public.profiles p
                left join public.request_private rp on rp.request_id = v_order.request_id
               where p.id = v_order.buyer_id),
    'seller', (select jsonb_build_object('business_name', s.business_name,
                                         'phone', coalesce(sc.business_phone, p.phone),
                                         'email', sc.business_email, 'website', sc.website,
                                         'address_line', sc.address_line)
                 from public.sellers s join public.profiles p on p.id = s.id
                 left join public.seller_contacts sc on sc.seller_id = s.id
                where s.id = v_order.seller_id));
end $$;

-- Reviews --------------------------------------------------------------------------------------------
create or replace function private.refresh_seller_rating(p_seller_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.sellers s
     set rating_avg = coalesce(x.avg, 0), rating_count = coalesce(x.cnt, 0)
    from (select round(avg(stars)::numeric, 2) as avg, count(*)::int as cnt
            from public.reviews where to_id = p_seller_id and role = 'buyer_to_seller' and not hidden) x
   where s.id = p_seller_id
$$;

create or replace function public.submit_review(
  p_order_id uuid, p_stars int, p_tags text[] default '{}', p_text text default null, p_photos text[] default '{}')
returns public.reviews
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_order public.orders;
  v_review public.reviews;
  v_role text;
  v_to uuid;
begin
  select * into v_order from public.orders where id = p_order_id;
  if not found or v_uid not in (v_order.buyer_id, v_order.seller_id) then
    perform private.raise_error('order_not_found', 404);
  end if;
  if v_order.status <> 'completed' then
    perform private.raise_error('order_not_completed', 409);
  end if;
  if p_stars not between 1 and 5 then
    perform private.raise_error('invalid_stars', 400);
  end if;
  if v_uid = v_order.buyer_id then
    v_role := 'buyer_to_seller'; v_to := v_order.seller_id;
  else
    v_role := 'seller_to_buyer'; v_to := v_order.buyer_id;
  end if;
  insert into public.reviews (order_id, from_id, to_id, role, stars, tags, text, photos)
  values (p_order_id, v_uid, v_to, v_role, p_stars, coalesce(p_tags[1:10], '{}'), p_text, coalesce(p_photos[1:6], '{}'))
  on conflict (order_id, role) do nothing
  returning * into v_review;
  if v_review.id is null then
    perform private.raise_error('already_reviewed', 409);
  end if;
  if v_role = 'buyer_to_seller' then
    perform private.refresh_seller_rating(v_to);
  end if;
  perform private.notify(v_to, 'new_review',
    jsonb_build_object('review_id', v_review.id, 'order_id', p_order_id, 'stars', p_stars,
                       'route', '/reviews/' || v_review.id));
  return v_review;
end $$;

create or replace function public.seller_reply_review(p_review_id uuid, p_reply text)
returns public.reviews
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_review public.reviews;
begin
  select * into v_review from public.reviews where id = p_review_id for update;
  if not found or v_review.to_id <> v_uid or v_review.role <> 'buyer_to_seller' then
    perform private.raise_error('review_not_found', 404);
  end if;
  if v_review.seller_reply is not null then
    perform private.raise_error('already_replied', 409);
  end if;
  if coalesce(trim(p_reply), '') = '' then
    perform private.raise_error('reply_required', 400);
  end if;
  update public.reviews set seller_reply = left(trim(p_reply), 1000), seller_replied_at = now()
   where id = p_review_id returning * into v_review;
  return v_review;
end $$;

-- Reports and auto-hide ------------------------------------------------------------------------------------
create or replace function private.set_target_hidden(p_type text, p_id uuid, p_hidden boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  case p_type
    when 'request' then update public.requests set hidden = p_hidden where id = p_id;
    when 'quote' then update public.quotes set hidden = p_hidden where id = p_id;
    when 'message' then update public.messages set hidden = p_hidden where id = p_id;
    when 'review' then
      update public.reviews set hidden = p_hidden where id = p_id;
      perform private.refresh_seller_rating(r.to_id) from public.reviews r where r.id = p_id and r.role = 'buyer_to_seller';
    when 'seller' then update public.sellers set hidden = p_hidden where id = p_id;
    else null; -- 'user': admins decide (suspend/ban)
  end case;
end $$;

create or replace function public.report_content(
  p_target_type text, p_target_id uuid, p_reason text, p_details text default null)
returns public.reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := private.require_user();
  v_report public.reports;
  v_count int;
begin
  if p_target_type not in ('request','quote','message','review','seller','user') then
    perform private.raise_error('invalid_target_type', 400);
  end if;
  if p_reason not in ('spam','fraud','abusive','inappropriate','prohibited_item','fake','other') then
    perform private.raise_error('invalid_reason', 400);
  end if;
  -- rate limit reports per user
  if not private.rate_limit_hit('report:' || v_uid, 30, 3600) then
    perform private.raise_error('rate_limited', 429);
  end if;
  insert into public.reports (reporter_id, target_type, target_id, reason, details)
  values (v_uid, p_target_type, p_target_id, p_reason, left(p_details, 2000))
  on conflict (reporter_id, target_type, target_id) do update set reason = excluded.reason, details = excluded.details
  returning * into v_report;

  select count(distinct reporter_id) into v_count from public.reports
   where target_type = p_target_type and target_id = p_target_id and status = 'open';
  if v_count >= private.setting_int('auto_hide_report_threshold', 3) then
    perform private.set_target_hidden(p_target_type, p_target_id, true);
  end if;
  return v_report;
end $$;

-- Account deletion -----------------------------------------------------------------------------------------
-- Deletes / anonymizes the caller's personal data. Orders, quotes and reviews
-- are kept (tax / dispute records) but no longer point to personal details.
-- The delete-account Edge Function calls this with the user's JWT, then
-- soft-deletes the auth user and revokes the Apple token.
create or replace function private.anonymize_user(p_uid uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_req int; v_quotes int;
begin
  update public.requests set status = 'cancelled', closed_at = now()
   where buyer_id = p_uid and status = 'open';
  get diagnostics v_req = row_count;
  update public.quotes set status = 'withdrawn'
   where seller_id = p_uid and status in ('sent','revised','shortlisted');
  get diagnostics v_quotes = row_count;
  update public.requests r set quote_count = (select count(*) from public.quotes q
     where q.request_id = r.id and q.status in ('sent','revised','shortlisted','accepted','declined'))
   where r.status = 'open' and r.id in (select request_id from public.quotes where seller_id = p_uid);

  update public.request_private rp set full_address = null, buyer_phone = null, exact_location = null
    from public.requests r where r.id = rp.request_id and r.buyer_id = p_uid;
  update public.requests set description = null, fields = '{}'::jsonb, reference_url = null
   where buyer_id = p_uid and status <> 'awarded';
  delete from public.request_media m using public.requests r where r.id = m.request_id and r.buyer_id = p_uid;
  delete from public.addresses where user_id = p_uid;
  delete from public.device_tokens where user_id = p_uid;
  delete from public.notifications where user_id = p_uid;
  delete from public.blocks where blocker_id = p_uid;
  delete from public.lead_states where seller_id = p_uid;
  delete from public.quote_templates where seller_id = p_uid;
  update public.messages set body = null, attachment_path = null, type = 'system', hidden = true
   where sender_id = p_uid;
  update public.reviews set text = null, photos = '{}' where from_id = p_uid;

  update public.sellers
     set hidden = true, business_name = 'Deleted business', logo_url = null, photos = '{}',
         description = null, brands = '{}', center = null, service_codes = '{}',
         area_type = 'nationwide', radius_km = null
   where id = p_uid;
  delete from public.seller_contacts where seller_id = p_uid;
  delete from public.seller_categories where seller_id = p_uid;
  update public.seller_documents set doc_number = null, file_path = null where seller_id = p_uid;
  update public.seller_licences set file_path = null where seller_id = p_uid;

  update public.profiles
     set name = null, phone = null, email = null, photo_url = null, status = 'deleted',
         deleted_at = now(), roles = '{}', notification_prefs = '{"push":false}'::jsonb
   where id = p_uid;

  return jsonb_build_object('cancelled_requests', v_req, 'withdrawn_quotes', v_quotes);
end $$;

create or replace function public.delete_my_account()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then perform private.raise_error('not_authenticated', 401); end if;
  return private.anonymize_user(v_uid);
end $$;
