import 'dart:convert';
import 'dart:typed_data';

import '../../../features/auth/domain/app_user.dart';
import '../../../features/chat/domain/chat.dart';
import '../../../features/notifications/domain/app_notification.dart';
import '../../../features/orders/domain/order.dart';
import '../../../features/quotes/domain/quote.dart';
import '../../../features/requests/domain/buyer_request.dart';
import '../../../features/requests/domain/category.dart';
import '../../../features/reviews/domain/review.dart';
import '../../../features/seller/domain/lead.dart';
import '../../../features/seller/domain/seller.dart';
import '../../../features/settings/domain/app_settings.dart';
import '../../money/money.dart';
import '../../money/tax.dart';

/// Server row (PostgREST / RPC JSON) -> domain model.
///
/// Money is converted here and only here: integer minor units plus the row's
/// ISO currency become [Money] through [moneyFromMinor]. Never doubles.
/// Timestamps (`timestamptz`, ISO 8601 UTC) become local [DateTime]s; `date`
/// columns become local midnight of that calendar day.

typedef JsonRow = Map<String, dynamic>;

// ------------------------------------------------------------------ scalars

DateTime? parseTimestamp(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  final s = v.toString();
  if (s.isEmpty) return null;
  final d = DateTime.tryParse(s);
  return d?.toLocal();
}

/// `date` columns ('2026-10-02') -> local midnight of that day.
DateTime? parseDate(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.length < 10) return null;
  final d = DateTime.tryParse(s.substring(0, 10));
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

/// Local calendar day -> `date` column value.
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int? asInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? asDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool asBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;

String? asString(Object? v) => v?.toString();

List<String> asStringList(Object? v) => v is List ? [for (final e in v) e.toString()] : const [];

List<int> asIntList(Object? v) => v is List ? [for (final e in v) ?asInt(e)] : const [];

Map<String, Object?> asMap(Object? v) => v is Map ? v.map((k, val) => MapEntry(k.toString(), val as Object?)) : {};

/// Integer minor units + ISO currency -> [Money]; null stays null.
Money? moneyOrNull(Object? minor, String currency) {
  final m = asInt(minor);
  return m == null ? null : moneyFromMinor(m, currency);
}

Money moneyOrZero(Object? minor, String currency) => moneyFromMinor(asInt(minor) ?? 0, currency);

String currencyOf(JsonRow row, String fallback) {
  final c = row['currency']?.toString().trim();
  return (c == null || c.isEmpty) ? fallback : c;
}

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  final s = name?.toString();
  for (final v in values) {
    if (v.name == s) return v;
  }
  return fallback;
}

