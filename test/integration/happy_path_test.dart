// Happy path (brief Section 14) against a running local Supabase stack:
// buyer posts a request, a seller sees it in the lead feed and quotes, the
// buyer sees the quote with the right totals and accepts it, both parties
// get the order and the chat, a message goes both ways and the contacts
// unlock.
//
// Skipped unless SUPABASE_URL and SUPABASE_ANON_KEY are set:
//
//   supabase start
//   eval "$(supabase status -o env)"
//   SUPABASE_URL=$API_URL SUPABASE_ANON_KEY=$ANON_KEY COUNTRY=india flutter test test/integration
//
// COUNTRY (india | usa, default india) must match the seed the stack was
// started with (config.toml seeds India; see supabase/README.md "Per-country
// seeds" for the USA). Only the anon key is used: both users sign in with
// the test phone numbers from config.toml [auth.sms.test_otp] (code 123456)
// and every call goes through the app's own Supabase repositories.
//
// Reruns: each run posts a request with a unique title (no duplicate_request)
// and leaves it awarded. The buyer may post 10 requests per rolling 24 h, so
// after a handful of local reruns in one day, `supabase db reset`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/config/country_config.dart';
import 'package:iwant/core/data/backend.dart';
import 'package:iwant/core/data/supabase/supabase_backend.dart';
import 'package:iwant/core/money/money.dart';
import 'package:iwant/core/money/tax.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/country/usa/usa_config.dart';
import 'package:iwant/features/auth/domain/app_user.dart';
import 'package:iwant/features/orders/domain/order.dart';
import 'package:iwant/features/quotes/domain/quote.dart';
import 'package:iwant/features/requests/domain/buyer_request.dart';
import 'package:iwant/features/seller/domain/lead.dart';
import 'package:iwant/features/seller/domain/seller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Per-country inputs. Category slugs and postal codes exist in
/// `supabase/seed/<country>.sql`; the phones are the dev test accounts
/// created by `supabase/seed/<country>_demo.sql` (API.md section 10).
class _Fixture {
  const _Fixture({
    required this.config,
    required this.buyerPhone,
    required this.sellerPhone,
    required this.categorySlug,
    required this.postalCode,
    required this.fields,
    required this.lines,
    required this.deliveryMinor,
    this.gstRateBp = 0,
    this.salesTaxRatePpm = 0,
  });

  final CountryConfig config;
  final String buyerPhone;

  /// The *verified* test seller: new requests start with a 15-minute
  /// verified-first priority window (priority_window_minutes), during which
  /// an unverified seller neither sees nor may quote the lead.
  final String sellerPhone;
  final String categorySlug;
  final String postalCode;
  final Map<String, Object?> fields;
  final List<(String, int, int)> lines; // description, qty, unit price (minor)
  final int deliveryMinor;
  final int gstRateBp;
  final int salesTaxRatePpm;
}

const _india = _Fixture(
  config: indiaConfig,
  buyerPhone: '+910000000001',
  sellerPhone: '+910000000003',
  categorySlug: 'plumbing', // allowed leaf, one required request field
  postalCode: '560001', // Bengaluru, the test accounts' demo city
  fields: {'problem': 'Kitchen sink tap is leaking and needs a new washer'},
  lines: [('Replace kitchen tap washer', 1, 45000), ('Labour per visit', 3, 33333)],
  deliveryMinor: 30000,
  gstRateBp: 1800,
);

const _usa = _Fixture(
  config: usaConfig,
  buyerPhone: '+15555550100',
  sellerPhone: '+15555550102',
  categorySlug: 'handyman', // plumbing is licence-restricted in the USA seed
  postalCode: '10001', // New York, the test accounts' demo city
  fields: {'problem': 'Mount a TV and assemble two bookshelves'},
  lines: [('TV wall mount install', 1, 12999), ('Bookshelf assembly', 2, 4550)],
  deliveryMinor: 2500,
  salesTaxRatePpm: 88750, // NYC 8.875 %
);

