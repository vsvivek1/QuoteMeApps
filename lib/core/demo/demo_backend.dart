import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/chat/domain/chat.dart';
import '../../features/community/domain/community.dart';
import '../../features/notifications/domain/app_notification.dart';
import '../../features/orders/domain/order.dart';
import '../../features/quotes/domain/quote.dart';
import '../../features/requests/domain/buyer_request.dart';
import '../../features/requests/domain/category.dart';
import '../../features/reviews/domain/review.dart';
import '../../features/seller/domain/seller.dart';
import '../config/country_config.dart';
import '../money/money.dart';
import '../money/tax.dart';
import 'demo_seed.dart';

/// An in-memory marketplace used when no Supabase project is configured
/// (demo builds, widget and integration tests). It mirrors the server rules
/// that matter to the UI: quote cap, accept closes the request, contact
/// details unlock after acceptance, reviews only after completion.
class DemoBackend {
  DemoBackend(this.config, {this.simulateMarket = true, Random? random}) : _random = random ?? Random(7) {
    categories = demoCategories(config.country);
    _seed();
  }

  final CountryConfig config;
  final bool simulateMarket;
  final Random _random;
  final _uuid = const Uuid();

  /// Test OTP accepted in demo mode (mirrors supabase/config.toml test OTPs).
  static const demoOtp = '123456';

  late final List<Category> categories;
  final profiles = <String, Profile>{};
  final sellers = <String, Seller>{};
  final requests = <String, BuyerRequest>{};
  final requestPrivate = <String, Map<String, String?>>{};
  final quotes = <String, Quote>{};
  final quoteSellerIds = <String, String>{};
  final chats = <String, Chat>{};
  final messages = <String, List<ChatMessage>>{};
  final orders = <String, Order>{};
  final reviews = <String, Review>{};
  final notifications = <String, List<AppNotification>>{};
  final blocks = <String, Set<String>>{};
  final templates = <String, List<QuoteTemplate>>{};
  final documents = <String, List<SellerDocument>>{};
  final licences = <String, List<SellerLicence>>{};
  final dismissedLeads = <String, Set<String>>{};
  final reports = <Map<String, String>>[];
  final consents = <String, Map<String, String>>{};
  int quoteCap = 10;

  // Community feed (demo_community.dart).
  final comments = <String, List<FeedComment>>{}; // request id -> comments, oldest first
  final likes = <String, Set<String>>{}; // request id -> user ids
  final groupMembers = <String, Map<String, num>>{}; // request id -> user id -> qty
  final groupUnits = <String, String>{};
  final quoteTiers = <String, List<PriceTier>>{}; // quote id -> tiers, qty ascending

  String? currentUserId;
  final _changes = StreamController<void>.broadcast();
  final _sessionChanges = StreamController<AuthSession?>.broadcast();

  Stream<void> get changes => _changes.stream;
  Stream<AuthSession?> get sessionChanges => _sessionChanges.stream;

  void notify() => _changes.add(null);

  /// Emits [compute] now and after every change.
  Stream<T> watch<T>(T Function() compute) async* {
    yield compute();
    await for (final _ in changes) {
      yield compute();
    }
  }

  String newId() => _uuid.v4();

  Money m(int minor) => config.money(minor);

  // ---------------------------------------------------------------- auth

  AuthSession? get session {
    final id = currentUserId;
    if (id == null) return null;
    final p = profiles[id];
    return AuthSession(userId: id, phone: p?.phone, email: p?.email);
  }

  void signInAs(String userId) {
    currentUserId = userId;
    _sessionChanges.add(session);
    notify();
  }

  String signInWithPhone(String e164) {
    final existing = profiles.values.where((p) => p.phone == e164).firstOrNull;
    final id = existing?.id ?? newId();
    profiles.putIfAbsent(id, () => Profile(id: id, phone: e164, phoneVerified: true, createdAt: DateTime.now()));
    signInAs(id);
    return id;
  }

