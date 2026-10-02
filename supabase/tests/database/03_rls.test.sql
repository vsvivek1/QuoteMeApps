-- Row Level Security: buyers, sellers, chats, private request details.
begin;
\ir _helpers.psql
select plan(26);

select tests.create_user('rls-buyer-a') as buyer_a \gset
select tests.create_user('rls-buyer-b') as buyer_b \gset
select tests.make_seller('rls-seller-1') as seller_1 \gset
select tests.make_seller('rls-seller-2') as seller_2 \gset
select tests.make_request(:'buyer_a') as req_a \gset
select tests.make_request(:'buyer_b', 't-repair') as req_b \gset

-- Buyers --------------------------------------------------------------------------------
select tests.authenticate_as(:'buyer_a');
select is((select count(*)::int from public.requests where id = :'req_a'), 1, 'buyer reads own request');
select is((select count(*)::int from public.requests where id = :'req_b'), 0, 'buyer cannot read another buyer''s request');
select is((select count(*)::int from public.request_private where request_id = :'req_b'), 0,
  'buyer cannot read another buyer''s private details');
select is((select full_address from public.request_private where request_id = :'req_a'), '1 Secret Lane',
  'buyer reads own private details');
select is((select count(*)::int from public.profiles where id <> :'buyer_a'::uuid), 0, 'profiles of others are not readable');
select throws_ok(
  format($$ insert into public.requests (buyer_id, category_id, title, currency, quote_window_ends_at, audience)
            values (%L, %s, 'direct insert', 'INR', now() + interval '1 day', 'online') $$, :'buyer_a', tests.cat('t-fridge')),
  '42501', null, 'direct insert into requests is denied (create_request only)');
select throws_ok(format($$ update public.profiles set roles = '{buyer,admin}' where id = %L $$, :'buyer_a'),
  '42501', null, 'users cannot grant themselves roles');
select lives_ok(format($$ update public.profiles set name = 'New Name' where id = %L $$, :'buyer_a'),
  'users can update their own display name');

-- Sellers: no direct access to requests or private details before acceptance ------------------
select tests.authenticate_as(:'seller_1');
select is((select count(*)::int from public.requests where id = :'req_a'), 0,
  'seller cannot select requests directly (lead feed only)');
select is((select count(*)::int from public.request_private where request_id = :'req_a'), 0,
  'seller cannot read request_private before acceptance');
select throws_ok(
  format($$ insert into public.quotes (request_id, seller_id, subtotal_minor, total_minor, currency)
            values (%L, %L, 100, 100, 'INR') $$, :'req_a', :'seller_1'),
  '42501', null, 'direct insert into quotes is denied');

select lives_ok(format($$ select tests.quote(%L, 100000) $$, :'req_a'), 'seller 1 quotes via RPC');
select tests.authenticate_as(:'seller_2');
select lives_ok(format($$ select tests.quote(%L, 90000) $$, :'req_a'), 'seller 2 quotes via RPC');
select is((select count(*)::int from public.quotes where request_id = :'req_a'), 1, 'a seller reads only their own quotes');

select tests.authenticate_as(:'buyer_a');
select is((select count(*)::int from public.quotes where request_id = :'req_a'), 2, 'buyer reads all quotes on own request');
select tests.authenticate_as(:'buyer_b');
select is((select count(*)::int from public.quotes where request_id = :'req_a'), 0, 'other buyers cannot read those quotes');

-- Chat visibility ----------------------------------------------------------------------------------
select tests.authenticate_as(:'buyer_a');
select id as chat_1 from public.get_or_create_chat(:'req_a', :'seller_1') \gset
select lives_ok(format($$ insert into public.messages (chat_id, sender_id, body) values (%L, %L, 'Hello, is it in stock?') $$,
  :'chat_1', :'buyer_a'), 'buyer posts in own chat');
select tests.authenticate_as(:'seller_1');
select is((select count(*)::int from public.messages where chat_id = :'chat_1'), 1, 'chat seller reads the messages');
select tests.authenticate_as(:'seller_2');
select is((select count(*)::int from public.chats where id = :'chat_1'), 0, 'other seller cannot see the chat');
select is((select count(*)::int from public.messages where chat_id = :'chat_1'), 0, 'other seller cannot read messages');
select throws_ok(format($$ insert into public.messages (chat_id, sender_id, body) values (%L, %L, 'spam') $$, :'chat_1', :'seller_2'),
  '42501', null, 'non-members cannot post into a chat');
select tests.authenticate_as(:'seller_1');
select throws_ok(format($$ insert into public.messages (chat_id, sender_id, body) values (%L, %L, 'spoof') $$, :'chat_1', :'buyer_a'),
  '42501', null, 'members cannot post as someone else');

-- After acceptance: winner sees private details, loser does not; contacts unlocked --------------------
select tests.authenticate_as(:'buyer_a');
select public.accept_quote((select id from public.quotes where request_id = :'req_a' and seller_id = :'seller_1'));
select tests.authenticate_as(:'seller_1');
select is((select buyer_phone from public.request_private where request_id = :'req_a'), '+910000099999',
  'accepted seller reads request_private after acceptance');
select tests.authenticate_as(:'seller_2');
select is((select count(*)::int from public.request_private where request_id = :'req_a'), 0,
  'declined seller still cannot read request_private');
select tests.authenticate_as(:'buyer_a');
select is((select count(*)::int from public.seller_contacts where seller_id = :'seller_2'), 0,
  'seller contacts stay hidden without an order');

-- anon --------------------------------------------------------------------------------------------------
select tests.authenticate_anon();
select throws_ok($$ select count(*) from public.requests $$, '42501', null, 'anon has no access to requests');

select tests.clear_auth();
reset role;
select * from finish();
rollback;