const _otp = '123456';
const _timeout = Duration(seconds: 20);

void main() {
  final env = Platform.environment;
  final url = env['SUPABASE_URL'] ?? '';
  final anonKey = env['SUPABASE_ANON_KEY'] ?? '';
  final country = (env['COUNTRY'] ?? 'india').trim().toLowerCase();
  final fx = switch (country) {
    'usa' || 'us' => _usa,
    _ => _india,
  };
  final skip = url.isEmpty || anonKey.isEmpty
      ? 'Set SUPABASE_URL and SUPABASE_ANON_KEY (local stack) to run the integration test'
      : null;

  group('Happy path against local Supabase ($country)', skip: skip, () {
    late SupabaseClient buyerClient;
    late SupabaseClient sellerClient;
    late Backend buyer;
    late Backend seller;

    setUpAll(() async {
      // flutter_test may install HTTP overrides that answer every request
      // with 400; this test talks to a real server.
      HttpOverrides.global = null;
      SupabaseClient newClient() => SupabaseClient(
        url,
        anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false, authFlowType: AuthFlowType.implicit),
      );
      buyerClient = newClient();
      sellerClient = newClient();
      buyer = createSupabaseBackend(fx.config, client: buyerClient);
      seller = createSupabaseBackend(fx.config, client: sellerClient);
    });

    tearDownAll(() async {
      for (final b in [buyer, seller]) {
        try {
          await b.auth.signOut();
        } catch (_) {}
        b.dispose();
      }
      await buyerClient.dispose();
      await sellerClient.dispose();
    });

    test('buyer posts a request, seller quotes, buyer accepts', timeout: const Timeout(Duration(minutes: 3)), () async {
      final tag = DateTime.now().toUtc().millisecondsSinceEpoch.toRadixString(36);
      final currency = fx.config.currencyCode;
      Money m(int minor) => moneyFromMinor(minor, currency);

      // 1. Both users sign in with phone OTP (test numbers, fixed code).
      for (final (b, phone) in [(buyer, fx.buyerPhone), (seller, fx.sellerPhone)]) {
        await b.auth.sendPhoneOtp(phone);
        await b.auth.verifyPhoneOtp(phone, _otp);
        expect(b.auth.currentSession, isNotNull, reason: 'signed in as $phone');
      }
      final buyerId = buyer.auth.currentSession!.userId;
      final sellerId = seller.auth.currentSession!.userId;
      expect(buyerId, isNot(sellerId));

      final sellerProfile = await seller.profiles.fetchMyProfile();
      expect(sellerProfile?.isSeller, isTrue, reason: '${fx.sellerPhone} is a seeded seller');
      await seller.profiles.setActiveMode(AppMode.seller);

      // 2. Category (seeded) and the seller covering it and the location.
      final categoryRow = await buyerClient
          .from('categories')
          .select('id')
          .eq('slug', fx.categorySlug)
          .single()
          .timeout(_timeout);
      final categoryId = (categoryRow['id'] as num).toInt();
      final categories = await buyer.categories.fetchAll(forceRefresh: true);
      expect(categories.map((c) => c.id), contains(categoryId));

      var me = await seller.sellers.getSeller(sellerId);
      expect(me, isNotNull, reason: 'seed creates the seller profile');
      me = await seller.sellers.upsertSeller(
        me!.copyWith(
          categoryIds: {...me.categoryIds, categoryId}.toList(),
          // A "codes" seller must list the request's postal code.
          serviceCodes: me.areaType == AreaType.codes ? {...me.serviceCodes, fx.postalCode}.toList() : me.serviceCodes,
        ),
      );
      expect(me.categoryIds, contains(categoryId));
      expect(me.isVerified, isTrue, reason: 'the verified test seller skips the priority window');

      // 3. Buyer posts the request: pinned at the seller's centre for a
      //    radius seller (the seeded centre is randomised), plus a seeded
      //    postal code for city / state.
      final pinAtSeller = me.areaType == AreaType.radius && me.lat != null && me.lng != null;
      final title = 'Integration test $tag';
      final request = await buyer.requests.createRequest(
        RequestDraft(
          text: '$title\nHappy path check from test/integration.',
          categoryId: categoryId,
          fields: fx.fields,
          budgetMin: m(1000),
          budgetMax: m(5000000),
          lat: pinAtSeller ? me.lat : null,
          lng: pinAtSeller ? me.lng : null,
          locationCode: fx.postalCode,
          fullAddress: '12 Test Street, $tag',
        ),
      );
      expect(request.title, title);
      expect(request.status, RequestStatus.open);
      expect(request.buyerId, buyerId);
      expect(request.notifiedSellers, greaterThanOrEqualTo(1), reason: 'the seller matches');

      // Contacts are private until an order exists.
      final privateBefore = await sellerClient.from('request_private').select().eq('request_id', request.id);
      expect(privateBefore, isEmpty);

      // 4. Seller finds it in the lead feed and opens it.
      final page = await seller.leads.feed(LeadFilters(categoryId: categoryId));
      final lead = page.leads.where((l) => l.requestId == request.id).firstOrNull;
      expect(lead, isNotNull, reason: 'new request in the lead feed');
      expect(lead!.title, title);
      expect(lead.alreadyQuoted, isFalse);
      final detail = await seller.leads.lead(request.id);
      expect(detail?.requestId, request.id);
      await seller.leads.markSeen(request.id);

      // 5. Seller quotes (GST per line in India, sales tax ppm in the USA).
      final lines = [for (final (d, q, p) in fx.lines) QuoteLine(description: d, qty: q, unitPrice: m(p))];
      final draft = QuoteDraft(
        requestId: request.id,
        lines: lines,
        delivery: m(fx.deliveryMinor),
        taxRateBp: fx.gstRateBp,
        salesTaxRatePpm: fx.salesTaxRatePpm,
        warranty: '6 months',
        validDays: 7,
        notes: 'Integration test quote $tag',
      );
      final sent = await seller.quotes.submitQuote(draft);
      expect(sent.requestId, request.id);
      expect(sent.status, QuoteStatus.sent);

      // Expected totals from the app's own tax rule (same rounding as SQL).
      final expected = fx.config.taxRule.compute(
        lines: lines,
        delivery: m(fx.deliveryMinor),
        rateBp: fx.gstRateBp,
        ratePpm: fx.salesTaxRatePpm,
        sellerState: me.state,
        buyerState: detail?.state ?? request.state,
      );
      expect(expected.tax.isZeroAmount, isFalse);

      // 6. Buyer sees the quote with the right totals.
      final quotes = await buyer.quotes.watchQuotesForRequest(request.id).first.timeout(_timeout);
      final quote = quotes.singleWhere((q) => q.id == sent.id);
      expect(quote.seller.id, sellerId);
      expect(quote.subtotal.minorInt, expected.subtotal.minorInt, reason: 'subtotal');
      expect(quote.tax.minorInt, expected.tax.minorInt, reason: 'tax');
      expect(quote.delivery.minorInt, fx.deliveryMinor, reason: 'delivery');
      expect(quote.total.minorInt, expected.total.minorInt, reason: 'total');
      expect(quote.total.minorInt, quote.subtotal.minorInt + quote.tax.minorInt + quote.delivery.minorInt);
      expect(quote.lines, hasLength(lines.length));
      switch (quote.taxBreakdown) {
        case final GstBreakdown g:
          expect(fx.config.taxRule, isA<GstTaxRule>());
          final e = expected.breakdown as GstBreakdown;
          expect(g.rateBp, fx.gstRateBp);
          expect(g.intraState, e.intraState);
          expect(
            [g.cgst.minorInt, g.sgst.minorInt, g.igst.minorInt],
            [e.cgst.minorInt, e.sgst.minorInt, e.igst.minorInt],
          );
        case final SalesTaxBreakdown s:
          expect(fx.config.taxRule, isA<SalesTaxRule>());
          expect(s.ratePpm, fx.salesTaxRatePpm);
          expect(s.amount.minorInt, expected.tax.minorInt);
        case NoTaxBreakdown():
          fail('quote has no tax breakdown');
      }

      // 7. Buyer accepts: the request is awarded and an order exists.
      final orderId = await buyer.quotes.acceptQuote(quote.id);
      final accepted = await buyer.quotes.getQuote(quote.id);
      expect(accepted?.status, QuoteStatus.accepted);
      final awarded = await buyer.requests.watchRequest(request.id).first.timeout(_timeout);
      expect(awarded?.status, RequestStatus.awarded);
      expect(awarded?.acceptedQuoteId, quote.id);

      // 8. The order is visible to both parties, with the contacts unlocked
      //    (watchOrder reads get_order_contacts).
      for (final b in [buyer, seller]) {
        final orders = await b.orders.watchMyOrders().first.timeout(_timeout);
        final o = orders.where((o) => o.id == orderId).firstOrNull;
        expect(o, isNotNull, reason: 'order in my orders');
        expect(o!.quoteId, quote.id);
        expect(o.buyerId, buyerId);
        expect(o.sellerId, sellerId);
        expect(o.status, OrderStatus.accepted);
        expect(o.total.minorInt, expected.total.minorInt);
        expect(o.title, title);
      }
      final sellerView = await seller.orders.watchOrder(orderId).first.timeout(_timeout);
      expect(sellerView?.buyerPhone, isNotNull, reason: 'buyer phone unlocked for the seller');
      final buyerDigits = fx.buyerPhone.replaceAll(RegExp(r'\D'), '');
      expect(
        sellerView!.buyerPhone!.replaceAll(RegExp(r'\D'), ''),
        endsWith(buyerDigits.substring(buyerDigits.length - 4)),
      );
      expect(sellerView.fullAddress, '12 Test Street, $tag');
      final buyerView = await buyer.orders.watchOrder(orderId).first.timeout(_timeout);
      expect(buyerView?.sellerName, me.businessName);
      expect(buyerView?.sellerPhone, isNotNull, reason: 'seller phone unlocked for the buyer');

      // 9. The chat exists for both and a message goes both ways.
      final chatId = await buyer.chats.openChat(requestId: request.id, sellerId: sellerId);
      final sellerChats = await seller.chats.watchMyChats().first.timeout(_timeout);
      final sellerChat = sellerChats.where((c) => c.id == chatId).firstOrNull;
      expect(sellerChat, isNotNull, reason: 'seller sees the chat');
      expect(sellerChat!.requestId, request.id);
      expect(sellerChat.buyerId, buyerId);
      expect(sellerChat.quoteAccepted, isTrue);

      final hello = 'Hello from the buyer, see you soon ($tag)';
      await buyer.chats.sendText(chatId, hello);
      final atSeller = await seller.chats.watchMessages(chatId).first.timeout(_timeout);
      expect(atSeller.where((x) => x.body == hello && x.senderId == buyerId), hasLength(1));

      final reply = 'Thanks, confirmed from the seller ($tag)';
      await seller.chats.sendText(chatId, reply);
      await seller.chats.markRead(chatId);
      final atBuyer = await buyer.chats
          .watchMessages(chatId)
          .firstWhere((list) => list.any((x) => x.body == reply))
          .timeout(_timeout);
      expect(atBuyer.where((x) => x.body == reply && x.senderId == sellerId), hasLength(1));
      expect(atBuyer.where((x) => x.body == hello), hasLength(1), reason: 'no duplicate of the optimistic copy');
    });
  });
}
