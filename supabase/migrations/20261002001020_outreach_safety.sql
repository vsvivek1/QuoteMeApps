-- 1020 Outreach safety additions (Section 21.2 / 21.5 / 21.8, admin/BACKEND_NEEDS.md 4 and 5):
--   * outreach_business_address setting (admin only). While it is empty or a
--     {{...}} placeholder, outreach_can_send refuses every send
--     ('business_address_missing') and the outreach_events trigger rejects any
--     'sent' row (outreach_business_address_missing).
--   * campaigns are always created paused (draft / paused). Only an admin
--     (admin JWT) can set a campaign to active; the activation is stamped
--     (activated_by / activated_at) and cron sends only for active campaigns
--     carrying that stamp. Leaving 'active' clears it.
--   * brochures.format is 'pdf' | 'image' | 'onepager'; 'png' is accepted as an
--     alias of 'image' and stored as 'image'.
--   * admin_outreach_set_stage: atomic, forward-only stage move (same edges as
--     admin/lib/features/outreach/domain/stage_machine.dart).
set search_path = public, extensions;

-- Business address setting ------------------------------------------------------------------------
insert into public.app_settings (key, value, is_public, description) values
  ('outreach_business_address', '"{{BUSINESS_ADDRESS}}"', false,
   'Physical postal address printed in every outreach email (CAN-SPAM, rule 21.8-8). Sends stay blocked while empty or a {{...}} placeholder')
on conflict (key) do nothing;

