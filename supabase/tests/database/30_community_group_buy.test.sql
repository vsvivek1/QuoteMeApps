-- Community feed (publish, public projection, comments, likes, reports) and
-- group buy (join, tiers, price ladder, members, award notifications).
begin;
\ir _helpers.psql
select plan(50);

select tests.create_user('cf-buyer', 'Priya Sharma') as buyer \gset
select tests.create_user('cf-friend', 'Ravi Kumar') as friend \gset
select tests.create_user('cf-stranger', 'Sam Lee') as stranger \gset
select tests.make_seller('cf-seller-1') as seller1 \gset
select tests.make_seller('cf-seller-2') as seller2 \gset
select tests.make_request(:'buyer', p_title => 'Need 20 ceiling fans') as req \gset
select tests.make_request(:'buyer', p_title => 'Private request') as private_req \gset

-- publishing -----------------------------------------------------------------------------------------
select tests.authenticate_as(:'friend');
select throws_ok(format($$ select public.publish_request(%L) $$, :'req'), 'PT404', 'request_not_found',
  'only the buyer can publish a request');
select tests.authenticate_as(:'buyer');
select lives_ok(format($$ select public.publish_request(%L) $$, :'req'), 'buyer publishes a request');

select tests.authenticate_anon();
select is((select count(*)::int from public.get_community_feed() f where f->>'request_id' = :'req'), 1,
  'signed-out visitors see the published request');
select is((select count(*)::int from public.get_community_feed() f where f->>'request_id' = :'private_req'), 0,
  'unpublished requests stay off the feed');
select is((select f->>'author_name' from public.get_community_feed() f where f->>'request_id' = :'req'), 'Priya S.',
  'author shows as first name + initial');
select ok(not (select f ? 'buyer_id' from public.get_community_feed() f where f->>'request_id' = :'req'),
  'the feed never exposes the buyer id');
select ok((select f::text not like '%Secret Lane%' and f::text not like '%910000099999%'
             from public.get_community_feed() f where f->>'request_id' = :'req'),
  'the feed never exposes the address or phone');
select throws_ok(format($$ select public.post_comment(%L, 'hi') $$, :'req'), '42501', null,
  'signed-out visitors cannot comment');
select throws_ok(format($$ select public.get_feed_post(%L) $$, :'private_req'), 'PT404', 'post_not_found',
  'an unpublished request is not readable as a post');
reset role;

-- comments ------------------------------------------------------------------------------------------
select tests.authenticate_as(:'friend');
select id as c1 from public.post_comment(:'req', '  I need 5 as well!  ') \gset
select is((select body from public.request_comments where id = :'c1'), 'I need 5 as well!', 'comment body is trimmed');
select throws_ok(format($$ select public.post_comment(%L, '   ') $$, :'req'), 'PT400', 'comment_empty',
  'empty comments are rejected');
select throws_ok(format($$ select public.post_comment(%L, 'selling zzforbiddenthing cheap') $$, :'req'), 'PT422', 'blocked_content',
  'blocked keywords are rejected in comments');
select throws_ok(format($$ select public.post_comment(%L, 'x', null, true) $$, :'req'), 'PT403', 'not_a_seller',
  'only sellers can comment as a business');
select throws_ok(format($$ select public.post_comment(%L, 'hi') $$, :'private_req'), 'PT404', 'post_not_found',
  'cannot comment on an unpublished request');

select tests.authenticate_as(:'seller1');
select id as c2 from public.post_comment(:'req', 'We can supply these, 2 year warranty', :'c1', true) \gset
reset role;
select is((select parent_id from public.request_comments where id = :'c2'), :'c1'::uuid, 'reply attaches to the comment');
select is((select comment_count from public.requests where id = :'req'), 2, 'comment_count counts comments');
select is((select count(*)::int from public.notifications where user_id = :'buyer' and type = 'feed_comment'), 2,
  'the post author is notified of comments');
select is((select count(*)::int from public.notifications where user_id = :'friend' and type = 'feed_reply'), 1,
  'the comment author is notified of replies');

select tests.authenticate_anon();
select is((select business_name from public.get_feed_comments(:'req') where id = :'c2'), 'Shop cf-seller-1',
  'business comments show the business name');
select is((select seller_id from public.get_feed_comments(:'req') where id = :'c2'), :'seller1'::uuid,
  'business comments link the seller profile');
select is((select author_name from public.get_feed_comments(:'req') where id = :'c1'), 'Ravi K.',
  'personal comments show first name + initial');
reset role;

-- blocks hide comments both ways
insert into public.blocks (blocker_id, blocked_id) values (:'stranger', :'friend');
select tests.authenticate_as(:'stranger');
select is((select count(*)::int from public.get_feed_comments(:'req') where id = :'c1'), 0,
  'comments by blocked users are hidden');
reset role;

-- reports: three reporters auto-hide a comment
select tests.create_user('cf-r1') as r1 \gset
select tests.create_user('cf-r2') as r2 \gset
select tests.create_user('cf-r3') as r3 \gset
select set_config('tests.c1', :'c1', true) \gset
do $$
declare k text;
begin
  foreach k in array array['cf-r1','cf-r2','cf-r3'] loop
    perform tests.authenticate_as(md5('pgtap:' || k)::uuid);
    perform public.report_content('comment', current_setting('tests.c1')::uuid, 'spam');
  end loop;