/// A geography point as PostgREST returns it: GeoJSON (`{type: Point,
/// coordinates: [lng, lat]}`), or hex (E)WKB such as
/// `0101000020E6100000...`. Returns (lat, lng) or null.
({double lat, double lng})? parsePoint(Object? v) {
  if (v == null) return null;
  if (v is Map) {
    final c = v['coordinates'];
    if (c is List && c.length >= 2) {
      return (lat: (c[1] as num).toDouble(), lng: (c[0] as num).toDouble());
    }
    return null;
  }
  final s = v.toString();
  if (s.startsWith('{')) {
    try {
      return parsePoint(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }
  if (s.length < 42 || s.length.isOdd || !RegExp(r'^[0-9A-Fa-f]+$').hasMatch(s)) return null;
  final bytes = Uint8List(s.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  final data = ByteData.sublistView(bytes);
  final endian = bytes[0] == 1 ? Endian.little : Endian.big;
  final type = data.getUint32(1, endian);
  var offset = 5;
  if (type & 0x20000000 != 0) offset += 4; // SRID present (EWKB)
  if ((type & 0xFFFF) != 1 || bytes.length < offset + 16) return null; // not a 2D point
  final x = data.getFloat64(offset, endian);
  final y = data.getFloat64(offset + 8, endian);
  return (lat: y, lng: x);
}

/// `time` column ('22:00:00') -> hour.
int? parseHour(Object? v) {
  final s = v?.toString();
  if (s == null || s.isEmpty) return null;
  return int.tryParse(s.split(':').first);
}

String? formatHour(int? hour) => hour == null ? null : '${hour.toString().padLeft(2, '0')}:00';

// ---------------------------------------------------------------- JWT claims

/// Custom claims added by `custom_access_token_hook` (API.md section 1).
class JwtClaims {
  const JwtClaims({
    this.roles = const ['buyer'],
    this.activeMode = 'buyer',
    this.accountStatus = 'active',
    this.sellerVerified = false,
  });

  final List<String> roles;
  final String activeMode;
  final String accountStatus;
  final bool sellerVerified;

  bool get isActive => accountStatus == 'active';
}

/// Decodes the payload of a JWT without verifying it (the server verifies
/// every request; the app only reads claims for display and routing).
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return const {};
  try {
    final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final m = jsonDecode(decoded);
    return m is Map<String, dynamic> ? m : const {};
  } catch (_) {
    return const {};
  }
}

JwtClaims claimsFromJwt(String token) {
  final p = decodeJwtPayload(token);
  return JwtClaims(
    roles: p['roles'] is List ? asStringList(p['roles']) : const ['buyer'],
    activeMode: p['active_mode']?.toString() ?? 'buyer',
    accountStatus: p['account_status']?.toString() ?? 'active',
    sellerVerified: p['seller_verified'] == true,
  );
}

// ------------------------------------------------------------------ profile

Profile mapProfile(JsonRow row) {
  final roles = <UserRole>[
    for (final r in asStringList(row['roles']))
      if (UserRole.values.any((v) => v.name == r)) UserRole.values.byName(r),
  ];
  final phone = asString(row['phone']);
  return Profile(
    id: row['id'].toString(),
    name: asString(row['name']),
    phone: phone,
    email: asString(row['email']),
    photoUrl: asString(row['photo_url']),
    language: asString(row['language']),
    roles: roles.isEmpty && row['roles'] == null ? const [UserRole.buyer] : roles,
    activeMode: enumByName(AppMode.values, row['active_mode'], AppMode.buyer),
    // profiles.phone is only ever written from auth.users (verified by OTP).
    phoneVerified: phone != null && phone.isNotEmpty,
    createdAt: parseTimestamp(row['created_at']),
    accountStatus: asString(row['status']) ?? 'active',
    suspendedUntil: parseTimestamp(row['suspended_until']),
  );
}

// ---------------------------------------------------------------- settings

AppFlags mapFlags(Map<String, dynamic> s) {
  final legal = asMap(s['legal_versions']);
  const d = AppFlags();
  return AppFlags(
    monetizationEnabled: asBool(s['monetization_enabled'], d.monetizationEnabled),
    quoteCap: asInt(s['quote_cap']) ?? d.quoteCap,
    priorityWindowMinutes: asInt(s['priority_window_minutes']) ?? d.priorityWindowMinutes,
    earlyPartnerFreeUntil: parseTimestamp(s['early_partner_free_until']),
    maxRequestsPerDay: asInt(s['max_requests_per_buyer_per_day']) ?? d.maxRequestsPerDay,
    webPurchaseLinksAllowed: asBool(s['web_purchase_links_allowed'], d.webPurchaseLinksAllowed),
    paywallDefaultPeriod: switch (s['paywall_default_period']) {
      final String p when p == 'monthly' || p == 'annual' => p,
      _ => d.paywallDefaultPeriod,
    },
    whatsappNotifications: asBool(s['whatsapp_notifications'], d.whatsappNotifications),
    termsVersion: asString(legal['terms']) ?? d.termsVersion,
    privacyVersion: asString(legal['privacy']) ?? d.privacyVersion,
  );
}

// --------------------------------------------------------------- categories

List<FieldDef> parseFieldSchema(Object? schema) {
  // API.md documents a bare array; the SQL validator reads {"fields": [...]}.
  final list = schema is Map ? schema['fields'] : schema;
  if (list is! List) return const [];
  return [
    for (final f in list)
      if (f is Map && f['key'] != null) _fieldDef(Map<String, dynamic>.from(f)),
  ];
}

FieldDef _fieldDef(Map<String, dynamic> j) {
  final base = FieldDef.fromJson(j);
  final scope = j['scope']?.toString();
  return scope == null ? base : base.copyWith(quoteField: base.quoteField ?? (scope == 'quote' || scope == 'both'));
}

Category mapCategory(JsonRow row) => Category(
  id: asInt(row['id'])!,
  parentId: asInt(row['parent_id']),
  names: parseLocalizedMap(row['names']),
  policy: enumByName(CategoryPolicy.values, row['policy'], CategoryPolicy.allowed),
  requiredLicenceType: asString(row['required_licence_type']),
  disclaimer: parseLocalizedMap(row['disclaimer']),
  fields: parseFieldSchema(row['field_schema']),
  keywords: asStringList(row['keywords']),
  icon: asString(row['icon']),
  sort: asInt(row['sort']) ?? 0,
);

// ----------------------------------------------------------------- requests

RequestMedia mapRequestMedia(JsonRow row) =>
    RequestMedia(path: row['file_path'].toString(), type: asString(row['type']) ?? 'image');

/// A `requests` row as the buyer reads it, optionally with embedded
/// `request_media(*)`.
BuyerRequest mapRequest(JsonRow row, {required String fallbackCurrency, int notifiedSellers = 0}) {
  final cur = currencyOf(row, fallbackCurrency);
  final point = parsePoint(row['location']);
  final media = row['request_media'] is List
      ? ([
          for (final m in row['request_media'] as List)
            if (m is Map && m['hidden'] != true) Map<String, dynamic>.from(m),
        ]..sort((a, b) => (asInt(a['sort']) ?? 0).compareTo(asInt(b['sort']) ?? 0)))
      : const <Map<String, dynamic>>[];
  return BuyerRequest(
    id: row['id'].toString(),
    buyerId: row['buyer_id'].toString(),
    categoryId: asInt(row['category_id'])!,
    title: asString(row['title']) ?? '',
    description: asString(row['description']) ?? '',
    fields: asMap(row['fields']),
    budgetMin: moneyOrNull(row['budget_min_minor'], cur),
    budgetMax: moneyOrNull(row['budget_max_minor'], cur),
    budgetVisible: asBool(row['budget_visible'], true),
    neededBy: parseDate(row['needed_by']),
    lat: point?.lat,
    lng: point?.lng,
    locationCode: asString(row['location_code']),
    locality: asString(row['locality']) ?? asString(row['city']),
    state: asString(row['state']),
    audience: enumByName(Audience.values, row['audience'], Audience.both),
    status: enumByName(RequestStatus.values, row['status'], RequestStatus.open),
    quoteCount: asInt(row['quote_count']) ?? 0,
    maxQuotes: asInt(row['max_quotes']) ?? 10,
    quoteWindowEndsAt: parseTimestamp(row['quote_window_ends_at']),
    priorityUntil: parseTimestamp(row['priority_until']),
    acceptedQuoteId: asString(row['accepted_quote_id']),
    referenceLink: asString(row['reference_url']),
    media: [for (final m in media) mapRequestMedia(m)],
    createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
    notifiedSellers: notifiedSellers,
  );
}

// ------------------------------------------------------------------- quotes

/// `quote_line_items` row -> [QuoteLine]. The app's line has an integer
/// quantity; a fractional server quantity (numeric(12,3), e.g. 2.5 kg) is
/// shown as one line of its rounded line total so totals stay exact.
QuoteLine mapQuoteLine(JsonRow row, String currency) {
  final qty = num.tryParse(row['qty']?.toString() ?? '1') ?? 1;
  final desc = asString(row['description']) ?? '';
  if (qty == qty.truncate() && qty > 0) {
    return QuoteLine(description: desc, qty: qty.toInt(), unitPrice: moneyOrZero(row['unit_price_minor'], currency));
  }
  return QuoteLine(
    description: '$desc (× ${row['qty']})',
    qty: 1,
    unitPrice: moneyOrZero(row['line_total_minor'], currency),
  );
}

SellerSummary mapSellerSummary(JsonRow? row, String sellerId) {
  if (row == null) return SellerSummary(id: sellerId, businessName: '');
  return SellerSummary(
    id: asString(row['id']) ?? sellerId,
    businessName: asString(row['business_name']) ?? '',
    logoUrl: asString(row['logo_url']),
    ratingAvg: asDouble(row['rating_avg']) ?? 0,
    ratingCount: asInt(row['rating_count']) ?? 0,
    verified: row['verification_status'] == 'verified',
    avgResponseMins: asInt(row['avg_response_mins']),
    distanceKm: row['distance_m'] == null ? null : asDouble(row['distance_m'])! / 1000,
    earlyPartner: asBool(row['early_partner']),
  );
}

TaxBreakdown mapTaxBreakdown(Object? json, String currency) {
  if (json is! Map || json['kind'] == null) return const NoTaxBreakdown();
  try {
    return TaxBreakdown.fromJson(Map<String, dynamic>.from(json), currency);
  } catch (_) {
    return const NoTaxBreakdown();
  }
}

/// A `quotes` row with optional embeds: `quote_line_items(*)` (or the
/// `line_items` key `get_my_quotes` uses) and `seller:sellers(...)`.
Quote mapQuote(JsonRow row, {required String fallbackCurrency, SellerSummary? seller}) {
  final cur = currencyOf(row, fallbackCurrency);
  final rawLines = (row['quote_line_items'] ?? row['line_items']) as List? ?? const [];
  final lines = [for (final l in rawLines) Map<String, dynamic>.from(l as Map)]
    ..sort((a, b) => (asInt(a['sort']) ?? 0).compareTo(asInt(b['sort']) ?? 0));
  final sellerId = row['seller_id'].toString();
  final sellerRow = row['seller'] ?? row['sellers'];
  return Quote(
    id: row['id'].toString(),
    requestId: row['request_id'].toString(),
    seller: seller ?? mapSellerSummary(sellerRow is Map ? Map<String, dynamic>.from(sellerRow) : null, sellerId),
    lines: [for (final l in lines) mapQuoteLine(l, cur)],
    subtotal: moneyOrZero(row['subtotal_minor'], cur),
    tax: moneyOrZero(row['tax_minor'], cur),
    taxBreakdown: mapTaxBreakdown(row['tax_breakdown'], cur),
    delivery: moneyOrZero(row['delivery_minor'], cur),
    total: moneyOrZero(row['total_minor'], cur),
    offeredBrandModel: asString(row['offered_brand_model']),
    deliveryDate: parseDate(row['delivery_date']),
    warranty: asString(row['warranty']),
    validUntil: parseDate(row['valid_until']),
    notes: asString(row['notes']),
    status: enumByName(QuoteStatus.values, row['status'], QuoteStatus.sent),
    counterOfferTarget: moneyOrNull(row['counter_target_minor'], cur),
    counterOfferNote: asString(row['counter_note']),
    declineReason: asString(row['decline_reason']),
    createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
    updatedAt: parseTimestamp(row['updated_at']),
  );
}

/// [QuoteDraft] -> `p_line_items` for `submit_quote` / `revise_quote`.
/// India sends the GST rate per line; the US rate goes in
/// `p_sales_tax_rate_ppm` instead.
List<Map<String, Object?>> quoteLineItemsJson(QuoteDraft d, {required bool gst}) => [
  for (final l in d.lines)
    {
      'description': l.description,
      'qty': l.qty,
      'unit_price_minor': l.unitPrice.minorInt,
      if (gst) 'tax_rate_bp': d.taxRateBp,
    },
];

// -------------------------------------------------------------------- leads

/// One row of `get_lead_feed`.
Lead mapLeadFeedRow(JsonRow row, {required String fallbackCurrency}) {
  final cur = currencyOf(row, fallbackCurrency);
  final distance = asDouble(row['distance_m']);
  return Lead(
    requestId: row['request_id'].toString(),
    categoryId: asInt(row['category_id'])!,
    title: asString(row['title']) ?? '',
    description: asString(row['description']) ?? '',
    fields: asMap(row['fields']),
    budgetMin: moneyOrNull(row['budget_min_minor'], cur),
    budgetMax: moneyOrNull(row['budget_max_minor'], cur),
    neededBy: parseDate(row['needed_by']),
    locality: asString(row['locality']) ?? asString(row['city']),
    locationCode: asString(row['location_code']),
    state: asString(row['state']),
    distanceKm: distance == null ? null : distance / 1000,
    audience: enumByName(Audience.values, row['audience'], Audience.both),
    quoteCount: asInt(row['quote_count']) ?? 0,
    maxQuotes: asInt(row['max_quotes']) ?? 10,
    quoteWindowEndsAt: parseTimestamp(row['quote_window_ends_at']),
    createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
    seen: row['seen_at'] != null,
    alreadyQuoted: row['my_quote_id'] != null,
  );
}

/// `get_request_for_seller` JSON (safe request + media[] + my_quote).
Lead mapLeadDetail(JsonRow row, {required String fallbackCurrency, String? buyerFirstName}) {
  final cur = currencyOf(row, fallbackCurrency);
  final distance = asDouble(row['distance_m']);
  return Lead(
    requestId: row['id'].toString(),
    categoryId: asInt(row['category_id'])!,
    title: asString(row['title']) ?? '',
    description: asString(row['description']) ?? '',
    fields: asMap(row['fields']),
    budgetMin: moneyOrNull(row['budget_min_minor'], cur),
    budgetMax: moneyOrNull(row['budget_max_minor'], cur),
    neededBy: parseDate(row['needed_by']),
    locality: asString(row['locality']) ?? asString(row['city']),
    locationCode: asString(row['location_code']),
    state: asString(row['state']),
    distanceKm: distance == null ? null : distance / 1000,
    audience: enumByName(Audience.values, row['audience'], Audience.both),
    quoteCount: asInt(row['quote_count']) ?? 0,
    maxQuotes: asInt(row['max_quotes']) ?? 10,
    quoteWindowEndsAt: parseTimestamp(row['quote_window_ends_at']),
    createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
    media: [
      for (final m in (row['media'] as List? ?? const []))
        if (m is Map) mapRequestMedia(Map<String, dynamic>.from(m)),
    ],
    seen: true, // get_request_for_seller marks the lead seen
    alreadyQuoted: row['my_quote'] != null,
    buyerFirstName: buyerFirstName,
  );
}

/// [LeadFilters] -> `p_filters` for `get_lead_feed`.
Map<String, Object?> leadFiltersJson(LeadFilters f) => {
  if (f.categoryId != null) 'category_ids': [f.categoryId],
  if (f.maxDistanceKm != null) 'max_distance_km': f.maxDistanceKm,
  if (f.minBudget != null) 'min_budget_minor': f.minBudget!.minorInt,
  if (f.neededBefore != null) 'needed_by_before': formatDate(f.neededBefore!),
};

/// Keyset cursor (`{created_at, id}` of the last row) as an opaque string.
String leadCursor(JsonRow lastRow) =>
    jsonEncode({'created_at': lastRow['created_at'], 'id': lastRow['request_id'] ?? lastRow['id']});

// ------------------------------------------------------------------ sellers

VerificationStatus mapVerificationStatus(Object? s) => switch (s) {
  'verified' || 'approved' => VerificationStatus.verified,
  'pending' => VerificationStatus.pending,
  'rejected' || 'expired' => VerificationStatus.rejected,
  _ => VerificationStatus.none,
};

NotifyPreference mapNotifyMode(Object? s) => switch (s) {
  'hourly' => NotifyPreference.hourly,
  'daily' => NotifyPreference.quiet,
  _ => NotifyPreference.instant,
};

String notifyModeJson(NotifyPreference p) => switch (p) {
  NotifyPreference.instant => 'instant',
  NotifyPreference.hourly => 'hourly',
  NotifyPreference.quiet => 'daily',
};

/// A `sellers` row (with optional `seller_categories(category_id)` embed and
/// geography `center`) or the `get_my_seller_profile()` JSON (with
/// `center_lat`, `center_lng`, `category_ids`, `contacts`).
Seller mapSeller(JsonRow row) {
  final point = row['center_lat'] != null
      ? (lat: asDouble(row['center_lat'])!, lng: asDouble(row['center_lng'])!)
      : parsePoint(row['center']);
  final cats = row['category_ids'] is List
      ? asIntList(row['category_ids'])
      : [
          for (final c in (row['seller_categories'] as List? ?? const []))
            if (c is Map) ?asInt(c['category_id']),
        ];
  final contacts = row['contacts'] is Map ? asMap(row['contacts']) : const <String, Object?>{};
  return Seller(
    id: row['id'].toString(),
    businessName: asString(row['business_name']) ?? '',
    logoUrl: asString(row['logo_url']),
    photos: asStringList(row['photos']),
    description: asString(row['description']) ?? '',
    yearsInBusiness: asInt(row['years_in_business']),
    brands: asStringList(row['brands']),
    categoryIds: cats,
    areaType: enumByName(AreaType.values, row['area_type'], AreaType.radius),
    lat: point?.lat,
    lng: point?.lng,
    radiusKm: (asDouble(row['radius_km']) ?? 10).round(),
    serviceCodes: asStringList(row['service_codes']),
    state: asString(row['state']),
    locality: asString(row['city']),
    verificationStatus: mapVerificationStatus(row['verification_status']),
    verifiedAt: parseTimestamp(row['verified_at']),
    ratingAvg: asDouble(row['rating_avg']) ?? 0,
    ratingCount: asInt(row['rating_count']) ?? 0,
    quotesSent: asInt(row['quotes_sent']) ?? 0,
    quotesWon: asInt(row['quotes_won']) ?? 0,
    avgResponseMins: asInt(row['avg_response_mins']),
    notifyPreference: mapNotifyMode(row['notify_mode']),
    quietStartHour: parseHour(row['quiet_hours_start']),
    quietEndHour: parseHour(row['quiet_hours_end']),
    earlyPartner: asBool(row['early_partner']),
    freeUntil: parseTimestamp(row['free_until']),
    phone: asString(contacts['business_phone']),
    directoryOptIn: asBool(row['seo_directory_opt_in']),
  );
}

SellerDocument mapSellerDocument(JsonRow row) => SellerDocument(
  id: row['id'].toString(),
  docType: row['doc_type'].toString(),
  docNumber: asString(row['doc_number']),
  filePath: asString(row['file_path']),
  status: mapVerificationStatus(row['status']),
  rejectionReason: asString(row['rejection_reason']),
);

SellerLicence mapSellerLicence(JsonRow row) => SellerLicence(
  id: row['id'].toString(),
  licenceType: asString(row['licence_type']) ?? '',
  number: asString(row['number']) ?? '',
  issuer: asString(row['issuer']),
  state: asString(row['state']),
  categoryIds: asIntList(row['category_ids']),
  expiresAt: parseTimestamp(row['expires_at']),
  status: mapVerificationStatus(row['status']),
);

QuoteTemplate mapQuoteTemplate(JsonRow row) =>
    QuoteTemplate(id: row['id'].toString(), name: asString(row['name']) ?? '', payload: asMap(row['payload']));

// -------------------------------------------------------------------- chats

MessageType mapMessageType(Object? t) => switch (t) {
  'image' => MessageType.image,
  'quote_card' => MessageType.quoteCard,
  'system' => MessageType.system,
  _ => MessageType.text,
};

ChatMessage mapChatMessage(JsonRow row, {String? attachmentUrl}) => ChatMessage(
  id: row['id'].toString(),
  chatId: row['chat_id'].toString(),
  senderId: asString(row['sender_id']) ?? '',
  type: mapMessageType(row['type']),
  body: asString(row['body']) ?? '',
  attachmentPath: asString(row['attachment_path']),
  attachmentUrl: attachmentUrl,
  createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
  readAt: parseTimestamp(row['read_at']),
  clientId: asString(row['client_id']),
);

/// A `chats` row decorated for the signed-in user. [counterpartName] is the
/// seller's business name for the buyer, the buyer's public display name for
/// the seller. The title defaults to the row's `request_title` (kept in sync
/// by the server; sellers can't read `requests`).
Chat mapChat(
  JsonRow row, {
  String? requestTitle,
  required String counterpartName,
  String? counterpartPhotoUrl,
  int unread = 0,
  bool quoteAccepted = false,
}) => Chat(
  id: row['id'].toString(),
  requestId: row['request_id'].toString(),
  buyerId: row['buyer_id'].toString(),
  sellerId: row['seller_id'].toString(),
  requestTitle: requestTitle ?? asString(row['request_title']) ?? asString(asMap(row['request'])['title']) ?? '',
  counterpartName: counterpartName,
  counterpartPhotoUrl: counterpartPhotoUrl,
  lastMessage: asString(row['last_message_preview']),
  lastMessageAt: parseTimestamp(row['last_message_at']),
  unread: unread,
  quoteAccepted: quoteAccepted,
);

// ------------------------------------------------------------ notifications

/// Server routes (API.md section 7) -> routes this app registers.
String? normalizeServerRoute(String? route) {
  if (route == null || !route.startsWith('/')) return route;
  final seg = route.split('/');
  if (seg.length >= 3 && seg[1] == 'chat') return '/chats/${seg[2]}';
  if (seg.length >= 4 && seg[1] == 'seller' && seg[2] == 'quotes') return '/seller/quotes';
  if (seg.length >= 3 && seg[1] == 'seller' && seg[2] == 'profile') return '/seller/account';
  if (seg.length >= 3 && seg[1] == 'reviews') return null; // no review detail screen yet
  return route;
}

AppNotification mapNotification(JsonRow row) {
  final payload = asMap(row['payload']);
  if (payload.containsKey('route')) {
    final r = normalizeServerRoute(payload['route']?.toString());
    if (r == null) {
      payload.remove('route');
    } else {
      payload['route'] = r;
    }
  }
  return AppNotification(
    id: row['id'].toString(),
    type: asString(row['type']) ?? '',
    payload: payload,
    createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
    readAt: parseTimestamp(row['read_at']),
  );
}

// ------------------------------------------------------------------- orders

/// An `orders` row with optional `order_events(*)`, `reviews(role)` and
/// `seller:sellers(business_name)` embeds. The title is the row's
/// `request_title` (a legacy `request:requests(title)` embed still works).
/// [contacts] is the `get_order_contacts` JSON (parties only).
Order mapOrder(JsonRow row, {required String fallbackCurrency, String? title, Map<String, Object?>? contacts}) {
  final cur = currencyOf(row, fallbackCurrency);
  final events = <OrderEvent>[
    for (final e in (row['order_events'] as List? ?? const []))
      if (e is Map && OrderStatus.values.any((s) => s.name == e['status']))
        OrderEvent(
          status: OrderStatus.values.byName(e['status'] as String),
          at: parseTimestamp(e['at'] ?? e['created_at']) ?? DateTime.now(),
          note: asString(e['note']),
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  final roles = {
    for (final r in (row['reviews'] as List? ?? const []))
      if (r is Map) r['role'],
  };
  final seller = asMap(row['seller'] ?? row['sellers']);
  final request = asMap(row['request'] ?? row['requests']);
  final buyerC = asMap(contacts?['buyer']);
  final sellerC = asMap(contacts?['seller']);
  return Order(
    id: row['id'].toString(),
    requestId: row['request_id'].toString(),
    quoteId: row['quote_id'].toString(),
    buyerId: row['buyer_id'].toString(),
    sellerId: row['seller_id'].toString(),
    title: title ?? asString(row['request_title']) ?? asString(request['title']) ?? '',
    sellerName: asString(sellerC['business_name']) ?? asString(seller['business_name']) ?? '',
    buyerName: asString(buyerC['name']),
    sellerPhone: asString(sellerC['phone']),
    buyerPhone: asString(buyerC['phone']),
    fullAddress: asString(buyerC['full_address']),
    total: moneyOrZero(row['total_minor'], cur),
    status: enumByName(OrderStatus.values, row['status'], OrderStatus.accepted),
    paymentMethod: asString(row['payment_method']),
    paymentAmount: moneyOrNull(row['payment_amount_minor'], cur),
    paymentRecordedAt: parseTimestamp(row['payment_recorded_at']),
    events: events,
    createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
    buyerReviewed: roles.contains('buyer_to_seller'),
    sellerReviewed: roles.contains('seller_to_buyer'),
  );
}

// ------------------------------------------------------------------ reviews

Review mapReview(JsonRow row, {String? authorName}) => Review(
  id: row['id'].toString(),
  orderId: row['order_id'].toString(),
  fromId: asString(row['from_id']) ?? '',
  toId: row['to_id'].toString(),
  // The app names the author's side; the server names the direction.
  role: row['role'] == 'seller_to_buyer' ? 'seller' : 'buyer',
  stars: asInt(row['stars']) ?? 0,
  tags: asStringList(row['tags']),
  text: asString(row['text']) ?? '',
  photos: asStringList(row['photos']),
  sellerReply: asString(row['seller_reply']),
  authorName: authorName,
  createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
);
