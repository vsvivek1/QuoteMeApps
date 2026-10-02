import 'money.dart';

/// Tax rounding lives here and only here. The same rules are implemented in
/// SQL (`supabase/migrations`) and the Edge Function shared helper, tested
/// against the same cases.
///
/// India GST rates are integers in basis points (18% = 1800). US sales tax
/// rates are integers in parts per million (8.875% = 88750), because basis
/// points cannot express rates such as New York City's. Rounding is half-up.
BigInt roundHalfUp(BigInt numerator, BigInt denominator) {
  assert(!numerator.isNegative && denominator > BigInt.zero);
  return (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);
}

final _tenK = BigInt.from(10000);
final _twentyK = BigInt.from(20000);
final _million = BigInt.from(ppmPerUnit);

/// Parts per million in 100%.
const ppmPerUnit = 1000000;

/// Basis points (older app versions, legacy `rate_bp` rows) -> ppm. Exact.
int bpToPpm(int bp) => bp * 100;

/// ppm -> basis points rounded half up. Only for the legacy `rate_bp` field
/// the server still writes for older app versions (88750 -> 888).
int ppmToLegacyBp(int ppm) => roundHalfUp(BigInt.from(ppm), BigInt.from(100)).toInt();

class QuoteLine {
  const QuoteLine({required this.description, required this.qty, required this.unitPrice});

  final String description;
  final int qty;
  final Money unitPrice;

  Money get lineTotal => unitPrice * qty;
}

/// How a quote is taxed. Built by the country's [TaxRule].
sealed class TaxBreakdown {
  const TaxBreakdown();

  Map<String, Object?> toJson();

  static TaxBreakdown fromJson(Map<String, dynamic> json, String isoCode) {
    switch (json['kind']) {
      case 'gst':
        return GstBreakdown(
          intraState: json['mode'] == 'intra',
          rateBp: (json['rate_bp'] as num).toInt(),
          cgst: moneyFromMinor((json['cgst'] as num? ?? 0).toInt(), isoCode),
          sgst: moneyFromMinor((json['sgst'] as num? ?? 0).toInt(), isoCode),
          igst: moneyFromMinor((json['igst'] as num? ?? 0).toInt(), isoCode),
        );
      case 'sales_tax':
        // rate_ppm since migration 1050; older rows only have rate_bp.
        final ppm = json['rate_ppm'] as num?;
        return SalesTaxBreakdown(
          ratePpm: ppm != null ? ppm.toInt() : bpToPpm((json['rate_bp'] as num).toInt()),
          amount: moneyFromMinor((json['amount'] as num).toInt(), isoCode),
        );
    }
    return const NoTaxBreakdown();
  }
}

class NoTaxBreakdown extends TaxBreakdown {
  const NoTaxBreakdown();
  @override
  Map<String, Object?> toJson() => {'kind': 'none'};
}

class GstBreakdown extends TaxBreakdown {
  const GstBreakdown({
    required this.intraState,
    required this.rateBp,
    required this.cgst,
    required this.sgst,
    required this.igst,
  });

  final bool intraState;
  final int rateBp;
  final Money cgst;
  final Money sgst;
  final Money igst;

  Money get total => cgst + sgst + igst;

  @override
  Map<String, Object?> toJson() => {
    'kind': 'gst',
    'mode': intraState ? 'intra' : 'inter',
    'rate_bp': rateBp,
    'cgst': cgst.minorInt,
    'sgst': sgst.minorInt,
    'igst': igst.minorInt,
  };
}

class SalesTaxBreakdown extends TaxBreakdown {
  const SalesTaxBreakdown({required this.ratePpm, required this.amount});

  /// Parts per million (8.875% = 88750).
  final int ratePpm;
  final Money amount;

  /// Same shape as the server: `rate_bp` is only for older app versions.
  @override
  Map<String, Object?> toJson() => {
    'kind': 'sales_tax',
    'rate_ppm': ratePpm,
    'rate_bp': ppmToLegacyBp(ratePpm),
    'amount': amount.minorInt,
  };
}

class QuoteTotals {
  const QuoteTotals({
    required this.subtotal,
    required this.tax,
    required this.delivery,
    required this.total,
    required this.breakdown,
  });

  final Money subtotal;
  final Money tax;
  final Money delivery;
  final Money total;
  final TaxBreakdown breakdown;
}

/// Country-specific tax computation, injected through CountryConfig.
abstract class TaxRule {
  const TaxRule();

  /// Selectable GST rates in basis points, shown in the quote form (empty
  /// when the seller types the rate, as for US sales tax).
  List<int> get rateOptionsBp;
  int get defaultRateBp;

