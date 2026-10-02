import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/money/money.dart';
import 'package:iwant/core/money/money_formatter.dart';
import 'package:iwant/core/money/tax.dart';

QuoteLine line(int qty, int unitMinor, String iso) =>
    QuoteLine(description: 'x', qty: qty, unitPrice: moneyFromMinor(unitMinor, iso));

void main() {
  group('roundHalfUp', () {
    test('rounds half up', () {
      expect(roundHalfUp(BigInt.from(5), BigInt.from(10)), BigInt.one);
      expect(roundHalfUp(BigInt.from(4), BigInt.from(10)), BigInt.zero);
      expect(roundHalfUp(BigInt.zero, BigInt.from(10)), BigInt.zero);
    });
  });

  group('GST (India), same cases as SQL and Edge Function helpers', () {
    const gst = GstTaxRule();
    final zero = zeroMoney('INR');

    test('intra-state 99999 @18% -> CGST 9000 + SGST 9000', () {
      final t = gst.compute(
        lines: [line(1, 99999, 'INR')],
        delivery: zero,
        rateBp: 1800,
        sellerState: 'Karnataka',
        buyerState: 'Karnataka',
      );
      final b = t.breakdown as GstBreakdown;
      expect(b.intraState, isTrue);
      expect(b.cgst.minorInt, 9000);
      expect(b.sgst.minorInt, 9000);
      expect(b.igst.minorInt, 0);
      expect(t.total.minorInt, 99999 + 18000);
    });

    test('inter-state 99999 @18% -> IGST 18000', () {
      final t = gst.compute(
        lines: [line(1, 99999, 'INR')],
        delivery: zero,
        rateBp: 1800,
        sellerState: 'Karnataka',
        buyerState: 'Kerala',
      );
      final b = t.breakdown as GstBreakdown;
      expect(b.intraState, isFalse);
      expect(b.igst.minorInt, 18000);
      expect(t.tax.minorInt, 18000);
    });

    test('333 @5% intra -> CGST 8 (8.325 rounds down)', () {
      final t = gst.compute(lines: [line(1, 333, 'INR')], delivery: zero, rateBp: 500);
      expect((t.breakdown as GstBreakdown).cgst.minorInt, 8);
    });

    test('computed per line, not on the subtotal', () {
      // Two lines of 333 @5%: per line CGST 8 + 8 = 16 (subtotal method would give 17).
      final t = gst.compute(lines: [line(1, 333, 'INR'), line(1, 333, 'INR')], delivery: zero, rateBp: 500);
      expect((t.breakdown as GstBreakdown).cgst.minorInt, 16);
    });

    test('delivery is added to the total untaxed', () {
      final t = gst.compute(lines: [line(2, 1000000, 'INR')], delivery: moneyFromMinor(50000, 'INR'), rateBp: 1800);
      expect(t.subtotal.minorInt, 2000000);
      expect(t.tax.minorInt, 360000);
      expect(t.total.minorInt, 2000000 + 360000 + 50000);
    });

    test('json round trip', () {
      final t = gst.compute(lines: [line(1, 10000, 'INR')], delivery: zero, rateBp: 1800);
      final back = TaxBreakdown.fromJson(t.breakdown.toJson(), 'INR') as GstBreakdown;
      expect(back.cgst.minorInt, 900);
      expect(back.rateBp, 1800);
    });
  });

  group('US sales tax', () {
    const rule = SalesTaxRule();
    final zero = zeroMoney('USD');
    test('1999 @8.25% -> 165', () {
      final t = rule.compute(lines: [line(1, 1999, 'USD')], delivery: zero, ratePpm: 82500);
      expect(t.tax.minorInt, 165);
      expect(t.total.minorInt, 2164);
    });
    test('10 @5% -> 1 (0.5 rounds up)', () {
      expect(rule.compute(lines: [line(1, 10, 'USD')], delivery: zero, ratePpm: 50000).tax.minorInt, 1);
    });
    test('0 -> 0', () {
      expect(rule.compute(lines: [line(1, 0, 'USD')], delivery: zero, ratePpm: 82500).tax.minorInt, 0);
    });
    test('NYC 8.875% is exact: 10000 -> 888 (887.5 half up)', () {
      final t = rule.compute(lines: [line(1, 10000, 'USD')], delivery: zero, ratePpm: 88750);
      expect(t.tax.minorInt, 888);
      final b = t.breakdown as SalesTaxBreakdown;
      expect(b.ratePpm, 88750);
      expect(b.toJson(), {'kind': 'sales_tax', 'rate_ppm': 88750, 'rate_bp': 888, 'amount': 888});
    });
    test('the GST rate is ignored', () {
      expect(rule.compute(lines: [line(1, 1000, 'USD')], delivery: zero, rateBp: 1800).tax.minorInt, 0);
    });
    test('breakdown JSON: rate_ppm wins, legacy rate_bp is read as bp * 100', () {
      final now = TaxBreakdown.fromJson({'kind': 'sales_tax', 'rate_ppm': 88750, 'rate_bp': 888, 'amount': 888}, 'USD');
      expect((now as SalesTaxBreakdown).ratePpm, 88750);
      final old = TaxBreakdown.fromJson({'kind': 'sales_tax', 'rate_bp': 825, 'amount': 165}, 'USD');
      expect((old as SalesTaxBreakdown).ratePpm, 82500);
    });
    test('rate out of range is rejected', () {
      expect(() => usSalesTax(BigInt.one, 1000001), throwsArgumentError);
      expect(() => usSalesTax(BigInt.one, -1), throwsArgumentError);
    });
  });

  group('percent helpers', () {
    test('bpToPercent', () {
      expect(bpToPercent(1800), '18');
      expect(bpToPercent(825), '8.25');
      expect(bpToPercent(50), '0.5');
      expect(bpToPercent(1250), '12.5');
    });
    test('percentToBp', () {
      expect(percentToBp('8.25'), 825);
      expect(percentToBp('18'), 1800);
      expect(percentToBp('7.5'), 750);
      expect(percentToBp('abc'), isNull);
      expect(percentToBp('101'), isNull);
    });
    test('ppmToPercent', () {
      expect(ppmToPercent(88750), '8.875');
      expect(ppmToPercent(82500), '8.25');
      expect(ppmToPercent(70000), '7');
      expect(ppmToPercent(10), '0.001');
      expect(ppmToPercent(1), '0.0001');
      expect(ppmToPercent(1000000), '100');
    });
    test('percentToPpm accepts up to 3 decimals', () {
      expect(percentToPpm('8.875'), 88750);
      expect(percentToPpm(' 8.25 '), 82500);
      expect(percentToPpm('8.'), isNull);
      expect(percentToPpm('8.8751'), isNull);
      expect(percentToPpm('100'), 1000000);
      expect(percentToPpm('100.001'), isNull);
      expect(percentToPpm('abc'), isNull);
    });
    test('bp <-> ppm', () {
      expect(bpToPpm(825), 82500);
      expect(ppmToLegacyBp(88750), 888);
      expect(ppmToLegacyBp(82500), 825);
    });
  });

  group('MoneyFormatter', () {
    final f = MoneyFormatter('en');
    test('Indian grouping', () {
      expect(f.format(moneyFromMinor(10000000, 'INR')), '₹1,00,000.00');
      expect(f.format(moneyFromMinor(1234567890, 'INR')), '₹1,23,45,678.90');
      expect(f.compact(moneyFromMinor(10000000, 'INR')), '₹1,00,000');
    });
    test('US grouping', () {
      expect(f.format(moneyFromMinor(10000000, 'USD')), r'$100,000.00');
      expect(f.compact(moneyFromMinor(129950, 'USD')), r'$1,299.50');
    });
    test('negative and range', () {
      expect(f.format(moneyFromMinor(-500, 'USD')), r'-$5.00');
      expect(f.range(moneyFromMinor(100000, 'INR'), moneyFromMinor(150000, 'INR')), '₹1,000 – ₹1,500');
    });
  });

  group('parseUserAmount', () {
    test('parses common inputs', () {
      expect(parseUserAmount('1,299.50', 'USD')!.minorInt, 129950);
      expect(parseUserAmount('1299', 'USD')!.minorInt, 129900);
      expect(parseUserAmount('1,00,000', 'INR')!.minorInt, 10000000);
      expect(parseUserAmount('0.5', 'USD')!.minorInt, 50);
      expect(parseUserAmount('', 'USD'), isNull);
      expect(parseUserAmount('1.234', 'USD'), isNull);
    });
  });
}
