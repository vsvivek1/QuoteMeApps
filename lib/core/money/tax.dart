import 'money.dart';

/// Tax rounding lives here and only here. The same rules are implemented in
/// SQL (`supabase/migrations`) and the Edge Function shared helper, tested
/// against the same cases.
///
/// Rates are integers in basis points (18% = 1800). Rounding is half-up.
BigInt roundHalfUp(BigInt numerator, BigInt denominator) {
  assert(!numerator.isNegative && denominator > BigInt.zero);
  return (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);
}

final _tenK = BigInt.from(10000);
final _twentyK = BigInt.from(20000);

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
        return SalesTaxBreakdown(
          rateBp: (json['rate_bp'] as num).toInt(),
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
  const SalesTaxBreakdown({required this.rateBp, required this.amount});

  final int rateBp;
  final Money amount;

  @override
  Map<String, Object?> toJson() => {'kind': 'sales_tax', 'rate_bp': rateBp, 'amount': amount.minorInt};
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

  /// Selectable rates in basis points, shown in the quote form.
  List<int> get rateOptionsBp;
  int get defaultRateBp;

  QuoteTotals compute({
    required List<QuoteLine> lines,
    required Money delivery,
    required int rateBp,
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
    required int rateBp,
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

/// US sales tax: one seller-entered rate on the subtotal, rounded to the cent.
/// Delivery is not taxed in the MVP.
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
    required int rateBp,
    String? sellerState,
    String? buyerState,
  }) {
    final iso = delivery.isoCode;
    final subtotal = MoneyX.sum(lines.map((l) => l.lineTotal), iso);
    final taxMinor = roundHalfUp(subtotal.minorUnits * BigInt.from(rateBp), _tenK);
    final tax = moneyFromBigMinor(taxMinor, iso);
    return QuoteTotals(
      subtotal: subtotal,
      tax: tax,
      delivery: delivery,
      total: subtotal + tax + delivery,
      breakdown: SalesTaxBreakdown(rateBp: rateBp, amount: tax),
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

/// `us_sales_tax` (SQL): round_half_up(subtotal * bp, 10000).
BigInt usSalesTax(BigInt subtotalMinor, int rateBp) => roundHalfUp(subtotalMinor * BigInt.from(rateBp), _tenK);

/// Mirror of `compute_quote_totals` (SQL) in minor units, for previews and
/// for the shared fixtures. `tax_breakdown.rate_bp` is the highest line rate
/// for India.
({BigInt subtotal, BigInt tax, BigInt delivery, BigInt total, Map<String, Object?> breakdown}) computeQuoteTotalsMinor({
  required bool india,
  required List<TaxLineInput> lines,
  int deliveryMinor = 0,
  int salesTaxRateBp = 0,
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
    tax = usSalesTax(sub, salesTaxRateBp);
    breakdown = {'kind': 'sales_tax', 'rate_bp': salesTaxRateBp, 'amount': tax.toInt()};
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