  /// [rateBp] is the GST rate (India); [ratePpm] the sales tax rate in parts
  /// per million (USA). Each rule reads its own.
  QuoteTotals compute({
    required List<QuoteLine> lines,
    required Money delivery,
    int rateBp = 0,
    int ratePpm = 0,
    String? sellerState,
    String? buyerState,
  });
}

/// India GST: computed per line, rounded to the paisa, split into CGST+SGST
/// (same state) or IGST (inter-state).
class GstTaxRule extends TaxRule {
  const GstTaxRule({this.rateOptionsBp = const [0, 500, 1800, 4000], this.defaultRateBp = 1800});

  @override
  final List<int> rateOptionsBp;
  @override
  final int defaultRateBp;

  static bool isIntraState(String? sellerState, String? buyerState) {
    if (sellerState == null || buyerState == null) return true;
    return sellerState.trim().toLowerCase() == buyerState.trim().toLowerCase();
  }

  @override
  QuoteTotals compute({
    required List<QuoteLine> lines,
    required Money delivery,
    int rateBp = 0,
    int ratePpm = 0,
    String? sellerState,
    String? buyerState,
  }) {
    final iso = delivery.isoCode;
    final intra = isIntraState(sellerState, buyerState);
    final rate = BigInt.from(rateBp);
    var cgst = BigInt.zero, sgst = BigInt.zero, igst = BigInt.zero;
    var subtotal = zeroMoney(iso);
    for (final line in lines) {
      final base = line.lineTotal;
      subtotal += base;
      if (intra) {
        final half = roundHalfUp(base.minorUnits * rate, _twentyK);
        cgst += half;
        sgst += half;
      } else {
        igst += roundHalfUp(base.minorUnits * rate, _tenK);
      }
    }
    final breakdown = GstBreakdown(
      intraState: intra,
      rateBp: rateBp,
      cgst: moneyFromBigMinor(cgst, iso),
      sgst: moneyFromBigMinor(sgst, iso),
      igst: moneyFromBigMinor(igst, iso),
    );
    final tax = breakdown.total;
    return QuoteTotals(
      subtotal: subtotal,
      tax: tax,
      delivery: delivery,
      total: subtotal + tax + delivery,
      breakdown: breakdown,
    );
  }
}

/// US sales tax: one seller-entered rate (parts per million, so 8.875% is
/// exact) on the subtotal, rounded to the cent. Delivery is not taxed in the
/// MVP.
class SalesTaxRule extends TaxRule {
  const SalesTaxRule();

  @override
  List<int> get rateOptionsBp => const [];
  @override
  int get defaultRateBp => 0;

  @override
  QuoteTotals compute({
    required List<QuoteLine> lines,
    required Money delivery,
    int rateBp = 0,
    int ratePpm = 0,
    String? sellerState,
    String? buyerState,
  }) {
    final iso = delivery.isoCode;
    final subtotal = MoneyX.sum(lines.map((l) => l.lineTotal), iso);
    final tax = moneyFromBigMinor(usSalesTax(subtotal.minorUnits, ratePpm), iso);
    return QuoteTotals(
      subtotal: subtotal,
      tax: tax,
      delivery: delivery,
      total: subtotal + tax + delivery,
      breakdown: SalesTaxBreakdown(ratePpm: ratePpm, amount: tax),
    );
  }
}

/// Server-shaped line for [computeQuoteTotalsMinor]: `qty` may be
/// fractional (up to 3 decimals, e.g. "2.5" kg) and India carries a GST rate
/// per line, exactly like `compute_quote_totals` in SQL.
class TaxLineInput {
  const TaxLineInput({required this.qty, required this.unitPriceMinor, this.taxRateBp = 0});

  /// Decimal string or number, e.g. 1, "2.5", "0.125".
  final Object qty;
  final int unitPriceMinor;
  final int taxRateBp;
}

/// Parses a non-negative decimal quantity into numerator / 10^scale without
/// floating point.
(BigInt, BigInt) _decimal(Object qty) {
  final s = qty.toString().trim();
  final m = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(s);
  if (m == null) throw ArgumentError.value(qty, 'qty', 'Not a non-negative decimal');
  final frac = m.group(2) ?? '';
  return (BigInt.parse('${m.group(1)}$frac'), BigInt.from(10).pow(frac.length));
}

/// `gst_line_tax` (SQL): base = round_half_up(qty * unit_price, 1); intra:
/// CGST = SGST = round_half_up(base * bp, 20000); inter: IGST =
/// round_half_up(base * bp, 10000).
({BigInt base, BigInt cgst, BigInt sgst, BigInt igst, BigInt tax}) gstLineTax({
  required Object qty,
  required int unitPriceMinor,
  required int rateBp,
  required bool intraState,
}) {
  final (n, d) = _decimal(qty);
  final base = roundHalfUp(n * BigInt.from(unitPriceMinor), d);
  final rate = BigInt.from(rateBp);
  if (intraState) {
    final half = roundHalfUp(base * rate, _twentyK);
    return (base: base, cgst: half, sgst: half, igst: BigInt.zero, tax: half + half);
  }
  final igst = roundHalfUp(base * rate, _tenK);
  return (base: base, cgst: BigInt.zero, sgst: BigInt.zero, igst: igst, tax: igst);
}

