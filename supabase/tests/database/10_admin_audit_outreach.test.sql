-- Admin audit log, admin_kpis, outreach business address, campaign activation,
-- brochure formats and the admin_outreach_set_stage machine (migrations 1000-1030).
begin;
\ir _helpers.psql
select plan(65);

select tests.create_user('aa-admin', 'Audit Admin', '{buyer,admin}') as admin \gset
select tests.create_user('aa-user', 'Plain User') as usr \gset
select tests.create_user('aa-target', 'Target User') as target \gset
select tests.make_seller('aa-seller') as seller \gset

-- audit log: shape, access ---------------------------------------------------------------------------
select has_table('public', 'admin_audit_log', 'admin_audit_log exists');
select columns_are('public', 'admin_audit_log',
  array['id','actor_id','actor_email','action','target_type','target_id','details','created_at','updated_at'],
  'admin_audit_log has the BACKEND_NEEDS shape');
select is(
  (select array_agg(p.proname::text order by p.proname) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname like 'admin\_%' and p.provolatile = 'v'
      and p.prosrc not like '%private.audit(%'),
  null, 'every data-changing admin_* RPC writes the audit log');

select tests.authenticate_as(:'admin');
select is((public.admin_set_setting('quote_cap', '11')).value, '11'::jsonb, 'admin changes a setting');
select is((select action || '|' || target_type || '|' || target_id || '|' || (details ->> 'to') || '|' || actor_id::text
             from public.admin_audit_log where action = 'admin_set_setting' order by id desc limit 1),
  'admin_set_setting|setting|quote_cap|11|' || :'admin', 'the setting change is logged with actor, target and value');
select is((select actor_email from public.admin_audit_log where action = 'admin_set_setting' order by id desc limit 1),
  'aa-admin@pgtap.invalid', 'actor email recorded');
select lives_ok(format($$ select public.admin_set_user_status(%L, 'suspended', now() + interval '1 day', 'spam') $$, :'target'),
  'admin suspends a user');
select is((select details ->> 'from' || '->' || (details ->> 'to') from public.admin_audit_log
            where action = 'admin_set_user_status' and target_id = :'target'), 'active->suspended',
  'user status change logged with old and new status');
select lives_ok($$ select public.admin_upsert_keyword('zzauditword', 'block') $$, 'admin adds a keyword');
select is((select count(*)::int from public.admin_audit_log where action = 'admin_upsert_keyword' and target_id = 'zzauditword'),
  1, 'keyword change logged');
select ok((select count(*) from public.admin_audit_log) > 0, 'admins read the audit log');
select throws_ok($$ insert into public.admin_audit_log (action) values ('forged') $$, '42501', null,
  'admins cannot write the audit log from the client');
select throws_ok($$ delete from public.admin_audit_log $$, '42501', null, 'admins cannot delete audit rows');

select tests.authenticate_as(:'usr');
select is((select count(*)::int from public.admin_audit_log), 0, 'non-admins see no audit rows');
select throws_ok($$ select public.admin_kpis() $$, 'PT403', 'admin_only', 'admin_kpis is admin only');
select throws_ok(format($$ select public.admin_outreach_set_stage(%L, 'replied', null) $$, gen_random_uuid()),
  'PT403', 'admin_only', 'admin_outreach_set_stage is admin only');
select is((select count(*)::int from public.app_settings where key = 'outreach_business_address'), 0,
  'the business address setting is not public');
select tests.authenticate_anon();
select throws_ok($$ select count(*) from public.admin_audit_log $$, '42501', null, 'anon cannot read the audit log');

select tests.authenticate_service();
select throws_ok($$ update public.admin_audit_log set action = 'x' $$, '42501', null,
  'the service role cannot change audit rows');
reset role;
select tests.clear_auth();
select throws_ok($$ update public.admin_audit_log set action = 'x' $$, 'PT403', 'audit_log_append_only',
  'the audit log is append-only even for the table owner');
