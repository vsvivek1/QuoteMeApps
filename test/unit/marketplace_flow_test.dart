import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/demo/demo_backend.dart';
import 'package:iwant/core/demo/demo_repositories.dart';
import 'package:iwant/core/money/money.dart';
import 'package:iwant/core/money/tax.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/country/usa/usa_config.dart';
import 'package:iwant/features/auth/domain/app_user.dart';
import 'package:iwant/features/orders/domain/order.dart';
import 'package:iwant/features/quotes/domain/quote.dart';
import 'package:iwant/features/quotes/domain/quote_repository.dart';
import 'package:iwant/features/requests/domain/buyer_request.dart';
import 'package:iwant/features/requests/domain/request_repository.dart';
import 'package:iwant/features/seller/domain/lead.dart';
import 'package:iwant/features/seller/domain/seller.dart';

/// The happy path from Section 14 against the in-memory backend, which
/// mirrors the server rules (the same flow runs against the local Supabase
/// stack in integration tests).
void main() {
  group('India: buyer posts, sellers quote, buyer accepts', () {
    late DemoBackend b;
    late DemoRequestRepository requests;
    late DemoQuoteRepository quotes;
    late DemoLeadRepository leads;
    late DemoSellerRepository sellers;
    late DemoReviewRepository reviews;
    late DemoOrderRepository orders;

    setUp(() {
      b = DemoBackend(indiaConfig, simulateMarket: false);
      requests = DemoRequestRepository(b);
      quotes = DemoQuoteRepository(b);
      leads = DemoLeadRepository(b);
      sellers = DemoSellerRepository(b);
      reviews = DemoReviewRepository(b);
      orders = DemoOrderRepository(b);
    });

    tearDown(() => b.dispose());

    int fridgeId() => b.categories.firstWhere((c) => c.names['en'] == 'Refrigerators').id;

    Future<BuyerRequest> post() async {
      b.signInAs(b.demoBuyerId);
      return requests.createRequest(RequestDraft(
        text: 'Samsung 300L double door fridge',
        categoryId: fridgeId(),
        lat: 12.9716,
        lng: 77.5946,
        locationCode: '560034',
        state: 'Karnataka',
        fullAddress: '12 MG Road',
        budgetMax: indiaConfig.money(3000000),
      ));
    }

    QuoteDraft draft(String requestId, int price) => QuoteDraft(
          requestId: requestId,
          lines: [QuoteLine(description: 'Fridge', qty: 1, unitPrice: indiaConfig.money(price))],
          delivery: indiaConfig.zero,
          taxRateBp: 1800,
          validDays: 7,
        );

    test('request appears in matching sellers\' lead feed without private details', () async {
      final r = await post();
      b.signInAs('demo-seller-1'); // unverified: waits out the priority window
      expect((await leads.feed(const LeadFilters())).leads, isEmpty);
      b.signInAs('demo-seller-0'); // verified
      final feed = await leads.feed(const LeadFilters());
      expect(feed.leads.map((l) => l.requestId), contains(r.id));
      // Leads never carry the full address or buyer phone (no such fields).
      expect(feed.leads.first.locationCode, '560034');
    });

    test('quote is taxed with GST and capped at max quotes', () async {
      final r = await post();
      b.quoteCap = 2;
      b.requests[r.id] = b.requests[r.id]!.copyWith(maxQuotes: 2, priorityUntil: DateTime(2000));
      b.signInAs('demo-seller-0');
      final q = await quotes.submitQuote(draft(r.id, 2500000));
      expect((q.taxBreakdown as GstBreakdown).intraState, isTrue);
      expect(q.total.minorInt, 2500000 + 450000);
      b.signInAs('demo-seller-1');
      await quotes.submitQuote(draft(r.id, 2400000));
      b.signInAs('demo-seller-2');
      expect(() => quotes.submitQuote(draft(r.id, 2300000)),
          throwsA(isA<QuoteFailure>().having((e) => e.code, 'code', 'cap_reached')));
    });

    test('accepting closes the request, declines others, unlocks contact, allows review after completion', () async {
      final r = await post();
      b.requests[r.id] = b.requests[r.id]!.copyWith(priorityUntil: DateTime(2000));
      b.signInAs('demo-seller-0');
      final q1 = await quotes.submitQuote(draft(r.id, 2500000));
      b.signInAs('demo-seller-1');
      final q2 = await quotes.submitQuote(draft(r.id, 2600000));

      b.signInAs(b.demoBuyerId);
      final orderId = await quotes.acceptQuote(q1.id);
      expect(b.requests[r.id]!.status, RequestStatus.awarded);
      expect(b.quotes[q1.id]!.status, QuoteStatus.accepted);
      expect(b.quotes[q2.id]!.status, QuoteStatus.declined);
      final order = b.orders[orderId]!;
      expect(order.fullAddress, '12 MG Road');
      expect(order.sellerPhone, isNotNull);

      expect(() => reviews.submitReview(orderId: orderId, stars: 5), throwsStateError);
      await orders.updateStatus(orderId, OrderStatus.completed);
      final before = b.sellers['demo-seller-0']!.ratingCount;
      await reviews.submitReview(orderId: orderId, stars: 5, text: 'Great');
      expect(b.sellers['demo-seller-0']!.ratingCount, before + 1);

      b.signInAs('demo-seller-2');
      expect(() => quotes.submitQuote(draft(r.id, 1)),
          throwsA(isA<QuoteFailure>().having((e) => e.code, 'code', 'request_closed')));
    });

    test('blocked categories and duplicate requests are refused', () async {
      b.signInAs(b.demoBuyerId);
      final insurance = b.categories.firstWhere((c) => c.names['en'] == 'Insurance');
      expect(
        () => requests.createRequest(RequestDraft(text: 'health insurance', categoryId: insurance.id)),
        throwsA(isA<RequestFailure>().having((e) => e.code, 'code', 'blocked_category')),
      );
      await post();
      expect(() => post(), throwsA(isA<RequestFailure>().having((e) => e.code, 'code', 'duplicate')));
    });

    test('keyword classifier catches blocked free text', () async {
      final repo = DemoCategoryRepository(b);
      expect((await repo.blockedMatch('need a personal loan urgently'))?.names['en'], 'Loans and credit');
      expect((await repo.suggest('fridge 300 litre')).first.names['en'], 'Refrigerators');
    });

    test('becoming a seller adds the role and switches mode', () async {
      b.signInWithPhone('+910000000009');
      final id = b.currentUserId!;
      await sellers.upsertSeller(const Seller(id: '', businessName: 'Test Traders', categoryIds: [1]));
      expect(b.profiles[id]!.roles, contains(UserRole.seller));
      expect(b.profiles[id]!.activeMode, AppMode.seller);
    });
  });

  test('USA: sales tax on a quote', () async {
    final b = DemoBackend(usaConfig, simulateMarket: false);
    addTearDown(b.dispose);
    b.signInAs(b.demoBuyerId);
    final cat = b.categories.firstWhere((c) => c.names['en'] == 'TVs');
    final r = await DemoRequestRepository(b).createRequest(RequestDraft(text: '65 inch TV', categoryId: cat.id, state: 'Texas'));
    b.requests[r.id] = b.requests[r.id]!.copyWith(priorityUntil: DateTime(2000));
    b.signInAs('demo-seller-1');
    final q = await DemoQuoteRepository(b).submitQuote(QuoteDraft(
      requestId: r.id,
      lines: [QuoteLine(description: 'TV', qty: 1, unitPrice: usaConfig.money(89999))],
      delivery: usaConfig.money(4900),
      taxRateBp: 825,
      validDays: 7,
    ));
    expect(q.tax.minorInt, 7425); // 89999 x 8.25% = 7424.9175 cents
    expect(q.total.minorInt, 89999 + 7425 + 4900);
  });
}
