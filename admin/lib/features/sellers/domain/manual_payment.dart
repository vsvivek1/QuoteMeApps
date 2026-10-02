import 'dart:convert';

/// A seller plan an admin can grant by hand after a payment arrives outside
/// the payment gateway (UPI or bank transfer while the India gateway is not
/// live). Ids match the store / checkout product ids.
enum ManualPlan {
  proMonthly('seller_pro_monthly', tier: 'pro', days: 30),
  proAnnual('seller_pro_annual', tier: 'pro', days: 365),
  credits10('credits_10', tier: 'credits', credits: 10),
  credits50('credits_50', tier: 'credits', credits: 50);

  const ManualPlan(this.id, {required this.tier, this.days, this.credits = 0});

  /// Product id (`seller_pro_monthly`, `credits_10`, ...). Written to the note
  /// because `admin_grant_entitlement` stores `product_id = admin_grant_<tier>`.
  final String id;

  /// `p_tier` for `admin_grant_entitlement`: `pro` or `credits`.
  final String tier;

  /// Pro only: how many calendar days the plan runs from today.
  final int? days;

  /// Credits only: `p_credits`.
  final int credits;

  bool get isPro => tier == 'pro';
}

enum PaymentMethod {
  upi('upi'),
  bankTransfer('bank_transfer'),
  other('other');

  const PaymentMethod(this.wire);
  final String wire;
}

/// Parses an amount typed in major units (rupees, dollars) into integer minor
/// units (paise, cents) without going through a double.
///
/// Accepts `499`, `499.5`, `499.50`, `1,499.00`, `1,00,000` (Indian grouping),
/// an optional leading currency sign (`₹`, `Rs`, `Rs.`, `INR`, `$`) and
/// surrounding spaces. Returns null for empty, zero, negative, more than two
/// decimals, anything else non-numeric, or more than [maxMajorDigits] digits
/// before the decimal point.
int? parseAmountToMinor(String input, {int maxMajorDigits = 9}) {
  var s = input.trim().replaceAll(RegExp(r'\s+'), '');
  s = s.replaceFirst(RegExp(r'^(₹|rs\.?|inr|\$|usd)', caseSensitive: false), '');
  s = s.replaceAll(',', '');
  final m = RegExp(r'^(\d*)(?:\.(\d{0,2}))?$').firstMatch(s);
  if (m == null) return null;
  final major = m.group(1)!;
  final minor = m.group(2) ?? '';
  if (major.isEmpty && minor.isEmpty) return null;
  final majorDigits = major.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (majorDigits.length > maxMajorDigits) return null;
  final value = int.parse(majorDigits.isEmpty ? '0' : majorDigits) * 100 + int.parse(minor.padRight(2, '0'));
  return value > 0 ? value : null;
}

/// Formats minor units as `1,499.00` style text (no currency sign), for
/// confirmations. Integer arithmetic only.
String formatMinor(int minor) {
  final major = (minor ~/ 100).toString();
  final cents = (minor % 100).toString().padLeft(2, '0');
  final grouped = major.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '$grouped.$cents';
}

/// Normalizes a payment reference (UTR / transaction id): whitespace removed,
/// upper case. Returns null when it is not 4 to 64 of `A-Z 0-9 . _ / -`.
String? normalizeReference(String input) {
  final s = input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  return RegExp(r'^[A-Z0-9._/-]{4,64}$').hasMatch(s) ? s : null;
}

/// When a manually granted plan ends: Pro runs through the end of the day
/// `today + days` (local time; stored as UTC); credits never expire (null).
DateTime? manualPlanExpiry(ManualPlan plan, DateTime now) {
  final days = plan.days;
  if (days == null) return null;
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + days + 1).toUtc();
}

/// A manual payment an admin has checked and wants to turn into a grant.
class ManualPaymentGrant {
  const ManualPaymentGrant({
    required this.sellerId,
    required this.plan,
    required this.method,
    required this.amountMinor,
    required this.currency,
    required this.reference,
    this.payerName,
    required this.now,
  });

  final String sellerId;
  final ManualPlan plan;
  final PaymentMethod method;
  final int amountMinor;
  final String currency;

  /// Already normalized ([normalizeReference]).
  final String reference;
  final String? payerName;
  final DateTime now;

  String get tier => plan.tier;
  int get credits => plan.credits;
  DateTime? get expiresAt => manualPlanExpiry(plan, now);

  /// `p_note`: compact JSON, so the audit log and the entitlement's `raw.note`
  /// carry the payment details and can be searched by reference.
  String get note => buildManualPaymentNote(
        plan: plan,
        method: method,
        amountMinor: amountMinor,
        currency: currency,
        reference: reference,
        payerName: payerName,
      );
}

const manualPaymentNoteKind = 'manual_payment';

String buildManualPaymentNote({
  required ManualPlan plan,
  required PaymentMethod method,
  required int amountMinor,
  required String currency,
  required String reference,
  String? payerName,
}) {
  final payer = payerName?.trim().replaceAll(RegExp(r'\s+'), ' ');
  return jsonEncode({
    'kind': manualPaymentNoteKind,
    'plan': plan.id,
    'method': method.wire,
    'amount_minor': amountMinor,
    'currency': currency,
    'ref': reference,
    if (payer != null && payer.isNotEmpty) 'payer': payer,
    'bank_checked': true,
  });
}

/// Reads a note written by [buildManualPaymentNote]; null for any other note.
Map<String, dynamic>? parseManualPaymentNote(String? note) {
  if (note == null || !note.startsWith('{')) return null;
  try {
    final v = jsonDecode(note);
    return v is Map<String, dynamic> && v['kind'] == manualPaymentNoteKind ? v : null;
  } on FormatException {
    return null;
  }
}