select throws_ok($$ delete from public.admin_audit_log $$, 'PT403', 'audit_log_append_only',
  'audit rows cannot be deleted');

-- business address placeholder blocks sends ----------------------------------------------------------
update public.app_settings set value = 'true' where key = 'outreach_enabled';
update public.app_settings set value = '"Asia/Kolkata"' where key = 'default_timezone';
select is((select value from public.app_settings where key = 'outreach_business_address') #>> '{}', '{{BUSINESS_ADDRESS}}',
  'outreach_business_address exists with a placeholder value');
select is(private.outreach_business_address_ready(), false, 'a placeholder address is not ready');

insert into public.outreach_sequences (id, name, steps) values
  ('00000000-0000-0000-0000-0000000001a1', 'Audit seq',
   '[{"step":1,"delay_days":0,"variants":[{"subject":"Quick question","body":"Hi"}]},
     {"step":2,"delay_days":4,"variants":[{"subject":"Follow up","body":"Hi again"}]}]');

-- campaigns are created paused and only an admin activates them ---------------------------------------
select tests.authenticate_as(:'admin');
insert into public.outreach_campaigns (id, name, sequence_id, status, daily_cap)
values ('00000000-0000-0000-0000-0000000001c1', 'Audit campaign', '00000000-0000-0000-0000-0000000001a1', 'active', 100);
select is((select status from public.outreach_campaigns where id = '00000000-0000-0000-0000-0000000001c1'), 'draft',
  'a campaign inserted as active is stored as draft');
select is((select count(*)::int from public.admin_audit_log where action = 'outreach_campaign_create'
            and target_id = '00000000-0000-0000-0000-0000000001c1'), 1, 'campaign creation is logged');
reset role;
select tests.clear_auth();

select tests.authenticate_service();
select throws_ok($$ update public.outreach_campaigns set status = 'active' where id = '00000000-0000-0000-0000-0000000001c1' $$,
  'PT403', 'campaign_activation_requires_admin', 'the service role (cron) cannot activate a campaign');
reset role;
select tests.clear_auth();
select throws_ok($$ update public.outreach_campaigns set status = 'active' where id = '00000000-0000-0000-0000-0000000001c1' $$,
  'PT403', 'campaign_activation_requires_admin', 'a direct database session cannot activate a campaign either');

select tests.authenticate_as(:'admin');
update public.outreach_campaigns set status = 'active' where id = '00000000-0000-0000-0000-0000000001c1';
select is((select activated_by from public.outreach_campaigns where id = '00000000-0000-0000-0000-0000000001c1'),
  :'admin'::uuid, 'admin activation is stamped');
select is((select details ->> 'from' || '->' || (details ->> 'to') from public.admin_audit_log
            where action = 'outreach_campaign_status' and target_id = '00000000-0000-0000-0000-0000000001c1'
            order by id desc limit 1), 'draft->active', 'campaign activation is logged');
reset role;
select tests.clear_auth();

insert into public.outreach_leads (id, business_key, business_name, email, email_status, address_source, source,
                                   lawful_basis, chosen_reason, matched_category_ids, campaign_id, timezone)
values ('00000000-0000-0000-0000-0000000001aa', 'domain:auditfridge.example', 'Audit Fridge', 'info@auditfridge.example',
        'valid', 'https://auditfridge.example/contact', 'osm', 'legitimate_interest', 'OSM shop=appliance',
        array[tests.cat('t-fridge')], '00000000-0000-0000-0000-0000000001c1', 'Asia/Kolkata');

select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-0000000001aa', 'email', null,
    '2026-10-05 11:00+05:30')), 'business_address_missing', 'outreach_can_send refuses while the address is a placeholder');
select throws_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-0000000001aa', '00000000-0000-0000-0000-0000000001c1',
    null, 'email', 1, 0, 'Quick question', 'Hi', 'info@auditfridge.example', 'audit-msg-0') $$,
  'PT409', 'outreach_business_address_missing', 'a send cannot be recorded while the address is a placeholder');

