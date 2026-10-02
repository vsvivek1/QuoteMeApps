-- 0830 Website forms (web/ sites -> web-forms Edge Function).
-- Anonymous visitors never touch these tables directly: the Edge Function
-- writes with the service role after Turnstile + honeypot + rate limit.
-- Admins read them in the panel (RLS: admin only).
set search_path = public, extensions;

-- consents: also hold consents given on the websites (no account yet) ---------------------------
alter table public.consents alter column user_id drop not null;
alter table public.consents
  add column if not exists email text,
  add column if not exists phone text,
  add column if not exists consent_key text,
  add column if not exists consent_text text,
  add column if not exists form text,
  add column if not exists page text,
  add column if not exists submission_id uuid,
  add column if not exists confirmed_at timestamptz,
  add column if not exists withdrawn_at timestamptz;
alter table public.consents drop constraint if exists consents_document_check;
alter table public.consents add constraint consents_document_check check (document in (
  'terms','privacy','marketing','analytics','whatsapp','seller_terms',
  'email_marketing','seller_contact','account_deletion','web_form'));
alter table public.consents drop constraint if exists consents_subject_check;
alter table public.consents add constraint consents_subject_check
  check (user_id is not null or email is not null or phone is not null or submission_id is not null);
create index if not exists consents_email_idx on public.consents (lower(email)) where email is not null;

-- raw submissions (audit + admin inbox) -----------------------------------------------------------
create table public.web_form_submissions (
  id uuid primary key default gen_random_uuid(),
  form text not null check (form in ('seller_signup','contact','waitlist','account_deletion','trends_contact')),
  country text,
  page text,
  fields jsonb not null default '{}'::jsonb,
  submitted_at timestamptz,
  ip_hash text,
  user_agent text,
  status text not null default 'received'
    check (status in ('received','pending_confirmation','confirmed','handled','spam','expired')),
  lead_id uuid references public.outreach_leads(id) on delete set null,
  handled_by uuid references public.profiles(id) on delete set null,
  handled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index web_form_submissions_form_idx on public.web_form_submissions (form, created_at desc);

-- waitlist with double opt-in ---------------------------------------------------------------------
create table public.waitlist_signups (
  id uuid primary key default gen_random_uuid(),
  email text not null,
  city text,
  postal_code text,
  whatsapp text,
  whatsapp_opt_in_at timestamptz,
  source text,
  status text not null default 'pending' check (status in ('pending','confirmed','unsubscribed','expired')),
  confirm_token_hash text,
  confirm_expires_at timestamptz,
  confirmation_sent_at timestamptz,
  confirmed_at timestamptz,
  unsubscribe_token text not null unique default encode(gen_random_bytes(16), 'hex'),
  unsubscribed_at timestamptz,
  submission_id uuid references public.web_form_submissions(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index waitlist_email_uidx on public.waitlist_signups (lower(email));
create index waitlist_token_idx on public.waitlist_signups (confirm_token_hash) where confirm_token_hash is not null;

-- account deletion requested from the website (Play "delete account" URL requirement) ---------------
create table public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  email text,
  phone text,
  user_id uuid references auth.users(id) on delete set null,
  reason text,
  status text not null default 'pending'
    check (status in ('pending','otp_sent','confirmed','completed','manual_review','expired','rejected')),
  otp_attempts int not null default 0,
  otp_sent_at timestamptz,
  confirmed_at timestamptz,
  completed_at timestamptz,
  submission_id uuid references public.web_form_submissions(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (email is not null or phone is not null)
);
create index account_deletion_requests_status_idx on public.account_deletion_requests (status, created_at);

do $$
declare t text;
begin
  foreach t in array array['web_form_submissions','waitlist_signups','account_deletion_requests'] loop
    perform private.add_updated_at_trigger(('public.' || t)::regclass);
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon', t);
    execute format('grant select, update on public.%I to authenticated', t);
    execute format('grant all on public.%I to service_role', t);
    execute format('create policy %I on public.%I for select to authenticated using (private.is_admin())', t || '_admin_read', t);
    execute format('create policy %I on public.%I for update to authenticated using (private.is_admin()) with check (private.is_admin())',
                   t || '_admin_update', t);
  end loop;
end $$;

-- Fixed-window rate limit for Edge Functions when Upstash is not configured.
-- Returns {allowed, count, retry_after_seconds}. service_role only.
create or replace function public.edge_rate_limit_hit(p_key text, p_limit int, p_window_seconds int)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_window int := greatest(p_window_seconds, 1);
  v_epoch bigint := floor(extract(epoch from now()));
  v_count int;
begin
  insert into public.rate_limits as r (key, window_start, count)
  values ('edge:' || p_key, to_timestamp((v_epoch / v_window) * v_window), 1)
  on conflict (key, window_start) do update set count = r.count + 1
  returning count into v_count;
  return jsonb_build_object('allowed', v_count <= p_limit, 'count', v_count,
                            'retry_after_seconds', v_window - (v_epoch % v_window));
end $$;

-- Expire unconfirmed waitlist sign-ups and deletion requests (no data kept longer than needed).
create or replace function private.expire_web_forms()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_w int; v_d int;
begin
  update public.waitlist_signups set status = 'expired', confirm_token_hash = null
   where status = 'pending' and confirm_expires_at < now();
  get diagnostics v_w = row_count;
  delete from public.waitlist_signups where status = 'expired' and updated_at < now() - interval '30 days';
  update public.account_deletion_requests set status = 'expired'
   where status in ('pending','otp_sent') and created_at < now() - interval '7 days';
  get diagnostics v_d = row_count;
  return jsonb_build_object('waitlist_expired', v_w, 'deletions_expired', v_d);
end $$;

revoke execute on function public.edge_rate_limit_hit(text, int, int) from public, anon, authenticated;
grant execute on function public.edge_rate_limit_hit(text, int, int) to service_role;

do $$
begin
  if to_regnamespace('cron') is null then
    raise notice 'pg_cron not installed: skipping iwant-expire-web-forms';
    return;
  end if;
  execute 'select cron.unschedule(jobid) from cron.job where jobname = $1' using 'iwant-expire-web-forms';
  execute 'select cron.schedule($1, $2, $3)' using 'iwant-expire-web-forms', '45 * * * *', 'select private.expire_web_forms()';
end $$;
