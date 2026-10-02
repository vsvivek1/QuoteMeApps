-- 0820 Seller acquisition CRM (Section 21.1-21.5) with the anti-spam
-- rulebook (21.8) enforced in the database wherever possible:
--   * at most 3 touches per business, ever (check constraints + trigger)
--   * one business = one conversation (unique business_key + dedupe indexes;
--     a finished/stopped sequence is never restarted automatically)
--   * shared suppression list checked by every send (trigger)
--   * audit trail required on every send (check constraint)
--   * WhatsApp/SMS only after recorded opt-in, max one marketing msg / week
--   * per-inbox warm-up caps, per-domain caps, global daily ceiling, weekday
--     business hours and automatic brakes (outreach_can_send / check_brakes)
-- All tables are admin-only (RLS) and also used by Edge Functions (service role).
set search_path = public, extensions;

create table public.outreach_inboxes (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  display_name text not null,
  provider text not null check (provider in ('resend','ses','brevo')),
  daily_cap_start int not null default 20 check (daily_cap_start between 1 and 50),
  daily_cap_max int not null default 150 check (daily_cap_max between 1 and 500),
  ramp_per_week int not null default 10 check (ramp_per_week between 0 and 50),
  warmup_started_on date not null default current_date,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- steps: [{"step":1,"delay_days":0,"include_brochure":false,
--          "variants":[{"subject":"...","body":"..."}]}, ...]  (max 3 steps)
create table public.outreach_sequences (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  channel text not null default 'email' check (channel in ('email','whatsapp')),
  language text not null default 'en',
  steps jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint outreach_sequences_max_3_touches
    check (jsonb_typeof(steps) = 'array' and jsonb_array_length(steps) between 1 and 3),
  constraint outreach_sequences_no_attachment_first
    check (not coalesce((steps->0->>'include_brochure')::boolean, false))
);

create table public.outreach_campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sequence_id uuid not null references public.outreach_sequences(id),
  status text not null default 'draft' check (status in ('draft','active','paused','completed')),
  category_ids bigint[] not null default '{}',
  states text[] not null default '{}',
  city_ids bigint[] not null default '{}',
  inbox_ids uuid[] not null default '{}',
  daily_cap int not null default 50 check (daily_cap between 0 and 1000),
  paused_reason text,
  paused_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.outreach_leads (
  id uuid primary key default gen_random_uuid(),
  business_key text not null unique, -- normalized: domain | phone | place_id | osm | name+postal
  business_name text not null,
  categories_source text[] not null default '{}', -- raw OSM / Places types
  matched_category_ids bigint[] not null default '{}', -- relevance (21.8 rule 1)
  email text,
  email_domain text generated always as (lower(split_part(email, '@', 2))) stored,
  email_status text not null default 'unverified'
    check (email_status in ('unverified','valid','invalid','disposable','role_bounced')),
  address_source text, -- URL/page where the business published the address (rule 3/11)
  phone text,
  website text,
  website_domain text,
  place_id text,
  osm_id text,
  address text,
  city text,
  city_id bigint references public.cities(id) on delete set null,
  state text,
  postal_code text,
  location geography(Point, 4326),
  timezone text,
  rating numeric(2,1),
  rating_count int,
  source text not null check (source in ('osm','places','registry','website','inbound','referral','manual','field')),
  source_ref text,
  lawful_basis text not null check (lawful_basis in ('legitimate_interest','consent','public_registry','inbound_request')),
  chosen_reason text, -- why this business was chosen (rule 11)
  stage text not null default 'sourced' check (stage in
    ('sourced','contacted','replied','onboarding','live_seller','active','not_interested','do_not_contact')),
  owner_id uuid references public.profiles(id) on delete set null,
  next_action text,
  next_action_due date,
  notes text,
  priority int, -- copied from cities.priority; lower first
  campaign_id uuid references public.outreach_campaigns(id) on delete set null,
  sequence_status text not null default 'none' check (sequence_status in ('none','active','completed','stopped')),
  touches_sent int not null default 0,
  contacted_at timestamptz,
  last_contacted_at timestamptz,
  sequence_completed_at timestamptz,
  remind_after timestamptz,
  whatsapp_opt_in_at timestamptz,
  whatsapp_opt_in_channel text,
  whatsapp_opt_in_proof text,
  whatsapp_last_marketing_at timestamptz,
  signup_token text unique default encode(gen_random_bytes(12), 'hex'),
  unsubscribe_token text unique default encode(gen_random_bytes(16), 'hex'),
  seller_id uuid references public.sellers(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint outreach_leads_max_3_touches check (touches_sent between 0 and 3),
  constraint outreach_leads_whatsapp_proof check (whatsapp_opt_in_at is null or whatsapp_opt_in_channel is not null)
);
create unique index outreach_leads_place_uidx on public.outreach_leads (place_id) where place_id is not null;
create unique index outreach_leads_osm_uidx on public.outreach_leads (osm_id) where osm_id is not null;
create unique index outreach_leads_phone_uidx on public.outreach_leads (phone) where phone is not null;
create unique index outreach_leads_domain_uidx on public.outreach_leads (website_domain) where website_domain is not null;
create unique index outreach_leads_email_uidx on public.outreach_leads (lower(email)) where email is not null;
create index outreach_leads_stage_idx on public.outreach_leads (stage, state, city);
create index outreach_leads_queue_idx on public.outreach_leads (campaign_id, priority nulls last, created_at)
  where sequence_status in ('none','active');

create table public.outreach_events (
  id uuid primary key default gen_random_uuid(),
  lead_id uuid not null references public.outreach_leads(id) on delete cascade,
  campaign_id uuid references public.outreach_campaigns(id) on delete set null,
  inbox_id uuid references public.outreach_inboxes(id) on delete set null,
  channel text not null check (channel in ('email','whatsapp','call','visit','sms','system')),
  event_type text not null check (event_type in (
    'sent','delivered','clicked','replied','negative_reply','not_now','bounced','soft_bounced',
    'complained','unsubscribed','whatsapp_manual','call_logged','visit_logged','note','stage_change')),
  sequence_step int check (sequence_step between 1 and 3),
  template_variant int,
  subject text,
  body_preview text,
  recipient text,
  recipient_domain text,
  provider_message_id text,
  reason_chosen text,
  address_source text,
  lawful_basis text,
  meta jsonb not null default '{}'::jsonb,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- audit trail (rule 11): every automated send records why, where from, and on what basis
  constraint outreach_events_sent_audit check (
    event_type <> 'sent' or (reason_chosen is not null and lawful_basis is not null
                             and sequence_step is not null
                             and (channel <> 'email' or (address_source is not null and recipient is not null))))
);
create index outreach_events_lead_idx on public.outreach_events (lead_id, created_at);
create index outreach_events_sent_day_idx on public.outreach_events (created_at, inbox_id, recipient_domain)
  where event_type = 'sent';
create index outreach_events_campaign_idx on public.outreach_events (campaign_id, event_type, created_at);
create unique index outreach_events_provider_msg_uidx on public.outreach_events (provider_message_id)
  where provider_message_id is not null and event_type = 'sent';

create table public.suppression_list (
  id uuid primary key default gen_random_uuid(),
  email text,
  email_domain text, -- set with email null to suppress a whole domain
  phone text,
  business_key text,
  reason text not null check (reason in
    ('unsubscribe','hard_bounce','complaint','negative_reply','manual','do_not_contact','deletion_request')),
  source text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (coalesce(email, email_domain, phone, business_key) is not null)
);
create unique index suppression_email_uidx on public.suppression_list (lower(email)) where email is not null;
create unique index suppression_domain_uidx on public.suppression_list (lower(email_domain))
  where email is null and email_domain is not null;
create unique index suppression_phone_uidx on public.suppression_list (phone) where phone is not null;
create unique index suppression_business_uidx on public.suppression_list (business_key) where business_key is not null;

create table public.brochures (
  id uuid primary key default gen_random_uuid(),
  city_id bigint references public.cities(id) on delete set null,
  city_name text not null,
  state text,
  category_id bigint references public.categories(id) on delete set null,
  language text not null default 'en',
  format text not null check (format in ('pdf','image','onepager')),
  storage_path text not null, -- brochures bucket (public)
  public_url text,
  signup_url text,
  utm jsonb not null default '{}'::jsonb,
  version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (city_name, state, category_id, language, format, version)
);

do $$
declare t text;
begin
  foreach t in array array['outreach_inboxes','outreach_sequences','outreach_campaigns','outreach_leads',
                           'outreach_events','suppression_list','brochures'] loop
    perform private.add_updated_at_trigger(('public.' || t)::regclass);
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
    execute format('grant all on public.%I to service_role', t);
    execute format('create policy %I on public.%I for all to authenticated using (private.is_admin()) with check (private.is_admin())',
                   t || '_admin_only', t);
  end loop;
end $$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('brochures', 'brochures', true, 10485760, array['application/pdf','image/png','image/jpeg','image/webp'])
on conflict (id) do nothing;
create policy "brochures public read" on storage.objects for select to anon, authenticated
  using (bucket_id = 'brochures');
create policy "brochures admin write" on storage.objects for insert to authenticated
  with check (bucket_id = 'brochures' and private.is_admin());
create policy "brochures admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'brochures' and private.is_admin());

-- Helpers ------------------------------------------------------------------------------------------------
create or replace function private.require_admin_or_service()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if coalesce(auth.role(), '') = 'service_role' then return; end if;
  -- direct database sessions (SQL editor, pg_cron, seeds) carry no JWT
  if auth.jwt() is null and session_user in ('postgres', 'supabase_admin') then return; end if;
  perform private.require_admin();
end $$;

create or replace function public.outreach_is_suppressed(
  p_email text default null, p_phone text default null, p_business_key text default null)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.suppression_list s
     where (p_email is not null and s.email is not null and lower(s.email) = lower(p_email))
        or (p_email is not null and s.email is null and s.email_domain is not null
            and lower(s.email_domain) = lower(split_part(p_email, '@', 2)))
        or (p_phone is not null and s.phone = p_phone)
        or (p_business_key is not null and s.business_key = p_business_key))
$$;

create or replace function private.outreach_inbox_daily_cap(p_inbox_id uuid, p_at timestamptz default now())
returns int
language sql
stable
security definer
set search_path = ''
as $$
  select least(i.daily_cap_max,
               i.daily_cap_start + i.ramp_per_week * greatest(0, ((p_at::date - i.warmup_started_on) / 7)))
    from public.outreach_inboxes i where i.id = p_inbox_id and i.active
$$;

create or replace function private.outreach_in_business_hours(p_tz text, p_at timestamptz)
returns boolean
language plpgsql
stable
set search_path = ''
as $$
declare v_local timestamp;
begin
  v_local := p_at at time zone coalesce(nullif(p_tz, ''), private.setting_text('default_timezone', 'UTC'));
  return extract(isodow from v_local) between 1 and 5
     and v_local::time between time '09:30' and time '17:00';
exception when others then
  return false;
end $$;

-- The single gate every automated message passes. Returns (allowed, reason).
create or replace function public.outreach_can_send(
  p_lead_id uuid, p_channel text default 'email', p_inbox_id uuid default null, p_at timestamptz default now())
returns table (allowed boolean, reason text)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  l public.outreach_leads;
  c public.outreach_campaigns;
  v_steps jsonb;
  v_delay int;
  v_sent_today int;
  v_cap int;
  v_day_start timestamptz := date_trunc('day', p_at);
begin
  perform private.require_admin_or_service();
  if not private.setting_bool('outreach_enabled', false) then
    return query select false, 'outreach_disabled'; return;
  end if;
  select * into l from public.outreach_leads where id = p_lead_id;
  if not found then return query select false, 'lead_not_found'; return; end if;
  if public.outreach_is_suppressed(l.email, l.phone, l.business_key) then
    return query select false, 'suppressed'; return;
  end if;
  if l.seller_id is not null then return query select false, 'already_seller'; return; end if;
  if l.stage not in ('sourced','contacted') then return query select false, 'stage_' || l.stage; return; end if;
  if l.touches_sent >= 3 then return query select false, 'max_touches'; return; end if;
  if l.sequence_status in ('completed','stopped') then return query select false, 'conversation_finished'; return; end if;
  if l.remind_after is not null and l.remind_after > p_at then return query select false, 'remind_later'; return; end if;
  if cardinality(l.matched_category_ids) = 0 then return query select false, 'not_relevant'; return; end if;

  if p_channel = 'email' then
    if l.email is null then return query select false, 'no_email'; return; end if;
    if l.email_status <> 'valid' then return query select false, 'email_not_verified'; return; end if;
    if l.address_source is null then return query select false, 'unknown_address_source'; return; end if;
  elsif p_channel in ('whatsapp','sms') then
    if l.whatsapp_opt_in_at is null then return query select false, 'no_opt_in'; return; end if;
    if l.whatsapp_last_marketing_at is not null and l.whatsapp_last_marketing_at > p_at - interval '7 days' then
      return query select false, 'weekly_cap'; return;
    end if;
  else
    return query select false, 'channel_not_automated'; return;
  end if;

  if l.campaign_id is null then return query select false, 'no_campaign'; return; end if;
  select * into c from public.outreach_campaigns where id = l.campaign_id;
  if c.status <> 'active' then return query select false, 'campaign_' || c.status; return; end if;

  -- next step due?
  select steps into v_steps from public.outreach_sequences where id = c.sequence_id;
  if l.touches_sent >= jsonb_array_length(v_steps) then
    return query select false, 'sequence_done'; return;
  end if;
  v_delay := coalesce((v_steps->l.touches_sent->>'delay_days')::int, 0);
  if l.last_contacted_at is not null and l.last_contacted_at + make_interval(days => greatest(v_delay, 1)) > p_at then
    return query select false, 'not_due'; return;
  end if;

  if not private.outreach_in_business_hours(l.timezone, p_at) then
    return query select false, 'outside_business_hours'; return;
  end if;

  -- volume caps (never lift automatically)
  select count(*) into v_sent_today from public.outreach_events e
   where e.event_type = 'sent' and e.channel = p_channel and e.created_at >= v_day_start;
  if v_sent_today >= private.setting_int('outreach_global_daily_cap', 50) then
    return query select false, 'global_daily_cap'; return;
  end if;
  select count(*) into v_sent_today from public.outreach_events e
   where e.event_type = 'sent' and e.campaign_id = c.id and e.created_at >= v_day_start;
  if v_sent_today >= c.daily_cap then return query select false, 'campaign_daily_cap'; return; end if;
  if p_channel = 'email' then
    select count(*) into v_sent_today from public.outreach_events e
     where e.event_type = 'sent' and e.recipient_domain = l.email_domain and e.created_at >= v_day_start;
    if v_sent_today >= private.setting_int('outreach_per_domain_daily_cap', 2) then
      return query select false, 'domain_daily_cap'; return;
    end if;
    if p_inbox_id is not null then
      v_cap := private.outreach_inbox_daily_cap(p_inbox_id, p_at);
      if v_cap is null then return query select false, 'inbox_inactive'; return; end if;
      select count(*) into v_sent_today from public.outreach_events e
       where e.event_type = 'sent' and e.inbox_id = p_inbox_id and e.created_at >= v_day_start;
      if v_sent_today >= v_cap then return query select false, 'inbox_daily_cap'; return; end if;
    end if;
  end if;
  return query select true, 'ok';
end $$;

-- Hard rules re-checked on every 'sent' insert, whatever code path inserts it.
create or replace function private.outreach_events_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare l public.outreach_leads;
begin
  select * into l from public.outreach_leads where id = new.lead_id for update;
  new.recipient_domain := coalesce(new.recipient_domain, lower(split_part(new.recipient, '@', 2)));
  if new.event_type = 'sent' then
    if public.outreach_is_suppressed(coalesce(new.recipient, l.email), l.phone, l.business_key) then
      raise exception using errcode = 'PT409', message = 'outreach_suppressed';
    end if;
    if l.touches_sent >= 3 then
      raise exception using errcode = 'PT409', message = 'outreach_max_touches';
    end if;
    if l.sequence_status in ('completed','stopped') or l.stage not in ('sourced','contacted') or l.seller_id is not null then
      raise exception using errcode = 'PT409', message = 'outreach_conversation_finished';
    end if;
    if new.channel = 'email' and l.email_status <> 'valid' then
      raise exception using errcode = 'PT409', message = 'outreach_email_not_verified';
    end if;
    if new.channel in ('whatsapp','sms') and l.whatsapp_opt_in_at is null then
      raise exception using errcode = 'PT409', message = 'outreach_no_opt_in';
    end if;
    if new.channel in ('call','visit') then
      raise exception using errcode = 'PT400', message = 'outreach_use_logged_event_types';
    end if;
    new.reason_chosen := coalesce(new.reason_chosen, l.chosen_reason);
    new.address_source := coalesce(new.address_source, l.address_source);
    new.lawful_basis := coalesce(new.lawful_basis, l.lawful_basis);
    new.sequence_step := coalesce(new.sequence_step, l.touches_sent + 1);
  end if;
  return new;
end $$;

create or replace trigger outreach_events_before_insert
  before insert on public.outreach_events
  for each row execute function private.outreach_events_before_insert();

create or replace function private.outreach_events_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  l public.outreach_leads;
  v_steps int;
begin
  select * into l from public.outreach_leads where id = new.lead_id;
  case new.event_type
    when 'sent' then
      select jsonb_array_length(s.steps) into v_steps
        from public.outreach_campaigns c join public.outreach_sequences s on s.id = c.sequence_id
       where c.id = coalesce(new.campaign_id, l.campaign_id);
      update public.outreach_leads
         set touches_sent = touches_sent + 1,
             contacted_at = coalesce(contacted_at, new.created_at),
             last_contacted_at = new.created_at,
             stage = case when stage = 'sourced' then 'contacted' else stage end,
             sequence_status = case when touches_sent + 1 >= coalesce(v_steps, 3) then 'completed' else 'active' end,
             sequence_completed_at = case when touches_sent + 1 >= coalesce(v_steps, 3) then now() end,
             whatsapp_last_marketing_at = case when new.channel in ('whatsapp','sms') then new.created_at
                                               else whatsapp_last_marketing_at end
       where id = new.lead_id;
    when 'replied' then
      update public.outreach_leads set stage = 'replied', sequence_status = 'stopped',
             next_action = 'reply', next_action_due = current_date
       where id = new.lead_id and stage in ('sourced','contacted');
    when 'not_now' then
      update public.outreach_leads set sequence_status = 'stopped', remind_after = now() + interval '3 months',
             next_action = 'remind (asked: not now)', next_action_due = (now() + interval '3 months')::date
       where id = new.lead_id;
    when 'negative_reply' then
      insert into public.suppression_list (email, phone, business_key, reason, source)
      values (l.email, null, l.business_key, 'negative_reply', 'outreach_event:' || new.id)
      on conflict do nothing;
    when 'unsubscribed' then
      insert into public.suppression_list (email, phone, business_key, reason, source)
      values (l.email, case when new.channel in ('whatsapp','sms') then l.phone end, l.business_key,
              'unsubscribe', 'outreach_event:' || new.id)
      on conflict do nothing;
    when 'complained' then
      insert into public.suppression_list (email, business_key, reason, source)
      values (l.email, l.business_key, 'complaint', 'outreach_event:' || new.id)
      on conflict do nothing;
    when 'bounced' then -- hard bounce = permanent suppression
      update public.outreach_leads set email_status = 'invalid' where id = new.lead_id;
      insert into public.suppression_list (email, business_key, reason, source)
      values (coalesce(new.recipient, l.email), l.business_key, 'hard_bounce', 'outreach_event:' || new.id)
      on conflict do nothing;
    else null;
  end case;
  if new.event_type in ('bounced','complained','negative_reply') and coalesce(new.campaign_id, l.campaign_id) is not null then
    perform public.outreach_check_brakes(coalesce(new.campaign_id, l.campaign_id));
  end if;
  return null;
end $$;

-- Suppression always wins: stop every matching lead immediately.
create or replace function private.suppression_after_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.outreach_leads
     set stage = case when stage in ('live_seller','active','onboarding') then stage else 'do_not_contact' end,
         sequence_status = case when sequence_status = 'active' or sequence_status = 'none' then 'stopped' else sequence_status end
   where (new.email is not null and lower(email) = lower(new.email))
      or (new.email is null and new.email_domain is not null and email_domain = lower(new.email_domain))
      or (new.phone is not null and phone = new.phone)
      or (new.business_key is not null and business_key = new.business_key);
  return null;
end $$;

create or replace trigger suppression_after_insert
  after insert on public.suppression_list
  for each row execute function private.suppression_after_insert();

-- Automatic brakes (rule 7): pause the campaign when bounce > 2 %,
-- complaints > 0.08 % or negative replies > 5 % (last 30 days).
create or replace function public.outreach_check_brakes(p_campaign_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sent int; v_bounce int; v_complaint int; v_negative int;
  v_reason text;
begin
  perform private.require_admin_or_service();
  select count(*) filter (where event_type = 'sent'),
         count(*) filter (where event_type = 'bounced'),
         count(*) filter (where event_type = 'complained'),
         count(*) filter (where event_type = 'negative_reply')
    into v_sent, v_bounce, v_complaint, v_negative
    from public.outreach_events
   where campaign_id = p_campaign_id and created_at > now() - interval '30 days';

  if v_sent > 0 then
    if 100.0 * v_complaint / v_sent > private.setting_text('outreach_complaint_brake_pct', '0.08')::numeric then
      v_reason := 'complaint_rate';
    elsif 100.0 * v_bounce / v_sent > private.setting_text('outreach_bounce_brake_pct', '2')::numeric then
      v_reason := 'bounce_rate';
    elsif 100.0 * v_negative / v_sent > private.setting_text('outreach_negative_brake_pct', '5')::numeric then
      v_reason := 'negative_reply_rate';
    end if;
  end if;

  if v_reason is not null then
    update public.outreach_campaigns
       set status = 'paused', paused_reason = 'auto_brake:' || v_reason, paused_at = now()
     where id = p_campaign_id and status = 'active';
    if found then
      perform private.notify(p.id, 'outreach_brake',
        jsonb_build_object('campaign_id', p_campaign_id, 'reason', v_reason, 'route', '/admin/outreach'))
        from public.profiles p where 'admin' = any(p.roles) and p.status = 'active';
    end if;
  end if;
  return jsonb_build_object('sent', v_sent, 'bounced', v_bounce, 'complained', v_complaint,
                            'negative', v_negative, 'paused_reason', v_reason);
end $$;

create or replace trigger outreach_events_after_insert
  after insert on public.outreach_events
  for each row execute function private.outreach_events_after_insert();

-- Next leads to contact for a campaign (DB rules applied; the Edge Function
-- applies content rules and re-checks outreach_can_send per lead).
create or replace function public.outreach_next_batch(p_campaign_id uuid, p_limit int default 20, p_at timestamptz default now())
returns table (lead_id uuid, business_name text, email text, city text, state text, timezone text,
               matched_category_ids bigint[], rating numeric, next_step int, unsubscribe_token text,
               signup_token text, chosen_reason text)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform private.require_admin_or_service();
  return query
  select l.id, l.business_name, l.email, l.city, l.state, l.timezone, l.matched_category_ids, l.rating,
         l.touches_sent + 1, l.unsubscribe_token, l.signup_token, l.chosen_reason
    from public.outreach_leads l
   where l.campaign_id = p_campaign_id
     and l.sequence_status in ('none','active')
     and l.stage in ('sourced','contacted')
     and l.touches_sent < 3
     and l.email is not null and l.email_status = 'valid'
     and (select allowed from public.outreach_can_send(l.id, 'email', null, p_at))
   order by l.priority nulls last, l.touches_sent desc, l.created_at
   limit least(greatest(p_limit, 1), 200);
end $$;

create or replace function public.outreach_record_send(
  p_lead_id uuid, p_campaign_id uuid, p_inbox_id uuid, p_channel text, p_step int, p_variant int,
  p_subject text, p_body_preview text, p_recipient text, p_provider_message_id text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_id uuid;
begin
  perform private.require_admin_or_service();
  insert into public.outreach_events (lead_id, campaign_id, inbox_id, channel, event_type, sequence_step,
                                      template_variant, subject, body_preview, recipient, provider_message_id)
  values (p_lead_id, p_campaign_id, p_inbox_id, p_channel, 'sent', p_step, p_variant, p_subject,
          left(p_body_preview, 500), p_recipient, p_provider_message_id)
  returning id into v_id;
  return v_id;
end $$;

-- Webhook / reply events. Finds the lead by provider message id, else by email.
create or replace function public.outreach_record_event(
  p_event_type text, p_provider_message_id text default null, p_email text default null,
  p_meta jsonb default '{}'::jsonb, p_channel text default 'email')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lead uuid; v_campaign uuid; v_id uuid;
begin
  perform private.require_admin_or_service();
  if p_provider_message_id is not null then
    select lead_id, campaign_id into v_lead, v_campaign from public.outreach_events
     where provider_message_id = p_provider_message_id and event_type = 'sent' limit 1;
  end if;
  if v_lead is null and p_email is not null then
    select id, campaign_id into v_lead, v_campaign from public.outreach_leads where lower(email) = lower(p_email) limit 1;
  end if;
  if v_lead is null then
    -- unknown sender: still honour opt-outs
    if p_email is not null and p_event_type in ('unsubscribed','complained','bounced','negative_reply') then
      insert into public.suppression_list (email, reason, source)
      values (p_email, case p_event_type when 'unsubscribed' then 'unsubscribe' when 'complained' then 'complaint'
                                         when 'bounced' then 'hard_bounce' else 'negative_reply' end, 'webhook')
      on conflict do nothing;
    end if;
    return null;
  end if;
  insert into public.outreach_events (lead_id, campaign_id, channel, event_type, recipient, meta)
  values (v_lead, v_campaign, p_channel, p_event_type, p_email, coalesce(p_meta, '{}'::jsonb))
  returning id into v_id;
  return v_id;
end $$;

-- One-click unsubscribe (List-Unsubscribe) by token.
create or replace function public.outreach_unsubscribe(p_token text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare l public.outreach_leads;
begin
  perform private.require_admin_or_service();
  select * into l from public.outreach_leads where unsubscribe_token = p_token;
  if not found then return false; end if;
  insert into public.outreach_events (lead_id, campaign_id, channel, event_type, recipient)
  values (l.id, l.campaign_id, 'email', 'unsubscribed', l.email);
  return true;
end $$;

-- Lead import (import-leads Edge Function). Returns the lead id, or null
-- when the business already exists under another key (dedupe).
create or replace function public.outreach_upsert_lead(p_lead jsonb)
returns uuid
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare v_id uuid;
begin
  perform private.require_admin_or_service();
  begin
    insert into public.outreach_leads (
      business_key, business_name, categories_source, matched_category_ids, email, address_source,
      phone, website, website_domain, place_id, osm_id, address, city, city_id, state, postal_code,
      location, timezone, rating, rating_count, source, source_ref, lawful_basis, chosen_reason, priority)
    values (
      p_lead->>'business_key', p_lead->>'business_name',
      coalesce(array(select jsonb_array_elements_text(p_lead->'categories_source')), '{}'),
      coalesce(array(select (jsonb_array_elements_text(p_lead->'matched_category_ids'))::bigint), '{}'),
      nullif(p_lead->>'email', ''), p_lead->>'address_source', nullif(p_lead->>'phone', ''),
      p_lead->>'website', nullif(p_lead->>'website_domain', ''), nullif(p_lead->>'place_id', ''),
      nullif(p_lead->>'osm_id', ''), p_lead->>'address', p_lead->>'city', (p_lead->>'city_id')::bigint,
      p_lead->>'state', p_lead->>'postal_code',
      case when p_lead ? 'lat' and p_lead ? 'lng'
           then st_setsrid(st_makepoint((p_lead->>'lng')::float8, (p_lead->>'lat')::float8), 4326)::geography end,
      p_lead->>'timezone', (p_lead->>'rating')::numeric, (p_lead->>'rating_count')::int,
      p_lead->>'source', p_lead->>'source_ref', coalesce(p_lead->>'lawful_basis', 'legitimate_interest'),
      p_lead->>'chosen_reason', (p_lead->>'priority')::int)
    on conflict (business_key) do update set
      categories_source = (select array_agg(distinct x) from unnest(outreach_leads.categories_source || excluded.categories_source) x),
      matched_category_ids = (select array_agg(distinct x) from unnest(outreach_leads.matched_category_ids || excluded.matched_category_ids) x),
      rating = coalesce(excluded.rating, outreach_leads.rating),
      rating_count = coalesce(excluded.rating_count, outreach_leads.rating_count),
      website = coalesce(outreach_leads.website, excluded.website),
      email = coalesce(outreach_leads.email, excluded.email),
      address_source = coalesce(outreach_leads.address_source, excluded.address_source)
    returning id into v_id;
  exception when unique_violation then
    return null; -- same business already known by phone / domain / place / osm id
  end;
  if public.outreach_is_suppressed(p_lead->>'email', p_lead->>'phone', p_lead->>'business_key') then
    update public.outreach_leads set stage = 'do_not_contact', sequence_status = 'stopped' where id = v_id;
  end if;
  return v_id;
end $$;

-- DPDP: delete imported leads never contacted after N days.
create or replace function private.outreach_purge_uncontacted()
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare v_n int;
begin
  delete from public.outreach_leads
   where stage = 'sourced' and contacted_at is null and seller_id is null
     and source not in ('inbound','referral')
     and created_at < now() - make_interval(days => private.setting_int('outreach_uncontacted_retention_days', 90));
  get diagnostics v_n = row_count;
  return v_n;
end $$;

-- Coverage per city x category (sellers), for the CRM dashboard.
create or replace function public.admin_seller_coverage(p_min_sellers int default 5)
returns table (city text, state text, category_id bigint, sellers int, needs_sellers boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
  perform private.require_admin();
  return query
  select s.city, s.state, sc.category_id, count(*)::int, count(*) < p_min_sellers
    from public.sellers s join public.seller_categories sc on sc.seller_id = s.id
   where not s.hidden and s.city is not null
   group by s.city, s.state, sc.category_id
   order by count(*) asc, s.state, s.city;
end $$;

revoke execute on function public.outreach_is_suppressed(text, text, text),
  public.outreach_can_send(uuid, text, uuid, timestamptz),
  public.outreach_check_brakes(uuid),
  public.outreach_next_batch(uuid, int, timestamptz),
  public.outreach_record_send(uuid, uuid, uuid, text, int, int, text, text, text, text),
  public.outreach_record_event(text, text, text, jsonb, text),
  public.outreach_unsubscribe(text),
  public.outreach_upsert_lead(jsonb),
  public.admin_seller_coverage(int)
  from public, anon, authenticated;
grant execute on function public.outreach_is_suppressed(text, text, text),
  public.outreach_can_send(uuid, text, uuid, timestamptz),
  public.outreach_check_brakes(uuid),
  public.outreach_next_batch(uuid, int, timestamptz),
  public.outreach_record_send(uuid, uuid, uuid, text, int, int, text, text, text, text),
  public.outreach_record_event(text, text, text, jsonb, text),
  public.outreach_unsubscribe(text),
  public.outreach_upsert_lead(jsonb),
  public.admin_seller_coverage(int)
  to service_role;
grant execute on function public.outreach_is_suppressed(text, text, text),
  public.outreach_can_send(uuid, text, uuid, timestamptz),
  public.outreach_check_brakes(uuid),
  public.outreach_next_batch(uuid, int, timestamptz),
  public.outreach_record_send(uuid, uuid, uuid, text, int, int, text, text, text, text),
  public.outreach_record_event(text, text, text, jsonb, text),
  public.outreach_upsert_lead(jsonb),
  public.admin_seller_coverage(int)
  to authenticated;