create or replace function private.outreach_business_address_ready()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select jsonb_typeof(value) = 'string'
       and length(btrim(value #>> '{}')) >= 10
       and (value #>> '{}') !~ '\{\{|\}\}'
      from public.app_settings where key = 'outreach_business_address'), false)
$$;

-- Campaign activation -----------------------------------------------------------------------------
alter table public.outreach_campaigns
  add column activated_by uuid references public.profiles(id) on delete set null,
  add column activated_at timestamptz;

-- Campaigns that are active without an admin activation (none expected) are
-- paused until an admin activates them explicitly.
update public.outreach_campaigns
   set status = 'paused', paused_reason = 'requires_admin_activation', paused_at = now()
 where status = 'active';

create or replace function private.outreach_campaign_guard()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    -- every new campaign starts paused, whoever creates it
    if new.status not in ('draft','paused') then new.status := 'draft'; end if;
    new.activated_by := null;
    new.activated_at := null;
    return new;
  end if;

  if new.status = 'active' then
    if old.status = 'active' then
      new.activated_by := old.activated_by;   -- the stamp cannot be edited
      new.activated_at := old.activated_at;
    else
      if not private.is_admin() then
        raise exception using errcode = 'PT403', message = 'campaign_activation_requires_admin';
      end if;
      new.activated_by := auth.uid();
      new.activated_at := now();
      new.paused_reason := null;
      new.paused_at := null;
    end if;
  else
    new.activated_by := null;
    new.activated_at := null;
  end if;
  return new;
end $$;

create trigger outreach_campaign_guard
  before insert or update on public.outreach_campaigns
  for each row execute function private.outreach_campaign_guard();

-- The single gate every message passes (0820 version plus the business
-- address and admin-activation checks).
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
  if not private.outreach_business_address_ready() then
    return query select false, 'business_address_missing'; return;
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
  if c.activated_by is null then return query select false, 'campaign_not_activated'; return; end if;

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

-- Hard rules re-checked on every 'sent' insert (0820 version plus the
-- business address and the active, admin-activated campaign).
create or replace function private.outreach_events_before_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  l public.outreach_leads;
  c public.outreach_campaigns;
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
    if not private.outreach_business_address_ready() then
      raise exception using errcode = 'PT409', message = 'outreach_business_address_missing';
    end if;
    new.campaign_id := coalesce(new.campaign_id, l.campaign_id);
    select * into c from public.outreach_campaigns where id = new.campaign_id;
    if c.id is null or c.status <> 'active' or c.activated_by is null then
      raise exception using errcode = 'PT409', message = 'outreach_campaign_not_active';
    end if;
    new.reason_chosen := coalesce(new.reason_chosen, l.chosen_reason);
    new.address_source := coalesce(new.address_source, l.address_source);
    new.lawful_basis := coalesce(new.lawful_basis, l.lawful_basis);
    new.sequence_step := coalesce(new.sequence_step, l.touches_sent + 1);
  end if;
  return new;
end $$;

-- Brochure formats: align on 'image' ('png' is an accepted alias) -------------------------------------
create or replace function private.brochure_normalize_format()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.format := case lower(btrim(new.format))
                  when 'png' then 'image'
                  when 'one_pager' then 'onepager'
                  else lower(btrim(new.format)) end;
  return new;
end $$;

create trigger brochure_normalize_format
  before insert or update of format on public.brochures
  for each row execute function private.brochure_normalize_format();

-- Atomic stage move -------------------------------------------------------------------------------
-- Mirrors StageMachine (admin/lib/features/outreach/domain/stage_machine.dart):
--   sourced        -> contacted, replied, not_interested, do_not_contact
--   contacted      -> replied, onboarding, not_interested, do_not_contact
--   replied        -> onboarding, not_interested, do_not_contact
--   onboarding     -> live_seller, not_interested, do_not_contact
--   live_seller    -> active, do_not_contact
--   active         -> do_not_contact
--   not_interested -> replied, do_not_contact
--   do_not_contact -> (none: permanent)
-- live_seller / active need a linked seller; a manual move to contacted needs
-- a logged touch (whatsapp_manual, call_logged or visit_logged event). Moves to
-- replied/onboarding/live_seller/active/not_interested stop a running
-- sequence; do_not_contact stops it and adds the business to suppression_list.
-- Errors (PT409 unless noted): stage_no_change, stage_terminal, stage_not_allowed,
-- stage_needs_seller_link, stage_needs_logged_contact; 400 invalid_stage; 404 lead_not_found.
create or replace function private.outreach_stage_edges(p_from text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case p_from
    when 'sourced' then array['contacted','replied','not_interested','do_not_contact']
    when 'contacted' then array['replied','onboarding','not_interested','do_not_contact']
    when 'replied' then array['onboarding','not_interested','do_not_contact']
    when 'onboarding' then array['live_seller','not_interested','do_not_contact']
    when 'live_seller' then array['active','do_not_contact']
    when 'active' then array['do_not_contact']
    when 'not_interested' then array['replied','do_not_contact']
    else array[]::text[] end
$$;

create or replace function public.admin_outreach_set_stage(p_lead_id uuid, p_stage text, p_note text default null)
returns public.outreach_leads
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_admin uuid := private.require_admin();
  l public.outreach_leads;
  v_from text;
  v_stop boolean := false;
  v_suppress boolean := p_stage = 'do_not_contact';
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if p_stage is null or p_stage not in ('sourced','contacted','replied','onboarding','live_seller','active',
                                        'not_interested','do_not_contact') then
    perform private.raise_error('invalid_stage', 400, p_stage);
  end if;
  select * into l from public.outreach_leads where id = p_lead_id for update;
  if not found then perform private.raise_error('lead_not_found', 404); end if;
  v_from := l.stage;

  if v_from = p_stage then perform private.raise_error('stage_no_change', 409); end if;
  if v_from = 'do_not_contact' then perform private.raise_error('stage_terminal', 409); end if;
  if not p_stage = any(private.outreach_stage_edges(v_from)) then
    perform private.raise_error('stage_not_allowed', 409, v_from || '->' || p_stage);
  end if;
  if p_stage in ('live_seller','active') and l.seller_id is null then
    perform private.raise_error('stage_needs_seller_link', 409);
  end if;
  if p_stage = 'contacted' and not exists (
       select 1 from public.outreach_events e
        where e.lead_id = l.id and e.event_type in ('whatsapp_manual','call_logged','visit_logged')) then
    perform private.raise_error('stage_needs_logged_contact', 409);
  end if;
  v_stop := v_suppress
            or (p_stage in ('replied','onboarding','live_seller','active','not_interested')
                and l.sequence_status in ('active','none'));

  perform set_config('iwant.audit_skip_stage', 'on', true);
  update public.outreach_leads
     set stage = p_stage,
         sequence_status = case when v_stop then 'stopped' else sequence_status end,
         contacted_at = case when p_stage = 'contacted' then coalesce(contacted_at, now()) else contacted_at end
   where id = l.id
  returning * into l;
  perform set_config('iwant.audit_skip_stage', '', true);

  if v_suppress then
    insert into public.suppression_list (email, phone, business_key, reason, source, note)
    values (lower(l.email), l.phone, l.business_key, 'do_not_contact', 'admin_stage_change', v_note)
    on conflict do nothing;
    -- an earlier row for the same email/phone must not leave the business key unsuppressed
    insert into public.suppression_list (business_key, reason, source, note)
    values (l.business_key, 'do_not_contact', 'admin_stage_change', v_note)
    on conflict do nothing;
  end if;

  insert into public.outreach_events (lead_id, campaign_id, channel, event_type, body_preview, meta, created_by)
  values (l.id, l.campaign_id, 'system', 'stage_change', left(v_note, 500),
          jsonb_build_object('from', v_from, 'to', p_stage, 'via', 'admin_outreach_set_stage'), v_admin);

  perform private.audit('admin_outreach_set_stage', 'outreach_lead', l.id::text,
    jsonb_build_object('from', v_from, 'to', p_stage, 'note', v_note, 'business_name', l.business_name,
                       'stopped_sequence', v_stop, 'suppressed', v_suppress));

  select * into l from public.outreach_leads where id = l.id;
  return l;
end $$;

revoke all on function private.outreach_business_address_ready(), private.outreach_campaign_guard(),
  private.brochure_normalize_format(), private.outreach_stage_edges(text) from public, anon;
grant execute on function private.outreach_business_address_ready() to authenticated, service_role;
revoke execute on function public.admin_outreach_set_stage(uuid, text, text) from public, anon;
grant execute on function public.admin_outreach_set_stage(uuid, text, text) to authenticated, service_role;
