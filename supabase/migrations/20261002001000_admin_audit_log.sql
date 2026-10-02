-- 1000 Admin audit log (admin/BACKEND_NEEDS.md item 1).
--
-- Append-only record of every privileged action. It is written ONLY server
-- side: by the admin_* RPCs (private.audit, see 1010) and by triggers on the
-- admin-relevant tables below. Clients (including admins) can read it through
-- admin-only RLS but can never insert, update or delete, so it cannot be
-- forged from the panel.
set search_path = public, extensions;

create table public.admin_audit_log (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles(id) on delete set null,
  actor_email text,
  action text not null,          -- e.g. admin_review_document, admin_set_setting, outreach_stage_change
  target_type text,              -- document | licence | report | user | seller | category | keyword | setting
                                 -- | entitlement | outreach_lead | outreach_campaign | suppression | brochure
  target_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index admin_audit_log_created_idx on public.admin_audit_log (created_at desc);
create index admin_audit_log_target_idx on public.admin_audit_log (target_type, target_id, created_at desc);
create index admin_audit_log_actor_idx on public.admin_audit_log (actor_id, created_at desc);

select private.add_updated_at_trigger('public.admin_audit_log');
alter table public.admin_audit_log enable row level security;
revoke all on public.admin_audit_log from public, anon, authenticated, service_role;
grant select on public.admin_audit_log to authenticated;
grant select, insert on public.admin_audit_log to service_role;
create policy admin_audit_log_admin_read on public.admin_audit_log
  for select to authenticated using (private.is_admin());

-- Append-only. The only permitted update is the FK's own "on delete set null"
-- of actor_id (when a profile row is removed); everything else is refused,
-- whoever the caller is (service_role included).
create or replace function private.admin_audit_log_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
     and new.actor_id is null
     and (new.id, new.actor_email, new.action, new.target_type, new.target_id, new.details, new.created_at)
         is not distinct from
         (old.id, old.actor_email, old.action, old.target_type, old.target_id, old.details, old.created_at) then
    return new;
  end if;
  raise exception using errcode = 'PT403', message = 'audit_log_append_only';
end $$;

create trigger admin_audit_log_append_only
  before update or delete on public.admin_audit_log
  for each row execute function private.admin_audit_log_append_only();

-- Writer used by every admin RPC and audit trigger. actor = the JWT subject
-- (null for service_role / cron / webhooks, recorded as details.via = 'system').
create or replace function private.audit(
  p_action text, p_target_type text default null, p_target_id text default null,
  p_details jsonb default '{}'::jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_actor uuid;
  v_email text;
begin
  if v_uid is not null then
    select p.id, coalesce(nullif(auth.jwt() ->> 'email', ''), p.email)
      into v_actor, v_email
      from public.profiles p where p.id = v_uid;
  end if;
  insert into public.admin_audit_log (actor_id, actor_email, action, target_type, target_id, details)
  values (v_actor, v_email, p_action, p_target_type, p_target_id,
          coalesce(p_details, '{}'::jsonb)
            || case when v_actor is null
                    then jsonb_build_object('via', coalesce(nullif(auth.role(), ''), 'system'))
                    else '{}'::jsonb end);
end $$;
revoke all on function private.audit(text, text, text, jsonb) from public, anon, authenticated;

-- Audit triggers on admin-relevant tables -------------------------------------------------------

-- outreach_leads: every stage change (manual, RPC or automatic). The atomic
-- admin_outreach_set_stage RPC writes its own richer row and sets
-- iwant.audit_skip_stage for the duration of its update so the change is not
-- logged twice.
create or replace function private.audit_outreach_lead_stage()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.stage is distinct from old.stage
     and coalesce(current_setting('iwant.audit_skip_stage', true), '') <> 'on' then
    perform private.audit('outreach_stage_change', 'outreach_lead', new.id::text,
      jsonb_build_object('from', old.stage, 'to', new.stage, 'business_name', new.business_name,
                         'sequence_status', new.sequence_status));
  end if;
  return null;
end $$;

create trigger audit_outreach_lead_stage
  after update of stage on public.outreach_leads
  for each row execute function private.audit_outreach_lead_stage();

-- suppression_list: every insert (opt-outs, bounces, complaints, admin adds).
create or replace function private.audit_suppression_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.audit('suppression_add', 'suppression', new.id::text,
    jsonb_strip_nulls(jsonb_build_object('email', new.email, 'email_domain', new.email_domain, 'phone', new.phone,
                       'business_key', new.business_key, 'reason', new.reason, 'source', new.source,
                       'note', new.note)));
  return null;
end $$;

create trigger audit_suppression_insert
  after insert on public.suppression_list
  for each row execute function private.audit_suppression_insert();

-- outreach_campaigns: creation and every status change (activation, manual
-- pause, automatic brakes, content-check pauses).
create or replace function private.audit_outreach_campaign()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    perform private.audit('outreach_campaign_create', 'outreach_campaign', new.id::text,
      jsonb_build_object('name', new.name, 'status', new.status, 'daily_cap', new.daily_cap));
  elsif new.status is distinct from old.status then
    perform private.audit('outreach_campaign_status', 'outreach_campaign', new.id::text,
      jsonb_strip_nulls(jsonb_build_object('name', new.name, 'from', old.status, 'to', new.status,
                                           'paused_reason', new.paused_reason)));
  end if;
  return null;
end $$;

create trigger audit_outreach_campaign
  after insert or update of status on public.outreach_campaigns
  for each row execute function private.audit_outreach_campaign();

-- brochures: every new version uploaded.
create or replace function private.audit_brochure_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.audit('brochure_create', 'brochure', new.id::text,
    jsonb_strip_nulls(jsonb_build_object('city_name', new.city_name, 'state', new.state,
                                         'category_id', new.category_id, 'language', new.language,
                                         'format', new.format, 'version', new.version,
                                         'storage_path', new.storage_path)));
  return null;
end $$;

create trigger audit_brochure_insert
  after insert on public.brochures
  for each row execute function private.audit_brochure_insert();

revoke all on function private.admin_audit_log_append_only(), private.audit_outreach_lead_stage(),
  private.audit_suppression_insert(), private.audit_outreach_campaign(), private.audit_brochure_insert()
  from public, anon, authenticated;