select tests.authenticate_as(:'admin');
select throws_ok($$ select public.admin_set_setting('outreach_business_address', '42') $$, 'PT400', 'invalid_setting_value',
  'the business address must be a string');
select lives_ok($$ select public.admin_set_setting('outreach_business_address', '"{{US_BUSINESS_ADDRESS}}"') $$,
  'a placeholder value can be stored');
select is(private.outreach_business_address_ready(), false, 'any {{...}} placeholder keeps sends blocked');
select lives_ok($$ select public.admin_set_setting('outreach_business_address', '"12 Market Road, Testpur 990001"') $$,
  'admin fills in the real address');
select is(private.outreach_business_address_ready(), true, 'a real address unblocks sends');
reset role;
select tests.clear_auth();

select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-0000000001aa', 'email', null,
    '2026-10-05 11:00+05:30')), 'ok', 'with a real address and an admin-activated campaign the lead can be emailed');
select tests.authenticate_as(:'admin');
update public.outreach_campaigns set status = 'paused', paused_reason = 'manual' where id = '00000000-0000-0000-0000-0000000001c1';
reset role;
select tests.clear_auth();
select is((select activated_by from public.outreach_campaigns where id = '00000000-0000-0000-0000-0000000001c1'), null,
  'pausing clears the activation stamp');
select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-0000000001aa', 'email', null,
    '2026-10-05 11:00+05:30')), 'campaign_paused', 'a paused campaign sends nothing');
select throws_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-0000000001aa', '00000000-0000-0000-0000-0000000001c1',
    null, 'email', 1, 0, 'Quick question', 'Hi', 'info@auditfridge.example', 'audit-msg-1') $$,
  'PT409', 'outreach_campaign_not_active', 'a send for a paused campaign cannot be recorded');

-- brochure format alias --------------------------------------------------------------------------------
select tests.authenticate_as(:'admin');
insert into public.brochures (city_name, category_id, language, format, storage_path)
values ('Testpur', tests.cat('t-fridge'), 'en', 'png', 'testpur/t-fridge/en/image-v1.png');
select is((select format from public.brochures where storage_path = 'testpur/t-fridge/en/image-v1.png'), 'image',
  'brochure format png is stored as image');
select is((select details ->> 'format' from public.admin_audit_log where action = 'brochure_create' order by id desc limit 1),
  'image', 'brochure upload is logged');

-- stage machine ------------------------------------------------------------------------------------------
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'live', null) $$,
  'PT400', 'invalid_stage', 'unknown stages are rejected');
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'sourced', null) $$,
  'PT409', 'stage_no_change', 'same stage is refused');
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'contacted', null) $$,
  'PT409', 'stage_needs_logged_contact', 'moving to contacted by hand needs a logged touch');
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'onboarding', null) $$,
  'PT409', 'stage_not_allowed', 'sourced cannot jump to onboarding');
insert into public.outreach_events (lead_id, channel, event_type, body_preview, created_by)
values ('00000000-0000-0000-0000-0000000001aa', 'call', 'call_logged', 'Spoke to the owner', :'admin');
select is((public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'contacted', 'called')).stage, 'contacted',
  'with a logged call the lead moves to contacted');
select is((select meta ->> 'from' || '->' || (meta ->> 'to') || '|' || body_preview from public.outreach_events
            where lead_id = '00000000-0000-0000-0000-0000000001aa' and event_type = 'stage_change'),
  'sourced->contacted|called', 'a stage_change event is recorded with the note');
select is((select count(*)::int from public.admin_audit_log where target_id = '00000000-0000-0000-0000-0000000001aa'
            and action in ('admin_outreach_set_stage','outreach_stage_change')), 1,
  'the RPC logs one audit row (the trigger does not log it twice)');
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'sourced', null) $$,
  'PT409', 'stage_not_allowed', 'the pipeline never moves back');
