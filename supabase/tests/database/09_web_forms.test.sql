-- Website form storage (web-forms Edge Function): admin-only tables, anonymous
-- consents, Postgres rate-limit fallback.
begin;
\ir _helpers.psql
select plan(10);

select tests.create_user('wf-admin', 'Admin', '{buyer,admin}') as admin \gset
select tests.create_user('wf-user') as usr \gset

-- the Edge Function writes with the service role
select tests.authenticate_service();
insert into public.web_form_submissions (id, form, country, fields, status)
values ('00000000-0000-0000-0000-00000000f001', 'waitlist', 'india', '{"email":"a@b.example","city":"Pune"}', 'pending_confirmation');
select lives_ok($$ insert into public.consents (document, version, email, consent_key, consent_text, form, submission_id)
    values ('email_marketing', 'web', 'a@b.example', 'consent_email', 'Email me updates', 'waitlist', '00000000-0000-0000-0000-00000000f001') $$,
  'consents can be stored for website visitors without an account');
select throws_ok($$ insert into public.consents (document, version) values ('web_form', 'web') $$, '23514', null,
  'a consent must identify someone (user, email, phone or submission)');
insert into public.waitlist_signups (email, city, confirm_token_hash, confirm_expires_at)
values ('a@b.example', 'Pune', 'hash', now() - interval '1 hour');
select throws_ok($$ insert into public.waitlist_signups (email) values ('A@B.example') $$, '23505', null,
  'one waitlist row per email (case-insensitive)');
select is((public.edge_rate_limit_hit('ip:1', 2, 600) ->> 'allowed')::boolean, true, 'rate limit: first hit allowed');
select public.edge_rate_limit_hit('ip:1', 2, 600);
select is((public.edge_rate_limit_hit('ip:1', 2, 600) ->> 'allowed')::boolean, false, 'rate limit: third hit in the window is refused');
select ok((public.edge_rate_limit_hit('ip:2', 2, 600) ->> 'retry_after_seconds')::int between 1 and 600, 'Retry-After seconds returned');

-- visitors and normal users cannot read submissions; admins can
select tests.authenticate_anon();
select throws_ok($$ select count(*) from public.web_form_submissions $$, '42501', null, 'anon has no access to submissions');
select throws_ok($$ select public.edge_rate_limit_hit('x', 1, 60) $$, '42501', null, 'rate-limit function is service-role only');
select tests.authenticate_as(:'usr');
select is((select count(*)::int from public.web_form_submissions), 0, 'normal users see no submissions');
select tests.authenticate_as(:'admin');
select is((select count(*)::int from public.web_form_submissions), 1, 'admins read submissions');

reset role;
select tests.clear_auth();
select private.expire_web_forms();
select * from finish();
rollback;