  String signInWithEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final existing = profiles.values.where((p) => p.email?.toLowerCase() == normalized).firstOrNull;
    final id = existing?.id ?? newId();
    profiles.putIfAbsent(id, () => Profile(id: id, email: normalized, createdAt: DateTime.now()));
    signInAs(id);
    return id;
  }

  void signOut() {
    currentUserId = null;
    _sessionChanges.add(null);
    notify();
  }

  // ---------------------------------------------------------------- seed

  late final List<String> _demoSellerIds;
  late final String demoBuyerId;

  void _seed() {
    final city = config.demoCities.first;
    demoBuyerId = 'demo-buyer';
    profiles[demoBuyerId] = Profile(
      id: demoBuyerId,
      name: config.country == Country.india ? 'Priya' : 'Alex',
      phone: config.country == Country.india ? '+910000000001' : '+15555550100',
      phoneVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    final names = config.country == Country.india
        ? [
            'Sharma Electronics',
            'Cool Air Services',
            'Mehta Home Appliances',
            'QuickFix Repairs',
            'Bharat Movers',
            'Kumar Furnishings',
          ]
        : [
            'Lone Star Appliances',
            'Big Apple HVAC',
            'Metro Movers',
            'Handy Pros',
            'Empire Electronics',
            'Brooklyn Furniture Co',
          ];
    final leafIds = categories.where((c) => c.isLeaf && !c.isBlocked).map((c) => c.id).toList();
    _demoSellerIds = [];
    for (var i = 0; i < names.length; i++) {
      final id = 'demo-seller-$i';
      _demoSellerIds.add(id);
      profiles[id] = Profile(
        id: id,
        name: names[i],
        roles: const [UserRole.buyer, UserRole.seller],
        activeMode: AppMode.seller,
      );
      sellers[id] = Seller(
        id: id,
        businessName: names[i],
        description: 'Trusted local business since ${2005 + i}.',
        yearsInBusiness: 20 - i,
        categoryIds: leafIds,
        lat: city.center.lat + (i - 3) * 0.01,
        lng: city.center.lng + (i - 3) * 0.01,
        radiusKm: config.defaultRadiusKm,
        state: city.state,
        locality: city.name,
        verificationStatus: i.isEven ? VerificationStatus.verified : VerificationStatus.none,
        ratingAvg: 3.8 + (i % 3) * 0.5,
        ratingCount: 12 + i * 7,
        quotesSent: 40 + i * 9,
        quotesWon: 11 + i * 2,
        avgResponseMins: 25 + i * 15,
        earlyPartner: true,
        phone: config.country == Country.india ? '+9100000001$i' : '+1555555011$i',
      );
    }
  }

  var _communitySeeded = false;

  /// Public posts by neighbours so the community feed is not empty: a group
  /// buy with tiered offers and comments, and a plain request. Seeded the
  /// first time the feed is opened, so flows that never open it (and their
  /// tests) see only their own requests.
  void seedCommunity() {
    if (_communitySeeded) return;
    _communitySeeded = true;
    final india = config.country == Country.india;
    final city = config.demoCities.first;
    final leaves = categories.where((c) => c.isLeaf && !c.isBlocked).toList();
    if (leaves.length < 2) return;
    final now = DateTime.now();
    final neighbours = india
        ? ['Anil Menon', 'Divya Nair', 'Farhan Ali']
        : ['Jordan Miller', 'Maria Garcia', 'Sam Lee'];
    for (final (i, name) in neighbours.indexed) {
      profiles['demo-neighbour-$i'] = Profile(id: 'demo-neighbour-$i', name: name, phoneVerified: true);
    }

    BuyerRequest post(String id, String buyer, int cat, String title, String desc, Duration ago, {bool group = false}) {
      final r = BuyerRequest(
        id: id,
        buyerId: buyer,
        categoryId: cat,
        title: title,
        description: desc,
        locality: city.name,
        state: city.state,
        lat: city.center.lat,
        lng: city.center.lng,
        maxQuotes: quoteCap,
        quoteWindowEndsAt: now.add(const Duration(days: 5)),
        priorityUntil: now.subtract(ago),
        createdAt: now.subtract(ago),
        isPublic: true,
        groupBuy: group,
      );
      requests[id] = r;
      return r;
    }

    void tieredQuote(String id, BuyerRequest r, String sellerId, List<(num, int)> tiers) {
      final seller = sellers[sellerId]!;
      final unit = m(tiers.first.$2);
      quotes[id] = Quote(
        id: id,
        requestId: r.id,
        seller: _summary(seller, r),
        lines: [QuoteLine(description: r.title, qty: 1, unitPrice: unit)],
        subtotal: unit,
        tax: m(0),
        delivery: m(0),
        total: unit,
        validUntil: now.add(const Duration(days: 7)),
        createdAt: r.createdAt.add(const Duration(hours: 2)),
      );
      quoteSellerIds[id] = sellerId;
      quoteTiers[id] = [for (final t in tiers) PriceTier(minQty: t.$1, unitPrice: m(t.$2))];
      requests[r.id] = requests[r.id]!.copyWith(quoteCount: requests[r.id]!.quoteCount + 1);
    }

    final fans = post(
      'demo-post-group',
      'demo-neighbour-0',
      leaves.first.id,
      india ? 'Ceiling fans for our apartment block' : 'Window AC units for our building',
      india
          ? 'BLDC 1200 mm fans, white. I need 6; neighbours are welcome to join so we get a bulk price.'
          : '8,000 BTU window units. I need 2; join in and we all get the bulk price.',
      const Duration(hours: 20),
      group: true,
    );
    groupUnits[fans.id] = india ? 'fans' : 'units';
    groupMembers[fans.id] = {'demo-neighbour-0': india ? 6 : 2, 'demo-neighbour-1': india ? 4 : 3};
    tieredQuote(
      'demo-quote-g1',
      fans,
      _demoSellerIds[0],
      india ? [(1, 320000), (10, 290000), (25, 265000)] : [(1, 32900), (5, 29900), (10, 27500)],
    );
    tieredQuote(
      'demo-quote-g2',
      fans,
      _demoSellerIds[2],
      india ? [(1, 310000), (20, 275000)] : [(1, 31900), (8, 28500)],
    );
    comments[fans.id] = [
      FeedComment(
        id: 'demo-c1',
        requestId: fans.id,
        body: india ? 'Count me in for 4, we are in B block.' : 'In for 3, we are on the 4th floor.',
        authorName: neighbours[1].split(' ').first,
        createdAt: now.subtract(const Duration(hours: 18)),
      ),
      FeedComment(
        id: 'demo-c2',
        requestId: fans.id,
        parentId: 'demo-c1',
        body: india
            ? 'At 25 fans we can include free installation for everyone.'
            : 'At 10 units we include free installation for everyone.',
        authorName: sellers[_demoSellerIds[0]]!.businessName,
        asSeller: true,
        sellerId: _demoSellerIds[0],
        sellerVerified: sellers[_demoSellerIds[0]]!.isVerified,
        createdAt: now.subtract(const Duration(hours: 16)),
      ),
    ];
    likes[fans.id] = {'demo-neighbour-1', 'demo-neighbour-2'};

    final tap = post(
      'demo-post-plain',
      'demo-neighbour-2',
      leaves[1].id,
      india ? 'Plumber for a leaking kitchen tap' : 'Plumber for a leaking kitchen faucet',
      india ? 'Dripping all night. Can anyone recommend someone reliable?' : 'Dripping all night. Any recommendations?',
      const Duration(hours: 3),
    );
    comments[tap.id] = [
      FeedComment(
        id: 'demo-c3',
        requestId: tap.id,
        body: india ? 'QuickFix fixed ours in an hour last month.' : 'Handy Pros fixed ours in an hour last month.',
        authorName: neighbours[0].split(' ').first,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
    likes[tap.id] = {'demo-neighbour-0'};
  }

  // ------------------------------------------------------------ requests

  BuyerRequest createRequest(String buyerId, RequestDraft d, {required String title}) {
    final todayCount = requests.values
        .where((r) => r.buyerId == buyerId && DateTime.now().difference(r.createdAt).inHours < 24)
        .length;
    if (todayCount >= 10) throw StateError('rate_limited');
    final dup = requests.values.any(
      (r) =>
          r.buyerId == buyerId &&
          r.categoryId == d.categoryId &&
          r.description.trim().toLowerCase() == d.text.trim().toLowerCase() &&
          DateTime.now().difference(r.createdAt).inHours < 24,
    );
    if (dup) throw StateError('duplicate');
    final cat = categories.firstWhere((c) => c.id == d.categoryId);
    if (cat.isBlocked) throw StateError('blocked_category');
    final id = newId();
    final now = DateTime.now();
    final r = BuyerRequest(
      id: id,
      buyerId: buyerId,
      categoryId: d.categoryId!,
      title: title,
      description: d.text,
      fields: d.fields,
      budgetMin: d.budgetMin,
      budgetMax: d.budgetMax,
      budgetVisible: d.budgetVisible,
      neededBy: d.neededBy,
      lat: d.lat,
      lng: d.lng,
      locationCode: d.locationCode,
      locality: d.locality,
      state: d.state,
      audience: d.audience,
      maxQuotes: quoteCap,
      quoteWindowEndsAt: now.add(d.quoteWindow.duration),
      priorityUntil: now.add(const Duration(minutes: 15)),
      referenceLink: d.referenceLink,
      media: [for (final p in d.localMediaPaths) RequestMedia(path: p, url: p)],
      createdAt: now,
      notifiedSellers: _matchingSellers(d.categoryId!).length,
      isPublic: d.postToFeed || d.groupBuy,
      groupBuy: d.groupBuy,
    );
    requests[id] = r;
    if (d.groupBuy) {
      groupMembers[id] = {buyerId: d.groupQty};
      groupUnits[id] = (d.groupUnit ?? '').trim().isEmpty ? 'units' : d.groupUnit!.trim();
    }
    requestPrivate[id] = {'full_address': d.fullAddress, 'buyer_phone': profiles[buyerId]?.phone};
    for (final s in _matchingSellers(d.categoryId!)) {
      _notify(s, 'new_request', {'request_id': id, 'title': title});
    }
    notify();
    if (simulateMarket) _simulateQuotes(r);
    return r;
  }

  List<String> _matchingSellers(int categoryId) => sellers.values
      .where((s) => s.categoryIds.contains(categoryId) && s.id != currentUserId)
      .map((s) => s.id)
      .toList();

  void _simulateQuotes(BuyerRequest r) {
    final ids = [..._demoSellerIds]..shuffle(_random);
    final count = 3 + _random.nextInt(2);
    for (var i = 0; i < count && i < ids.length; i++) {
      Timer(Duration(seconds: 3 + i * 4), () {
        final current = requests[r.id];
        if (current == null || !current.isOpen) return;
        final base = (r.budgetMax ?? r.budgetMin)?.minorInt ?? (config.country == Country.india ? 2500000 : 89900);
        final price = (base * (85 + _random.nextInt(25)) ~/ 100) ~/ 100 * 100;
        try {
          final q = submitQuote(
            ids[i],
            QuoteDraft(
              requestId: r.id,
              lines: [QuoteLine(description: r.title, qty: 1, unitPrice: m(price))],
              delivery: m(i.isEven ? 0 : (config.country == Country.india ? 50000 : 4900)),
              taxRateBp: config.taxRule.defaultRateBp,
              // NYC 8.875%, Dallas 8.25% (ppm)
              salesTaxRatePpm: config.country == Country.india ? 0 : (r.state == 'Texas' ? 82500 : 88750),
              offeredBrandModel: r.fields['brand']?.toString(),
              deliveryDate: DateTime.now().add(Duration(days: 1 + i)),
              warranty: '${1 + i % 2} year',
              validDays: 7,
              notes: 'Free installation included.',
            ),
          );
          if (current.groupBuy) {
            quoteTiers[q.id] = [
              PriceTier(minQty: 1, unitPrice: m(price)),
              PriceTier(minQty: 10, unitPrice: m(price * 92 ~/ 10000 * 100)),
              PriceTier(minQty: 25, unitPrice: m(price * 85 ~/ 10000 * 100)),
            ];
            notify();
          }
        } on StateError {
          // Cap reached or request closed while simulating; ignore.
        }
      });
    }
  }

  // -------------------------------------------------------------- quotes

  Quote submitQuote(String sellerId, QuoteDraft d) {
    final r = requests[d.requestId];
    if (r == null || !r.isOpen) throw StateError('request_closed');
    if (r.quoteCount >= r.maxQuotes) throw StateError('cap_reached');
    if (quotes.values.any((q) => q.requestId == r.id && quoteSellerIds[q.id] == sellerId && q.isActive)) {
      throw StateError('already_quoted');
    }
    final cat = categories.firstWhere((c) => c.id == r.categoryId);
    if (cat.isBlocked) throw StateError('not_allowed');
    final seller = sellers[sellerId]!;
    final totals = config.taxRule.compute(
      lines: d.lines,
      delivery: d.delivery,
      rateBp: d.taxRateBp,
      ratePpm: d.salesTaxRatePpm,
      sellerState: seller.state,
      buyerState: r.state,
    );
    final id = newId();
    final q = Quote(
      id: id,
      requestId: r.id,
      seller: _summary(seller, r),
      lines: d.lines,
      subtotal: totals.subtotal,
      tax: totals.tax,
      taxBreakdown: totals.breakdown,
      delivery: totals.delivery,
      total: totals.total,
      offeredBrandModel: d.offeredBrandModel,
      deliveryDate: d.deliveryDate,
      warranty: d.warranty,
      validUntil: DateTime.now().add(Duration(days: d.validDays)),
      notes: d.notes,
      createdAt: DateTime.now(),
    );
    quotes[id] = q;
    quoteSellerIds[id] = sellerId;
    requests[r.id] = r.copyWith(quoteCount: r.quoteCount + 1, unreadQuotes: r.unreadQuotes + 1);
    sellers[sellerId] = seller.copyWith(quotesSent: seller.quotesSent + 1);
    _notify(r.buyerId, 'new_quote', {'request_id': r.id, 'quote_id': id, 'seller': seller.businessName});
    notify();
    return q;
  }

  SellerSummary _summary(Seller s, BuyerRequest r) => SellerSummary(
    id: s.id,
    businessName: s.businessName,
    logoUrl: s.logoUrl,
    ratingAvg: s.ratingAvg,
    ratingCount: s.ratingCount,
    verified: s.isVerified,
    avgResponseMins: s.avgResponseMins,
    distanceKm: (r.lat != null && s.lat != null) ? _km(r.lat!, r.lng!, s.lat!, s.lng!) : null,
    earlyPartner: s.earlyPartner,
  );

  static double _km(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(a));
  }

  String acceptQuote(String buyerId, String quoteId) {
    final q = quotes[quoteId]!;
    final r = requests[q.requestId]!;
    if (r.buyerId != buyerId) throw StateError('not_allowed');
    if (!r.isOpen) throw StateError('request_closed');
    for (final other in quotes.values.where((x) => x.requestId == r.id).toList()) {
      if (other.id == quoteId) {
        quotes[other.id] = other.copyWith(status: QuoteStatus.accepted);
      } else if (other.isActive) {
        quotes[other.id] = other.copyWith(status: QuoteStatus.declined);
        _notify(quoteSellerIds[other.id]!, 'quote_declined', {'request_id': r.id, 'quote_id': other.id});
      }
    }
    requests[r.id] = r.copyWith(status: RequestStatus.awarded, acceptedQuoteId: quoteId);
    final sellerId = quoteSellerIds[quoteId]!;
    final seller = sellers[sellerId]!;
    sellers[sellerId] = seller.copyWith(quotesWon: seller.quotesWon + 1);
    final orderId = newId();
    final now = DateTime.now();
    orders[orderId] = Order(
      id: orderId,
      requestId: r.id,
      quoteId: quoteId,
      buyerId: buyerId,
      sellerId: sellerId,
      title: r.title,
      sellerName: seller.businessName,
      buyerName: profiles[buyerId]?.name,
      sellerPhone: seller.phone,
      buyerPhone: requestPrivate[r.id]?['buyer_phone'],
      fullAddress: requestPrivate[r.id]?['full_address'],
      total: q.total,
      events: [OrderEvent(status: OrderStatus.accepted, at: now)],
      createdAt: now,
    );
    _notify(sellerId, 'quote_accepted', {'order_id': orderId, 'request_id': r.id});
    notify();
    return orderId;
  }

  void updateQuote(String quoteId, Quote Function(Quote) f, {String? notifySellerType}) {
    final q = quotes[quoteId]!;
    quotes[quoteId] = f(q);
    if (notifySellerType != null) {
      _notify(quoteSellerIds[quoteId]!, notifySellerType, {'request_id': q.requestId, 'quote_id': quoteId});
    }
    notify();
  }

  // --------------------------------------------------------------- chats

  String openChat(String requestId, String sellerId) {
    final existing = chats.values.where((c) => c.requestId == requestId && c.sellerId == sellerId).firstOrNull;
    if (existing != null) return existing.id;
    final r = requests[requestId]!;
    final id = newId();
    chats[id] = Chat(
      id: id,
      requestId: requestId,
      buyerId: r.buyerId,
      sellerId: sellerId,
      requestTitle: r.title,
      counterpartName: '',
    );
    messages[id] = [];
    notify();
    return id;
  }

  void sendMessage(
    String chatId,
    String senderId,
    String body, {
    MessageType type = MessageType.text,
    String? attachment,
  }) {
    final msg = ChatMessage(
      id: newId(),
      chatId: chatId,
      senderId: senderId,
      type: type,
      body: body,
      attachmentPath: attachment,
      attachmentUrl: attachment,
      createdAt: DateTime.now(),
    );
    messages.putIfAbsent(chatId, () => []).add(msg);
    final c = chats[chatId]!;
    chats[chatId] = c.copyWith(lastMessage: type == MessageType.image ? '📷' : body, lastMessageAt: msg.createdAt);
    final to = senderId == c.buyerId ? c.sellerId : c.buyerId;
    _notify(to, 'message', {'chat_id': chatId});
    notify();
    if (simulateMarket && senderId == c.buyerId && _demoSellerIds.contains(c.sellerId)) {
      Timer(const Duration(seconds: 2), () {
        sendMessage(
          chatId,
          c.sellerId,
          config.country == Country.india
              ? 'Namaste! Yes, this is available. Delivery and installation are included.'
              : 'Hi! Yes, this is in stock. Delivery and installation are included.',
        );
      });
    }
  }

  // -------------------------------------------------------- notifications

  void _notify(String userId, String type, Map<String, Object?> payload) {
    notifications
        .putIfAbsent(userId, () => [])
        .insert(0, AppNotification(id: newId(), type: type, payload: payload, createdAt: DateTime.now()));
  }

  void addNotification(String userId, String type, Map<String, Object?> payload) {
    _notify(userId, type, payload);
    notify();
  }

  void dispose() {
    _changes.close();
    _sessionChanges.close();
  }
}
