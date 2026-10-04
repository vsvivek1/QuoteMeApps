import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/data/supabase/supabase_community_repository.dart';
import 'package:iwant/core/demo/demo_backend.dart';
import 'package:iwant/core/demo/demo_community.dart';
import 'package:iwant/core/demo/demo_repositories.dart';
import 'package:iwant/core/money/money.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/features/community/domain/community.dart';
import 'package:iwant/features/community/domain/community_repository.dart';
import 'package:iwant/features/requests/domain/buyer_request.dart';

/// Community feed and group buy against the in-memory backend, which mirrors
/// supabase/migrations/20261003400*_*.sql (pgTAP: 30_community_group_buy).
void main() {
  late DemoBackend b;
  late DemoCommunityRepository community;
  late DemoRequestRepository requests;

  setUp(() {
    b = DemoBackend(indiaConfig, simulateMarket: false);
    community = DemoCommunityRepository(b);
    requests = DemoRequestRepository(b);
  });
  tearDown(() => b.dispose());

  Future<FeedPost> post(String id) async => (await community.watchPost(id).first)!;

  test('the seeded group buy prices by the best tier at the group quantity', () async {
    b.signInAs(b.demoBuyerId);
    final feed = await community.watchFeed(FeedFilter.all).first;
    expect(feed.map((p) => p.id), containsAll(['demo-post-group', 'demo-post-plain']));
    final g = (await post('demo-post-group')).group!;
    // 6 + 4 fans; offers: A 3200 / 10+ 2900 / 25+ 2650, B 3100 / 20+ 2750.
    expect(g.totalQty, 10);
    expect(g.members, 2);
    expect(g.currentUnitPrice!.minorInt, 290000);
    expect(
      [for (final t in g.ladder) (t.minQty, t.unitPrice.minorInt)],
      [(1, 310000), (10, 290000), (20, 275000), (25, 265000)],
    );
    expect(g.nextMinQty, 20);
    expect(g.qtyToNext, 10);
    expect(g.myQty, isNull);
  });

  test('joining lowers the price once the group reaches the next tier', () async {
    b.signInAs(b.demoBuyerId);
    var g = await community.joinGroupBuy('demo-post-group', 12);
    expect(g.myQty, 12);
    expect(g.totalQty, 22);
    expect(g.currentUnitPrice!.minorInt, 275000);
    expect(b.notifications['demo-neighbour-0']!.first.type, 'group_joined');
    g = await community.leaveGroupBuy('demo-post-group');
    expect(g.currentUnitPrice!.minorInt, 290000);
    expect(
      () => community.joinGroupBuy('demo-post-group', 0),
      throwsA(isA<CommunityFailure>().having((e) => e.code, 'code', 'invalid_qty')),
    );
  });

  test('comments: replies attach to the top-level comment; authors and post owners delete', () async {
    b.signInAs(b.demoBuyerId);
    final c = await community.addComment('demo-post-plain', '  Same problem here  ');
    expect(c.body, 'Same problem here');
    final reply = await community.addComment('demo-post-plain', 'Try QuickFix', parentId: c.id);
    expect(reply.parentId, c.id);
    expect((await post('demo-post-plain')).commentCount, 3);
    expect(
      () => community.addComment('demo-post-plain', '   '),
      throwsA(isA<CommunityFailure>().having((e) => e.code, 'code', 'comment_empty')),
    );
    await community.deleteComment(c.id);
    expect((await post('demo-post-plain')).commentCount, 1, reason: 'replies go with their comment');

    b.signInAs('demo-neighbour-1');
    expect(() => community.deleteComment('demo-c3'), throwsA(isA<CommunityFailure>()));
    b.signInAs('demo-neighbour-2'); // the post's author
    await community.deleteComment('demo-c3');
    expect((await post('demo-post-plain')).commentCount, 0);
  });

  test('likes toggle', () async {
    b.signInAs(b.demoBuyerId);
    expect(await community.toggleLike('demo-post-plain'), isTrue);
    expect((await post('demo-post-plain')).likedByMe, isTrue);
    expect(await community.toggleLike('demo-post-plain'), isFalse);
    expect((await post('demo-post-plain')).likeCount, 1);
  });

  test('a buyer posts a group buy; it cannot leave the feed once others joined', () async {
    b.signInAs(b.demoBuyerId);
    final cat = b.categories.firstWhere((c) => c.isLeaf && !c.isBlocked);
    final r = await requests.createRequest(
      RequestDraft(text: 'Rice 25 kg bags', categoryId: cat.id, groupBuy: true, groupUnit: 'bags', groupQty: 4),
    );
    expect(r.isPublic, isTrue);
    expect((await post(r.id)).group!.myQty, 4);
    await community.publish(r.id, public: false); // nobody else yet
    expect(b.requests[r.id]!.isPublic, isFalse);
    await community.setGroupBuy(r.id, enabled: true, unit: 'bags', myQty: 4);
    b.signInAs('demo-neighbour-1');
    await community.joinGroupBuy(r.id, 2);
    b.signInAs(b.demoBuyerId);
    expect(
      () => community.publish(r.id, public: false),
      throwsA(isA<CommunityFailure>().having((e) => e.code, 'code', 'group_has_members')),
    );
    expect([for (final m in await community.groupMembers(r.id)) m.qty], [4, 2]);
  });

  test('seller tiers must step up in quantity and down in price', () async {
    b
      ..seedCommunity()
      ..signInAs('demo-seller-0');
    final m = indiaConfig.money;
    expect(
      () => community.setQuoteTiers('demo-quote-g1', [
        PriceTier(minQty: 1, unitPrice: m(1000)),
        PriceTier(minQty: 5, unitPrice: m(1200)),
      ]),
      throwsA(isA<CommunityFailure>().having((e) => e.code, 'code', 'invalid_tiers')),
    );
    await community.setQuoteTiers('demo-quote-g1', [
      PriceTier(minQty: 1, unitPrice: m(300000)),
      PriceTier(minQty: 10, unitPrice: m(250000)),
    ]);
    b.signInAs(b.demoBuyerId);
    expect((await post('demo-post-group')).group!.currentUnitPrice!.minorInt, 250000);
  });

  test('server rows map to feed posts and group summaries', () {
    final p = mapFeedPost({
      'request_id': 'r1',
      'category_id': 7,
      'title': 'Fans',
      'status': 'open',
      'comment_count': 2,
      'like_count': 5,
      'liked_by_me': true,
      'author_name': 'Priya S.',
      'published_at': '2026-10-03T10:00:00Z',
      'currency': 'INR',
      'group_buy': true,
      'group': {
        'unit': 'fans',
        'total_qty': '30.000',
        'members': 3,
        'my_qty': 5,
        'ladder': [
          {'min_qty': 1, 'unit_price_minor': 2900},
          {'min_qty': 40, 'unit_price_minor': 2400},
        ],
        'current_unit_price_minor': 2900,
        'next_min_qty': '40.000',
        'next_unit_price_minor': 2400,
        'qty_to_next': '10.000',
        'offers': 2,
        'accepted': null,
      },
    }, fallbackCurrency: 'INR');
    expect(p.id, 'r1');
    expect(p.status, RequestStatus.open);
    expect(p.likedByMe, isTrue);
    expect(p.group!.totalQty, 30);
    expect(p.group!.ladder.last.unitPrice.minorInt, 2400);
    expect(p.group!.qtyToNext, 10);
    expect(p.group!.progressToNext, 0.75);
    expect(formatQty(p.group!.totalQty), '30');
    expect(formatQty(2.5), '2.5');
  });
}
