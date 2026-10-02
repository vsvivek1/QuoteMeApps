-- Outreach CRM anti-spam rules (Section 21.8) enforced in the database.
begin;
\ir _helpers.psql
select plan(22);

update public.app_settings set value = 'true' where key = 'outreach_enabled';
update public.app_settings set value = '"Asia/Kolkata"' where key = 'default_timezone';

insert into public.outreach_sequences (id, name, steps) values
  ('00000000-0000-0000-0000-0000000000a1', 'Three touches',
   '[{"step":1,"delay_days":0,"variants":[{"subject":"Quick question","body":"Hi"}]},
     {"step":2,"delay_days":4,"include_brochure":true,"variants":[{"subject":"Re: quick question","body":"Hi again"}]},
     {"step":3,"delay_days":7,"variants":[{"subject":"Last note","body":"Bye"}]}]');
select throws_ok($$ insert into public.outreach_sequences (name, steps) values ('Four touches',
    '[{"step":1},{"step":2},{"step":3},{"step":4}]') $$, '23514', null, 'a sequence cannot have more than 3 touches');
select throws_ok($$ insert into public.outreach_sequences (name, steps) values ('Attachment first',
    '[{"step":1,"include_brochure":true}]') $$, '23514', null, 'no brochure / attachment in the first email');

insert into public.outreach_campaigns (id, name, sequence_id, status, daily_cap)
values ('00000000-0000-0000-0000-0000000000c1', 'Test campaign', '00000000-0000-0000-0000-0000000000a1', 'active', 100);

insert into public.outreach_leads (id, business_key, business_name, email, email_status, address_source, source,
                                   lawful_basis, chosen_reason, matched_category_ids, campaign_id, timezone)
values ('00000000-0000-0000-0000-00000000000a', 'domain:coolfridge.example', 'Cool Fridge Store', 'info@coolfridge.example',
        'valid', 'https://coolfridge.example/contact', 'osm', 'legitimate_interest', 'OSM shop=appliance in Testpur',
        array[tests.cat('t-fridge')], '00000000-0000-0000-0000-0000000000c1', 'Asia/Kolkata');

-- one business = one conversation
select throws_ok($$ insert into public.outreach_leads (business_key, business_name, email, source, lawful_basis)
    values ('domain:coolfridge.example', 'Cool Fridge Branch 2', 'sales@coolfridge.example', 'osm', 'legitimate_interest') $$,
  '23505', null, 'the same business cannot be imported twice');
select is(public.outreach_upsert_lead(jsonb_build_object('business_key', 'phone:+910000012345', 'business_name', 'Other branch',
    'email', 'info@coolfridge.example', 'source', 'osm')), null::uuid,
  'dedupe by email: a second key for the same business is skipped');

-- business hours (Mon 2026-10-05 11:00 IST) and caps
select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-00000000000a', 'email', null,
    '2026-10-05 11:00+05:30')), 'ok', 'lead can be emailed on a weekday in business hours');
select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-00000000000a', 'email', null,
    '2026-10-04 11:00+05:30')), 'outside_business_hours', 'no sends on weekends');
select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-00000000000a', 'email', null,
    '2026-10-05 21:00+05:30')), 'outside_business_hours', 'no sends outside business hours');
select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-00000000000a', 'whatsapp', null,
    '2026-10-05 11:00+05:30')), 'no_opt_in', 'WhatsApp needs a recorded opt-in');

-- audit trail required
select throws_ok($$ insert into public.outreach_events (lead_id, channel, event_type, sequence_step, recipient)
    values ('00000000-0000-0000-0000-00000000000a', 'email', 'sent', 1, null) $$, '23514', null,
  'a send without recipient / audit fields is rejected');

-- three touches, then never again
select lives_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000c1',
    null, 'email', 1, 0, 'Quick question', 'Hi', 'info@coolfridge.example', 'msg-1') $$, 'touch 1 recorded');
select is((select stage || '/' || sequence_status || '/' || touches_sent from public.outreach_leads
            where id = '00000000-0000-0000-0000-00000000000a'), 'contacted/active/1', 'lead moves to contacted');
select is((select reason_chosen from public.outreach_events where provider_message_id = 'msg-1'),
  'OSM shop=appliance in Testpur', 'send stores why the business was chosen');
select is((select reason from public.outreach_can_send('00000000-0000-0000-0000-00000000000a', 'email', null,
    now() + interval '1 hour')), 'not_due', 'follow-up waits for the step delay');
select lives_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000c1',
    null, 'email', 2, 0, 'Re', 'Hi again', 'info@coolfridge.example', 'msg-2') $$, 'touch 2 recorded');
select lives_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000c1',
    null, 'email', 3, 0, 'Last', 'Bye', 'info@coolfridge.example', 'msg-3') $$, 'touch 3 recorded');
select throws_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000c1',
    null, 'email', 3, 0, 'Again', 'x', 'info@coolfridge.example', 'msg-4') $$, 'PT409', 'outreach_max_touches',
  'a 4th touch is impossible');
select is((select sequence_status from public.outreach_leads where id = '00000000-0000-0000-0000-00000000000a'),
  'completed', 'sequence completed: the business is never re-contacted automatically');

-- suppression: unsubscribe / negative reply stop everything instantly
insert into public.outreach_leads (id, business_key, business_name, email, email_status, address_source, source,
                                   lawful_basis, chosen_reason, matched_category_ids, campaign_id, timezone)
values ('00000000-0000-0000-0000-00000000000b', 'domain:repairs.example', 'Repairs Co', 'hello@repairs.example',
        'valid', 'https://repairs.example', 'osm', 'legitimate_interest', 'test', array[tests.cat('t-repair')],
        '00000000-0000-0000-0000-0000000000c1', 'Asia/Kolkata');
select lives_ok($$ select public.outreach_record_event('negative_reply', null, 'hello@repairs.example', '{"text":"no thanks"}') $$,
  'negative reply recorded');
select is(public.outreach_is_suppressed('hello@repairs.example'), true, 'negative reply suppresses the address');
select throws_ok($$ select public.outreach_record_send('00000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-0000000000c1',
    null, 'email', 1, 0, 'Hi', 'x', 'hello@repairs.example', 'msg-b1') $$, 'PT409', 'outreach_suppressed',
  'suppressed address can never be emailed');

-- automatic brakes: 1 negative reply in 3 sends (> 5 %) already paused the campaign
select is((select status || ':' || paused_reason from public.outreach_campaigns where id = '00000000-0000-0000-0000-0000000000c1'),
  'paused:auto_brake:negative_reply_rate', 'negative replies above 5 % pause the campaign');
update public.outreach_campaigns set status = 'active', paused_reason = null where id = '00000000-0000-0000-0000-0000000000c1';
select public.outreach_record_event('complained', 'msg-1', null) is not null as complained \gset
select is((select status || ':' || paused_reason from public.outreach_campaigns where id = '00000000-0000-0000-0000-0000000000c1'),
  'paused:auto_brake:complaint_rate', 'complaint rate above 0.08 % pauses the campaign');

select * from finish();
rollback;