/// `us_sales_tax` (SQL): round_half_up(subtotal * rate_ppm, 1000000).
BigInt usSalesTax(BigInt subtotalMinor, int ratePpm) {
  if (ratePpm < 0 || ratePpm > ppmPerUnit) throw ArgumentError.value(ratePpm, 'ratePpm', 'Not 0..1000000');
  return roundHalfUp(subtotalMinor * BigInt.from(ratePpm), _million);
}

/// Mirror of `compute_quote_totals` (SQL) in minor units, for previews and
/// for the shared fixtures. `tax_breakdown.rate_bp` is the highest line rate
/// for India; US sales tax is in ppm.
({BigInt subtotal, BigInt tax, BigInt delivery, BigInt total, Map<String, Object?> breakdown}) computeQuoteTotalsMinor({
  required bool india,
  required List<TaxLineInput> lines,
  int deliveryMinor = 0,
  int salesTaxRatePpm = 0,
  bool intraState = true,
}) {
  var sub = BigInt.zero, tax = BigInt.zero, cgst = BigInt.zero, sgst = BigInt.zero, igst = BigInt.zero;
  var maxRate = 0;
  for (final l in lines) {
    final r = gstLineTax(
      qty: l.qty,
      unitPriceMinor: l.unitPriceMinor,
      rateBp: india ? l.taxRateBp : 0,
      intraState: intraState,
    );
    sub += r.base;
    if (india) {
      cgst += r.cgst;
      sgst += r.sgst;
      igst += r.igst;
      tax += r.tax;
      if (l.taxRateBp > maxRate) maxRate = l.taxRateBp;
    }
  }
  final Map<String, Object?> breakdown;
  if (india) {
    breakdown = {
      'kind': 'gst',
      'mode': intraState ? 'intra' : 'inter',
      'rate_bp': maxRate,
      'cgst': cgst.toInt(),
      'sgst': sgst.toInt(),
      'igst': igst.toInt(),
    };
  } else {
    tax = usSalesTax(sub, salesTaxRatePpm);
    breakdown = {
      'kind': 'sales_tax',
      'rate_ppm': salesTaxRatePpm,
      'rate_bp': ppmToLegacyBp(salesTaxRatePpm),
      'amount': tax.toInt(),
    };
  }
  final delivery = BigInt.from(deliveryMinor);
  return (subtotal: sub, tax: tax, delivery: delivery, total: sub + tax + delivery, breakdown: breakdown);
}

/// Formats basis points as a percentage string without floating point:
/// 1800 -> "18", 825 -> "8.25", 50 -> "0.5".
String bpToPercent(int bp) {
  final whole = bp ~/ 100;
  final frac = bp % 100;
  if (frac == 0) return '$whole';
  final f = frac.toString().padLeft(2, '0').replaceAll(RegExp(r'0$'), '');
  return '$whole.$f';
}

/// Parses "8.25" into 825 basis points. Returns null if invalid or > 100%.
int? percentToBp(String input) {
  final m = RegExp(r'^\s*(\d{1,3})(?:\.(\d{1,2}))?\s*$').firstMatch(input);
  if (m == null) return null;
  final bp = int.parse(m.group(1)!) * 100 + int.parse((m.group(2) ?? '').padRight(2, '0'));
  return bp > 10000 ? null : bp;
}

/// Formats parts per million as a percentage string without floating point,
/// up to 4 decimals (3 for any rate the form accepts): 88750 -> "8.875",
/// 82500 -> "8.25", 70000 -> "7".
String ppmToPercent(int ppm) {
  final whole = ppm ~/ 10000;
  final frac = ppm % 10000;
  if (frac == 0) return '$whole';
  final f = frac.toString().padLeft(4, '0').replaceAll(RegExp(r'0+$'), '');
  return '$whole.$f';
}

/// Parses a sales tax percentage with up to 3 decimals ("8.875") into parts
/// per million (88750). Returns null if invalid or > 100%.
int? percentToPpm(String input) {
  final m = RegExp(r'^\s*(\d{1,3})(?:\.(\d{1,3}))?\s*$').firstMatch(input);
  if (m == null) return null;
  final ppm = int.parse(m.group(1)!) * 10000 + int.parse((m.group(2) ?? '').padRight(3, '0')) * 10;
  return ppm > ppmPerUnit ? null : ppm;
}