select is((public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'onboarding', null)).sequence_status,
  'stopped', 'a human conversation stops the automated sequence');
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'live_seller', null) $$,
  'PT409', 'stage_needs_seller_link', 'live seller needs a linked seller account');
reset role;
update public.outreach_leads set seller_id = :'seller' where id = '00000000-0000-0000-0000-0000000001aa';
select is((select count(*)::int from public.admin_audit_log where action = 'outreach_stage_change'
            and target_id = '00000000-0000-0000-0000-0000000001aa'), 0, 'no automatic stage change logged for this lead');
select tests.authenticate_as(:'admin');
select is((public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'live_seller', null)).stage, 'live_seller',
  'linked lead becomes a live seller');
select is((public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'do_not_contact', 'asked us to stop')).stage,
  'do_not_contact', 'do not contact from any stage before the end');
select is(public.outreach_is_suppressed('info@auditfridge.example', null, 'domain:auditfridge.example'), true,
  'do not contact adds the business to the suppression list');
select is((select count(*)::int from public.suppression_list where business_key = 'domain:auditfridge.example'
            and reason = 'do_not_contact'), 1, 'suppression row carries the business key');
select throws_ok($$ select public.admin_outreach_set_stage('00000000-0000-0000-0000-0000000001aa', 'replied', null) $$,
  'PT409', 'stage_terminal', 'do not contact is permanent');
select ok((select count(*) from public.admin_audit_log where action = 'suppression_add'
            and details ->> 'business_key' = 'domain:auditfridge.example') >= 1, 'suppression insert is logged');

-- automatic stage changes (webhooks, sends) are logged by the trigger
reset role;
select tests.clear_auth();
insert into public.outreach_leads (id, business_key, business_name, email, source, lawful_basis)
values ('00000000-0000-0000-0000-0000000001ab', 'domain:auditrepair.example', 'Audit Repair', 'hi@auditrepair.example',
        'osm', 'legitimate_interest');
select public.outreach_record_event('replied', null, 'hi@auditrepair.example', '{"text":"tell me more"}') is not null as replied \gset
select is((select details ->> 'to' || '|' || (details ->> 'via') from public.admin_audit_log
            where action = 'outreach_stage_change' and target_id = '00000000-0000-0000-0000-0000000001ab'),
  'replied|system', 'automatic stage changes are logged as system');

-- KPIs ---------------------------------------------------------------------------------------------------
select tests.authenticate_as(:'admin');
select ok(public.admin_kpis() ?& array['request_to_acceptance_pct','seller_response_rate_pct','free_to_paid_pct','retention',
    'revenue_per_seller_minor','refunds_30d','outreach_sent_today','outreach_daily_capacity','outreach_queue',
    'outreach_reply_rate_pct','outreach_signup_rate_pct'], 'admin_kpis returns every key the panel reads');
select is((select array_agg(k order by k) from jsonb_object_keys(public.admin_kpis() -> 'retention') k),
  array['buyer_d1','buyer_d30','buyer_d7','seller_d1','seller_d30','seller_d7'], 'retention for both roles at D1/D7/D30');
select lives_ok($$ select public.admin_set_setting('kpi_product_prices_minor', '{"zz_test_pack": 1000}') $$,
  'admin sets the KPI price map');
select is((public.admin_kpis() ->> 'revenue_30d_minor')::bigint, 0::bigint, 'no revenue for a product nobody bought');
reset role;
insert into public.entitlements (seller_id, store, provider, product_id, tier, status, last_event_at)
values (:'seller', 'play', 'google_play', 'zz_test_pack', 'credits', 'active', now());
select tests.authenticate_as(:'admin');
select is((public.admin_kpis() ->> 'revenue_30d_minor')::bigint, 1000::bigint, 'revenue estimate uses the price map');

reset role;
select tests.clear_auth();
select * from finish();
rollback;
