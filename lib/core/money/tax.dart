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
  const QuoteLine({
    required this.description,
    required this.qty,
    required this.unitPrice,
  });

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
  Map<String, Object?> toJson() =>
      {'kind': 'sales_tax', 'rate_bp': rateBp, 'amount': amount.minorInt};
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
  const GstTaxRule({
    this.rateOptionsBp = const [0, 500, 1800, 4000],
    this.defaultRateBp = 1800,
  });

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
    final taxMinor =
        roundHalfUp(subtotal.minorUnits * BigInt.from(rateBp), _tenK);
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
  final bp = int.parse(m.group(1)!) * 100 +
      int.parse((m.group(2) ?? '').padRight(2, '0'));
  return bp > 10000 ? null : bp;
}