end $$;
reset role;
select is((select hidden from public.request_comments where id = :'c1'), true, 'three reports hide a comment');
select is((select comment_count from public.requests where id = :'req'), 1, 'hidden comments leave comment_count');
select tests.authenticate_as(:'friend');
select is((select count(*)::int from public.get_feed_comments(:'req') where id = :'c1'), 1,
  'the author still sees their own hidden comment');
reset role;

-- the post author removes a comment on their post
select tests.authenticate_as(:'buyer');
select lives_ok(format($$ select public.delete_comment(%L) $$, :'c2'), 'post author removes a comment');
reset role;
select is((select comment_count from public.requests where id = :'req'), 0, 'deleting updates comment_count');

-- likes ------------------------------------------------------------------------------------------------
select tests.authenticate_as(:'friend');
select is((public.toggle_request_like(:'req'))->>'liked', 'true', 'first toggle likes');
select is((select f->>'liked_by_me' from public.get_community_feed() f where f->>'request_id' = :'req'), 'true',
  'feed shows liked_by_me');
select is((public.toggle_request_like(:'req'))->>'like_count', '0', 'second toggle unlikes');
reset role;

-- group buy --------------------------------------------------------------------------------------------
select tests.authenticate_as(:'friend');
select throws_ok(format($$ select public.join_group_buy(%L, 5) $$, :'req'), 'PT404', 'post_not_found',
  'cannot join before the organiser turns on group buy');
select tests.authenticate_as(:'buyer');
select is((public.set_group_buy(:'req', true, 'fans', 20))->'group'->>'total_qty', '20.000',
  'organiser turns on group buy with their own quantity');
select tests.authenticate_as(:'friend');
select throws_ok(format($$ select public.join_group_buy(%L, 0) $$, :'req'), 'PT400', 'invalid_qty', 'quantity must be positive');
select is((public.join_group_buy(:'req', 5))->>'total_qty', '25.000', 'a member joins with 5');
select is((public.join_group_buy(:'req', 10))->>'total_qty', '30.000', 'joining again changes the quantity');
reset role;
select is((select group_members from public.requests where id = :'req'), 2, 'group_members counts the organiser and members');

-- sellers quote tiers
select tests.authenticate_as(:'seller1');
select id as q1 from tests.quote(:'req', 100000) \gset
select throws_ok(format($$ select public.set_quote_tiers(%L, '[{"min_qty":1,"unit_price_minor":1000},{"min_qty":10,"unit_price_minor":1200}]') $$, :'q1'),
  'PT400', 'invalid_tiers', 'tier prices must drop as quantity rises');
select lives_ok(format($$ select public.set_quote_tiers(%L, '[{"min_qty":1,"unit_price_minor":3000},{"min_qty":25,"unit_price_minor":2600},{"min_qty":50,"unit_price_minor":2200}]') $$, :'q1'),
  'seller sets three tiers');
select tests.authenticate_as(:'seller2');
select id as q2 from tests.quote(:'req', 100000) \gset
select lives_ok(format($$ select public.set_quote_tiers(%L, '[{"min_qty":1,"unit_price_minor":2900},{"min_qty":40,"unit_price_minor":2400}]') $$, :'q2'),
  'second seller sets tiers');

select tests.authenticate_anon();
select is((public.get_group_buy(:'req'))->>'current_unit_price_minor', '2600',
  'current price is the best offer at the group quantity (30 units)');
select is((public.get_group_buy(:'req'))->'ladder',
  '[{"min_qty": 1.000, "unit_price_minor": 2900}, {"min_qty": 25.000, "unit_price_minor": 2600}, {"min_qty": 40.000, "unit_price_minor": 2400}, {"min_qty": 50.000, "unit_price_minor": 2200}]'::jsonb,
  'the ladder keeps the best price at each step');
select is((public.get_group_buy(:'req'))->>'qty_to_next', '10.000', '10 more units unlock the next price');
reset role;

-- a newcomer pushes the group over the next tier: members hear about the drop
select tests.authenticate_as(:'stranger');
delete from public.blocks where blocker_id = :'stranger';
select is((public.join_group_buy(:'req', 10))->>'current_unit_price_minor', '2400', 'price drops when the group reaches 40');
reset role;
select ok((select count(*) from public.notifications where user_id = :'friend' and type = 'group_price_drop') >= 1,
  'existing members are notified of the price drop');
select is((select count(*)::int from public.notifications where user_id = :'seller1' and type = 'group_grew'), 1,
  'sellers who quoted hear that the group grew (digested)');

-- members list: organiser sees names, no phones; organiser cannot leave or unpublish
select tests.authenticate_as(:'buyer');
select is((select count(*)::int from public.get_group_members(:'req') where phone is null), 3,
  'organiser sees members without phone numbers');
select throws_ok(format($$ select public.publish_request(%L, false) $$, :'req'), 'PT409', 'group_has_members',
  'a group buy with members cannot be unpublished');
select id as ord from public.accept_quote(:'q2') \gset
reset role;
select is((select count(*)::int from public.notifications where type = 'group_awarded'
            and user_id in (:'friend', :'stranger')), 2, 'members hear the organiser accepted a quote');

select tests.authenticate_as(:'seller2');
select is((select count(*)::int from public.get_group_members(:'req') where phone is not null), 3,
  'the winning seller gets every member''s phone to arrange orders');
select tests.authenticate_as(:'friend');
select is((public.get_group_buy(:'req'))->'accepted'->>'business_name', 'Shop cf-seller-2',
  'members see the winning seller');
reset role;

select * from finish();
rollback;
