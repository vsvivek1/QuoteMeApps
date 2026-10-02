import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/data/supabase/mappers.dart';
import 'package:iwant/core/money/money.dart';
import 'package:iwant/core/money/tax.dart';
import 'package:iwant/features/auth/domain/app_user.dart';
import 'package:iwant/features/chat/domain/chat.dart';
import 'package:iwant/features/orders/domain/order.dart';
import 'package:iwant/features/quotes/domain/quote.dart';
import 'package:iwant/features/requests/domain/buyer_request.dart';
import 'package:iwant/features/seller/domain/lead.dart';
import 'package:iwant/features/seller/domain/seller.dart';

/// Hex EWKB for POINT(lng lat) SRID 4326, as PostgREST returns geography.
String ewkbPoint(double lng, double lat) {
  final b = ByteData(25)
    ..setUint8(0, 1)
    ..setUint32(1, 0x20000001, Endian.little)
    ..setUint32(5, 4326, Endian.little)
    ..setFloat64(9, lng, Endian.little)
    ..setFloat64(17, lat, Endian.little);
  return [for (var i = 0; i < 25; i++) b.getUint8(i).toRadixString(16).padLeft(2, '0')].join().toUpperCase();
}

Map<String, dynamic> quoteRow({
  required String currency,
  required Map<String, dynamic> breakdown,
  required int subtotal,
  required int tax,
  int delivery = 0,
}) => {
  'id': 'q1',
  'request_id': 'r1',
  'seller_id': 's1',
  'subtotal_minor': subtotal,
  'tax_minor': tax,
  'tax_breakdown': breakdown,
  'delivery_minor': delivery,
  'total_minor': subtotal + tax + delivery,
  'currency': currency,
  'offered_brand_model': 'Samsung RT34',
  'delivery_date': '2026-10-05',
  'valid_until': '2026-10-09',
  'warranty': '1 year',
  'notes': 'Free installation',
  'status': 'shortlisted',
  'counter_target_minor': null,
  'created_at': '2026-10-02T06:30:00.000000+00:00',
  'updated_at': '2026-10-02T07:00:00+00:00',
  'quote_line_items': [
    {'sort': 1, 'description': 'Stand', 'qty': 1, 'unit_price_minor': 333, 'line_total_minor': 333},
    {'sort': 0, 'description': 'Fridge', 'qty': '1.000', 'unit_price_minor': 99999, 'line_total_minor': 99999},
  ],
  'seller': {
    'id': 's1',
    'business_name': 'Sharma Electronics',
    'logo_url': null,
    'rating_avg': 4.35,
    'rating_count': 12,
    'verification_status': 'verified',
    'avg_response_mins': 25,
    'early_partner': true,
  },
};

