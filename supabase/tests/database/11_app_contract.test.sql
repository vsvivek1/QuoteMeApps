-- App contract additions (1040): idempotent message retries, request_title on
-- chats/orders, orders in realtime, new public settings, payment method
-- 'check', one field_schema shape.
begin;
\ir _helpers.psql
select plan(19);

select tests.create_user('ac-buyer') as buyer \gset
select tests.make_seller('ac-seller') as seller \gset
select tests.make_request(:'buyer', p_title => 'Double door fridge 300L') as req \gset

-- request_title on chats and orders ----------------------------------------------------------------
select tests.authenticate_as(:'seller');
select tests.quote(:'req', 100000);
select tests.authenticate_as(:'buyer');
select id as chat from public.get_or_create_chat(:'req', :'seller') \gset
select tests.authenticate_as(:'seller');
select is((select request_title from public.chats where id = :'chat'), 'Double door fridge 300L',
  'the seller reads the request title on the chat');

-- messages.client_id: retries are idempotent ----------------------------------------------------------
select tests.authenticate_as(:'buyer');
select lives_ok(format($$ insert into public.messages (chat_id, sender_id, body, client_id)
    values (%L, %L, 'Is it in stock?', '00000000-0000-4000-8000-00000000aa01')
    on conflict (chat_id, client_id) do nothing $$, :'chat', :'buyer'), 'a queued message is sent with its client id');
select lives_ok(format($$ insert into public.messages (chat_id, sender_id, body, client_id)
    values (%L, %L, 'Is it in stock?', '00000000-0000-4000-8000-00000000aa01')
    on conflict (chat_id, client_id) do nothing $$, :'chat', :'buyer'), 'the retry does not fail');
select is((select count(*)::int from public.messages where chat_id = :'chat' and client_id = '00000000-0000-4000-8000-00000000aa01'),
  1, 'the retry does not create a second message');
select lives_ok(format($$ insert into public.messages (chat_id, sender_id, body) values (%L, %L, 'no client id') $$, :'chat', :'buyer'),
  'messages without a client id still work');
select lives_ok(format($$ insert into public.messages (chat_id, sender_id, body) values (%L, %L, 'no client id') $$, :'chat', :'buyer'),
  'several messages without a client id are allowed');

select public.accept_quote((select id from public.quotes where request_id = :'req' and seller_id = :'seller')) as accepted \gset
select id as ord from public.orders where request_id = :'req' \gset
select tests.authenticate_as(:'seller');
select is((select request_title from public.orders where id = :'ord'), 'Double door fridge 300L',
  'the seller reads the request title on the order');
reset role;
select tests.clear_auth();
update public.requests set title = 'Double door fridge 320L' where id = :'req';
select is((select request_title from public.orders where id = :'ord') || '|' || (select request_title from public.chats where id = :'chat'),
  'Double door fridge 320L|Double door fridge 320L', 'a title change reaches chats and orders');
update public.chats set request_title = 'forged' where id = :'chat';
select is((select request_title from public.chats where id = :'chat'), 'Double door fridge 320L',
  'request_title cannot be edited on its own');

-- orders in realtime -----------------------------------------------------------------------------------
select ok(exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
                   and schemaname = 'public' and tablename = 'orders'), 'orders are published to realtime');

-- payment method 'check' ------------------------------------------------------------------------------
select tests.authenticate_as(:'buyer');
select is((public.record_payment(:'ord', 'check', 120000)).payment_method, 'check', 'a payment by check can be recorded');
select throws_ok(format($$ select public.record_payment(%L, 'cheque_book', 1) $$, :'ord'), 'PT400', 'invalid_payment_method',
  'unknown payment methods are refused');

-- public settings -------------------------------------------------------------------------------------
select tests.authenticate_anon();
select is(public.get_app_settings() -> 'web_purchase_links_allowed', 'false'::jsonb, 'web_purchase_links_allowed is public, default false');
select is(public.get_app_settings() -> 'paywall_default_period', '"annual"'::jsonb, 'paywall_default_period is public, default annual');
select is(public.get_app_settings() -> 'whatsapp_notifications', 'false'::jsonb, 'whatsapp_notifications is public, default false');
reset role;
select tests.clear_auth();
select tests.create_user('ac-admin', 'Admin', '{buyer,admin}') as admin \gset
select tests.authenticate_as(:'admin');
select throws_ok($$ select public.admin_set_setting('paywall_default_period', '"weekly"') $$, 'PT400', 'invalid_setting_value',
  'paywall_default_period is monthly or annual');
select is((public.admin_set_setting('paywall_default_period', '"monthly"')).value, '"monthly"'::jsonb, 'admin switches the default period');
reset role;
select tests.clear_auth();

-- field_schema has one shape ---------------------------------------------------------------------------
select throws_ok($$ update public.categories set field_schema = '[{"key":"x","type":"text"}]' where slug = 't-repair' $$,
  '23514', null, 'a bare array field_schema is rejected');
select is((select count(*)::int from public.categories where field_schema is not null
            and not (jsonb_typeof(field_schema) = 'object' and jsonb_typeof(field_schema -> 'fields') = 'array')),
  0, 'every seeded category uses {"version", "fields": [...]}');

select * from finish();
rollback;