void main() {
  group('scalars', () {
    test('timestamps become local, dates local midnight', () {
      final t = parseTimestamp('2026-10-02T06:30:00+00:00')!;
      expect(t.isUtc, isFalse);
      expect(t.toUtc(), DateTime.utc(2026, 10, 2, 6, 30));
      expect(parseDate('2026-10-05'), DateTime(2026, 10, 5));
      expect(formatDate(DateTime(2026, 1, 9)), '2026-01-09');
      expect(parseTimestamp(null), isNull);
    });

    test('money from integer minor units only', () {
      final m = moneyOrNull(129950, 'INR')!;
      expect(m.minorInt, 129950);
      expect(m.isoCode, 'INR');
      expect(moneyOrNull(null, 'USD'), isNull);
    });

    test('geography points: EWKB hex and GeoJSON', () {
      final p = parsePoint(ewkbPoint(77.5946, 12.9716))!;
      expect(p.lat, closeTo(12.9716, 1e-9));
      expect(p.lng, closeTo(77.5946, 1e-9));
      final g = parsePoint({
        'type': 'Point',
        'coordinates': [-74.006, 40.7128],
      })!;
      expect(g.lat, 40.7128);
      expect(g.lng, -74.006);
      expect(parsePoint('not a point'), isNull);
    });

    test('JWT claims', () {
      String seg(Map<String, Object?> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
      final token =
          '${seg({'alg': 'HS256'})}.${seg({
            'sub': 'u1',
            'roles': ['buyer', 'seller'],
            'active_mode': 'seller',
            'account_status': 'suspended',
            'seller_verified': true,
          })}.sig';
      final c = claimsFromJwt(token);
      expect(c.roles, ['buyer', 'seller']);
      expect(c.activeMode, 'seller');
      expect(c.accountStatus, 'suspended');
      expect(c.isActive, isFalse);
      expect(c.sellerVerified, isTrue);
      expect(claimsFromJwt('garbage').roles, ['buyer']);
    });
  });

  group('request', () {
    test('maps a buyer request row with media and budget', () {
      final r = mapRequest(
        {
          'id': 'r1',
          'buyer_id': 'b1',
          'category_id': 12,
          'title': 'Samsung fridge',
          'description': 'Double door',
          'fields': {'capacity_l': 300},
          'budget_min_minor': 2000000,
          'budget_max_minor': 2500000,
          'currency': 'INR',
          'budget_visible': false,
          'needed_by': '2026-10-10',
          'location': ewkbPoint(77.595, 12.972),
          'location_code': '560034',
          'locality': 'Koramangala',
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'audience': 'local',
          'status': 'awarded',
          'quote_count': 3,
          'max_quotes': 10,
          'priority_until': '2026-10-02T06:15:00Z',
          'quote_window_ends_at': '2026-10-04T06:00:00Z',
          'accepted_quote_id': 'q1',
          'reference_url': 'https://example.com',
          'created_at': '2026-10-02T06:00:00Z',
          'request_media': [
            {'file_path': 'r1/b.jpg', 'type': 'image', 'sort': 1, 'hidden': false},
            {'file_path': 'r1/a.mp4', 'type': 'video', 'sort': 0, 'hidden': false},
            {'file_path': 'r1/x.jpg', 'type': 'image', 'sort': 2, 'hidden': true},
          ],
        },
        fallbackCurrency: 'USD',
        notifiedSellers: 7,
      );
      expect(r.categoryId, 12);
      expect(r.budgetMin!.minorInt, 2000000);
      expect(r.budgetMax!.isoCode, 'INR');
      expect(r.budgetVisible, isFalse);
      expect(r.neededBy, DateTime(2026, 10, 10));
      expect(r.lat, closeTo(12.972, 1e-9));
      expect(r.audience, Audience.local);
      expect(r.status, RequestStatus.awarded);
      expect(r.quoteCount, 3);
      expect(r.acceptedQuoteId, 'q1');
      expect(r.referenceLink, 'https://example.com');
      expect(r.media.map((m) => m.path), ['r1/a.mp4', 'r1/b.jpg']);
      expect(r.media.first.type, 'video');
      expect(r.notifiedSellers, 7);
      expect(r.createdAt.toUtc(), DateTime.utc(2026, 10, 2, 6));
    });

    test('null budget and unknown status fall back safely', () {
      final r = mapRequest({
        'id': 'r2',
        'buyer_id': 'b1',
        'category_id': 3,
        'title': 'Movers',
        'status': 'weird',
        'created_at': '2026-10-02T06:00:00Z',
      }, fallbackCurrency: 'USD');
      expect(r.budgetMin, isNull);
      expect(r.status, RequestStatus.open);
      expect(r.media, isEmpty);
    });
  });

  group('quote', () {
    test('India GST intra-state breakdown', () {
      final q = mapQuote(
        quoteRow(
          currency: 'INR',
          subtotal: 100332,
          tax: 18016,
          delivery: 5000,
          breakdown: {'kind': 'gst', 'mode': 'intra', 'rate_bp': 1800, 'cgst': 9008, 'sgst': 9008, 'igst': 0},
        ),
        fallbackCurrency: 'USD',
      );
      expect(q.subtotal.minorInt, 100332);
      expect(q.tax.minorInt, 18016);
      expect(q.delivery.minorInt, 5000);
      expect(q.total.minorInt, 123348);
      expect(q.total.isoCode, 'INR');
      final b = q.taxBreakdown as GstBreakdown;
      expect(b.intraState, isTrue);
      expect(b.rateBp, 1800);
      expect(b.cgst.minorInt, 9008);
      expect(b.sgst.minorInt, 9008);
      expect(b.igst.minorInt, 0);
      expect(q.lines.map((l) => l.description), ['Fridge', 'Stand']);
      expect(q.lines.first.unitPrice.minorInt, 99999);
      expect(q.lines.first.qty, 1);
      expect(q.status, QuoteStatus.shortlisted);
      expect(q.deliveryDate, DateTime(2026, 10, 5));
      expect(q.validUntil, DateTime(2026, 10, 9));
      expect(q.seller.businessName, 'Sharma Electronics');
      expect(q.seller.verified, isTrue);
      expect(q.seller.ratingAvg, 4.35);
      expect(q.seller.earlyPartner, isTrue);
    });

    test('India GST inter-state breakdown', () {
      final q = mapQuote(
        quoteRow(
          currency: 'INR',
          subtotal: 99999,
          tax: 18000,
          delivery: 5000,
          breakdown: {'kind': 'gst', 'mode': 'inter', 'rate_bp': 1800, 'cgst': 0, 'sgst': 0, 'igst': 18000},
        ),
        fallbackCurrency: 'INR',
      );
      final b = q.taxBreakdown as GstBreakdown;
      expect(b.intraState, isFalse);
      expect(b.igst.minorInt, 18000);
      expect(b.total.minorInt, q.tax.minorInt);
      expect(q.total.minorInt, 122999);
    });

    test('US sales tax breakdown and counter offer', () {
      final row = quoteRow(
        currency: 'USD',
        subtotal: 1999,
        tax: 165,
        delivery: 500,
        breakdown: {'kind': 'sales_tax', 'rate_bp': 825, 'amount': 165},
      )..addAll({'counter_target_minor': 1800, 'counter_note': 'Can you do 18?', 'status': 'revised'});
      final q = mapQuote(row, fallbackCurrency: 'INR');
      final b = q.taxBreakdown as SalesTaxBreakdown;
      expect(b.rateBp, 825);
      expect(b.amount.minorInt, 165);
      expect(b.amount.isoCode, 'USD');
      expect(q.total.minorInt, 2664);
      expect(q.counterOfferTarget!.minorInt, 1800);
      expect(q.counterOfferNote, 'Can you do 18?');
      expect(q.status, QuoteStatus.revised);
    });

    test('empty breakdown and fractional quantities', () {
      final row = quoteRow(currency: 'INR', subtotal: 833, tax: 0, breakdown: {})
        ..['quote_line_items'] = [
          {'sort': 0, 'description': 'Rice', 'qty': '2.500', 'unit_price_minor': 333, 'line_total_minor': 833},
        ]
        ..remove('seller');
      final q = mapQuote(row, fallbackCurrency: 'INR');
      expect(q.taxBreakdown, isA<NoTaxBreakdown>());
      expect(q.lines.single.qty, 1);
      expect(q.lines.single.lineTotal.minorInt, 833);
      expect(q.lines.single.description, contains('2.500'));
      expect(q.seller.id, 's1');
    });

    test('quote draft -> line items JSON', () {
      final d = QuoteDraft(
        requestId: 'r1',
        lines: [QuoteLine(description: 'Fridge', qty: 2, unitPrice: moneyFromMinor(129900, 'INR'))],
        delivery: moneyFromMinor(0, 'INR'),
        taxRateBp: 1800,
        validDays: 7,
      );
      expect(quoteLineItemsJson(d, gst: true), [
        {'description': 'Fridge', 'qty': 2, 'unit_price_minor': 129900, 'tax_rate_bp': 1800},
      ]);
      expect(quoteLineItemsJson(d, gst: false).single.containsKey('tax_rate_bp'), isFalse);
    });
  });

  group('lead', () {
    final feedRow = {
      'request_id': 'r9',
      'category_id': 4,
      'category_slug': 'refrigerators',
      'title': 'Fridge',
      'description': 'Need a fridge',
      'fields': {'brand': 'LG'},
      'budget_min_minor': null,
      'budget_max_minor': 3000000,
      'currency': 'INR',
      'needed_by': '2026-10-20',
      'locality': null,
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'location_code': '560034',
      'audience': 'both',
      'quote_count': 10,
      'max_quotes': 10,
      'quote_window_ends_at': '2026-10-04T00:00:00Z',
      'created_at': '2026-10-02T05:00:00Z',
      'distance_m': 2500.0,
      'media_count': 2,
      'my_quote_id': 'q7',
      'seen_at': '2026-10-02T05:10:00Z',
    };

    test('feed row', () {
      final l = mapLeadFeedRow(feedRow, fallbackCurrency: 'USD');
      expect(l.requestId, 'r9');
      expect(l.budgetMin, isNull);
      expect(l.budgetMax!.minorInt, 3000000);
      expect(l.budgetMax!.isoCode, 'INR');
      expect(l.locality, 'Bengaluru');
      expect(l.distanceKm, 2.5);
      expect(l.alreadyQuoted, isTrue);
      expect(l.seen, isTrue);
      expect(l.isFull, isTrue);
      expect(l.neededBy, DateTime(2026, 10, 20));
      expect(jsonDecode(leadCursor(feedRow)), {'created_at': '2026-10-02T05:00:00Z', 'id': 'r9'});
    });

    test('detail JSON from get_request_for_seller', () {
      final l = mapLeadDetail(
        {
          'id': 'r9',
          'category_id': 4,
          'title': 'Fridge',
          'currency': 'INR',
          'budget_min_minor': 100,
          'audience': 'online',
          'created_at': '2026-10-02T05:00:00Z',
          'media': [
            {'id': 'm1', 'file_path': 'r9/a.jpg', 'type': 'image'},
          ],
          'my_quote': null,
        },
        fallbackCurrency: 'INR',
        buyerFirstName: 'Priya',
      );
      expect(l.audience, Audience.online);
      expect(l.media.single.path, 'r9/a.jpg');
      expect(l.alreadyQuoted, isFalse);
      expect(l.buyerFirstName, 'Priya');
      expect(l.budgetMin!.minorInt, 100);
    });

    test('filters JSON', () {
      expect(
        leadFiltersJson(
          LeadFilters(
            categoryId: 4,
            maxDistanceKm: 10,
            minBudget: moneyFromMinor(50000, 'INR'),
            neededBefore: DateTime(2026, 11, 1),
          ),
        ),
        {
          'category_ids': [4],
          'max_distance_km': 10,
          'min_budget_minor': 50000,
          'needed_by_before': '2026-11-01',
        },
      );
      expect(leadFiltersJson(const LeadFilters()), isEmpty);
    });
  });

  group('chat', () {
    test('message row', () {
      final m = mapChatMessage({
        'id': 'm1',
        'chat_id': 'c1',
        'sender_id': 'u1',
        'type': 'image',
        'body': null,
        'attachment_path': 'c1/x.jpg',
        'read_at': '2026-10-02T06:00:00Z',
        'created_at': '2026-10-02T05:59:00Z',
      }, attachmentUrl: 'https://signed');
      expect(m.type, MessageType.image);
      expect(m.body, '');
      expect(m.attachmentPath, 'c1/x.jpg');
      expect(m.attachmentUrl, 'https://signed');
      expect(m.readAt, isNotNull);
      expect(m.sendState, SendState.sent);
    });

    test('system and quote card messages without a sender', () {
      final m = mapChatMessage({
        'id': 'm2',
        'chat_id': 'c1',
        'sender_id': null,
        'type': 'quote_card',
        'body': 'quote_revised',
        'created_at': '2026-10-02T05:59:00Z',
      });
      expect(m.type, MessageType.quoteCard);
      expect(m.senderId, '');
    });

    test('chat row', () {
      final c = mapChat(
        {
          'id': 'c1',
          'request_id': 'r1',
          'buyer_id': 'b1',
          'seller_id': 's1',
          'last_message_preview': 'Hello',
          'last_message_at': '2026-10-02T06:00:00Z',
        },
        requestTitle: 'Fridge',
        counterpartName: 'Sharma Electronics',
        unread: 2,
        quoteAccepted: true,
      );
      expect(c.lastMessage, 'Hello');
      expect(c.unread, 2);
      expect(c.quoteAccepted, isTrue);
    });
  });

  group('notification', () {
    test('maps and normalises server routes', () {
      final n = mapNotification({
        'id': 'n1',
        'type': 'message',
        'payload': {'chat_id': 'c1', 'route': '/chat/c1', 'preview': 'Hi'},
        'read_at': null,
        'created_at': '2026-10-02T06:00:00Z',
      });
      expect(n.isRead, isFalse);
      expect(n.route, '/chats/c1');
      expect(n.payload['preview'], 'Hi');
    });

    test('route table', () {
      expect(normalizeServerRoute('/r/abc'), '/r/abc');
      expect(normalizeServerRoute('/q/abc'), '/q/abc');
      expect(normalizeServerRoute('/seller/leads/abc'), '/seller/leads/abc');
      expect(normalizeServerRoute('/seller/quotes/q1'), '/seller/quotes');
      expect(normalizeServerRoute('/orders/o1/review'), '/orders/o1/review');
      expect(normalizeServerRoute('/reviews/x'), isNull);
    });

    test('a dropped route falls back to the ids', () {
      final n = mapNotification({
        'id': 'n2',
        'type': 'new_review',
        'payload': {'route': '/reviews/x', 'order_id': 'o1'},
        'created_at': '2026-10-02T06:00:00Z',
      });
      expect(n.route, '/orders/o1');
    });
  });

  group('other rows', () {
    test('profile', () {
      final p = mapProfile({
        'id': 'u1',
        'name': 'Priya',
        'phone': '+910000000001',
        'roles': ['buyer', 'seller'],
        'active_mode': 'seller',
        'language': 'hi',
        'created_at': '2026-10-01T00:00:00Z',
      });
      expect(p.isSeller, isTrue);
      expect(p.activeMode, AppMode.seller);
      expect(p.phoneVerified, isTrue);
    });

    test('seller from get_my_seller_profile', () {
      final s = mapSeller({
        'id': 's1',
        'business_name': 'Cool Air',
        'area_type': 'codes',
        'center_lat': 12.9,
        'center_lng': 77.6,
        'radius_km': '7.5',
        'service_codes': ['560034'],
        'verification_status': 'unverified',
        'notify_mode': 'daily',
        'quiet_hours_start': '22:00:00',
        'quiet_hours_end': '07:00:00',
        'category_ids': [4, 5],
        'contacts': {'business_phone': '+911234567890'},
        'rating_avg': 4.5,
        'city': 'Bengaluru',
      });
      expect(s.areaType, AreaType.codes);
      expect(s.lat, 12.9);
      expect(s.radiusKm, 8);
      expect(s.verificationStatus, VerificationStatus.none);
      expect(s.notifyPreference, NotifyPreference.quiet);
      expect(s.quietStartHour, 22);
      expect(s.quietEndHour, 7);
      expect(s.categoryIds, [4, 5]);
      expect(s.phone, '+911234567890');
      expect(s.locality, 'Bengaluru');
    });

    test('order with events, reviews and contacts', () {
      final o = mapOrder(
        {
          'id': 'o1',
          'request_id': 'r1',
          'quote_id': 'q1',
          'buyer_id': 'b1',
          'seller_id': 's1',
          'status': 'delivered',
          'total_minor': 123348,
          'currency': 'INR',
          'payment_method': 'upi',
          'payment_amount_minor': 123348,
          'created_at': '2026-10-02T06:00:00Z',
          'order_events': [
            {'status': 'delivered', 'at': '2026-10-03T06:00:00Z'},
            {'status': 'payment_recorded', 'at': '2026-10-02T07:00:00Z', 'note': 'upi:123348'},
            {'status': 'accepted', 'at': '2026-10-02T06:00:00Z'},
          ],
          'reviews': [
            {'role': 'buyer_to_seller'},
          ],
          'seller': {'business_name': 'Sharma Electronics'},
          'request': {'title': 'Fridge'},
        },
        fallbackCurrency: 'INR',
        contacts: {
          'buyer': {'name': 'Priya', 'phone': '+910000000001', 'full_address': '12 MG Road'},
          'seller': {'business_name': 'Sharma Electronics', 'phone': '+911111111111'},
        },
      );
      expect(o.status, OrderStatus.delivered);
      expect(o.total.minorInt, 123348);
      expect(o.paymentAmount!.minorInt, 123348);
      expect(o.events.map((e) => e.status), [OrderStatus.accepted, OrderStatus.delivered]);
      expect(o.buyerReviewed, isTrue);
      expect(o.sellerReviewed, isFalse);
      expect(o.title, 'Fridge');
      expect(o.fullAddress, '12 MG Road');
      expect(o.sellerPhone, '+911111111111');
    });

    test('app settings', () {
      final f = mapFlags({
        'monetization_enabled': true,
        'quote_cap': 8,
        'priority_window_minutes': 20,
        'early_partner_free_until': '2027-04-01T00:00:00Z',
        'max_requests_per_buyer_per_day': 5,
        'legal_versions': {'terms': '2.0', 'privacy': '2.1'},
      });
      expect(f.monetizationEnabled, isTrue);
      expect(f.quoteCap, 8);
      expect(f.priorityWindowMinutes, 20);
      expect(f.maxRequestsPerDay, 5);
      expect(f.earlyPartnerFreeUntil, isNotNull);
      expect(f.termsVersion, '2.0');
      expect(f.privacyVersion, '2.1');
      expect(mapFlags(const {}).quoteCap, 10);
    });

    test('category field schema in both documented shapes', () {
      final schema = [
        {
          'key': 'capacity',
          'type': 'number',
          'label': {'en': 'Capacity'},
          'scope': 'both',
        },
      ];
      expect(parseFieldSchema(schema).single.key, 'capacity');
      expect(parseFieldSchema({'fields': schema}).single.quoteField, isTrue);
      final c = mapCategory({
        'id': 4,
        'parent_id': 1,
        'names': {'en': 'Refrigerators', 'hi': 'फ्रिज'},
        'policy': 'restricted',
        'required_licence_type': 'fssai',
        'field_schema': {'fields': schema},
        'keywords': ['fridge'],
      });
      expect(c.isLeaf, isTrue);
      expect(c.isRestricted, isTrue);
      expect(c.fields.single.label('en'), 'Capacity');
    });

    test('review direction becomes the author side', () {
      final r = mapReview({
        'id': 'v1',
        'order_id': 'o1',
        'from_id': 'b1',
        'to_id': 's1',
        'role': 'buyer_to_seller',
        'stars': 5,
        'tags': ['on_time'],
        'created_at': '2026-10-02T06:00:00Z',
      }, authorName: 'Priya S.');
      expect(r.role, 'buyer');
      expect(r.text, '');
      expect(r.authorName, 'Priya S.');
    });
  });
}
