import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/money/money.dart';
import 'package:iwant/core/money/tax.dart';

/// The shared rounding cases used by SQL (pgTAP) and the Edge Functions
/// (Deno), run against lib/core/money (API.md section 1).
void main() {
  final fixtures =
      jsonDecode(File('supabase/tests/fixtures/money_rounding_cases.json').readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> cases(String key) => [
    for (final c in fixtures[key] as List) Map<String, dynamic>.from(c as Map),
  ];

  group('round_half_up', () {
    for (final c in cases('round_half_up')) {
      test('${c['n']} / ${c['d']} -> ${c['expected']}', () {
        expect(roundHalfUp(BigInt.from(c['n'] as int), BigInt.from(c['d'] as int)), BigInt.from(c['expected'] as int));
      });
    }
  });

  group('gst_line', () {
    for (final c in cases('gst_line')) {
      final intra = c['intra'] as bool;
      final label = '${c['qty']} x ${c['unit_price_minor']} @ ${c['rate_bp']}bp ${intra ? 'intra' : 'inter'}';

      test('gstLineTax: $label', () {
        final r = gstLineTax(
          qty: c['qty'] as Object,
          unitPriceMinor: c['unit_price_minor'] as int,
          rateBp: c['rate_bp'] as int,
          intraState: intra,
        );
        if (c['base'] != null) expect(r.base.toInt(), c['base']);
        expect(r.cgst.toInt(), c['cgst']);
        expect(r.sgst.toInt(), c['sgst']);
        expect(r.igst.toInt(), c['igst']);
        expect(r.tax.toInt(), c['tax']);
      });

      // The app's GstTaxRule (quote form preview) takes whole quantities.
      if (c['qty'] is int) {
        test('GstTaxRule: $label', () {
          final t = const GstTaxRule().compute(
            lines: [
              QuoteLine(
                description: 'x',
                qty: c['qty'] as int,
                unitPrice: moneyFromMinor(c['unit_price_minor'] as int, 'INR'),
              ),
            ],
            delivery: zeroMoney('INR'),
            rateBp: c['rate_bp'] as int,
            sellerState: 'Karnataka',
            buyerState: intra ? 'Karnataka' : 'Kerala',
          );
          final b = t.breakdown as GstBreakdown;
          expect(b.intraState, intra);
          expect(b.cgst.minorInt, c['cgst']);
          expect(b.sgst.minorInt, c['sgst']);
          expect(b.igst.minorInt, c['igst']);
          expect(t.tax.minorInt, c['tax']);
        });
      }
    }
  });

  group('us_sales_tax', () {
    for (final c in cases('us_sales_tax')) {
      final label = '${c['subtotal_minor']} @ ${c['rate_bp']}bp -> ${c['expected']}';
      test('usSalesTax: $label', () {
        expect(usSalesTax(BigInt.from(c['subtotal_minor'] as int), c['rate_bp'] as int).toInt(), c['expected']);
      });
      test('SalesTaxRule: $label', () {
        final t = const SalesTaxRule().compute(
          lines: [QuoteLine(description: 'x', qty: 1, unitPrice: moneyFromMinor(c['subtotal_minor'] as int, 'USD'))],
          delivery: zeroMoney('USD'),
          rateBp: c['rate_bp'] as int,
        );
        expect(t.tax.minorInt, c['expected']);
        expect((t.breakdown as SalesTaxBreakdown).amount.minorInt, c['expected']);
      });
    }
  });

  group('quotes', () {
    for (final c in cases('quotes')) {
      final india = c['country'] == 'IN';
      final iso = india ? 'INR' : 'USD';
      final lines = [for (final l in c['lines'] as List) Map<String, dynamic>.from(l as Map)];
      final label = '${c['country']} ${c['intra'] == true ? 'intra' : 'inter'} total ${c['total_minor']}';

      test('computeQuoteTotalsMinor: $label', () {
        final t = computeQuoteTotalsMinor(
          india: india,
          lines: [
            for (final l in lines)
              TaxLineInput(
                qty: l['qty'] as Object,
                unitPriceMinor: l['unit_price_minor'] as int,
                taxRateBp: l['tax_rate_bp'] as int? ?? 0,
              ),
          ],
          deliveryMinor: c['delivery_minor'] as int,
          salesTaxRateBp: c['sales_tax_rate_bp'] as int,
          intraState: c['intra'] as bool,
        );
        expect(t.subtotal.toInt(), c['subtotal_minor']);
        expect(t.tax.toInt(), c['tax_minor']);
        expect(t.total.toInt(), c['total_minor']);
        expect(t.breakdown, c['tax_breakdown']);
      });

      test('TaxBreakdown JSON round trip: $label', () {
        final b = TaxBreakdown.fromJson(Map<String, dynamic>.from(c['tax_breakdown'] as Map), iso);
        expect(b.toJson(), c['tax_breakdown']);
      });

      // The app's TaxRule uses one rate for every line; check the fixtures
      // that have a single rate through it too.
      final rates = {for (final l in lines) l['tax_rate_bp'] ?? 0};
      if (!india || rates.length == 1) {
        test('CountryConfig TaxRule: $label', () {
          final rule = india ? const GstTaxRule() : const SalesTaxRule() as TaxRule;
          final t = rule.compute(
            lines: [
              for (final l in lines)
                QuoteLine(
                  description: 'x',
                  qty: l['qty'] as int,
                  unitPrice: moneyFromMinor(l['unit_price_minor'] as int, iso),
                ),
            ],
            delivery: moneyFromMinor(c['delivery_minor'] as int, iso),
            rateBp: india ? rates.single as int : c['sales_tax_rate_bp'] as int,
            sellerState: 'A',
            buyerState: c['intra'] == true ? 'A' : 'B',
          );
          expect(t.subtotal.minorInt, c['subtotal_minor']);
          expect(t.tax.minorInt, c['tax_minor']);
          expect(t.total.minorInt, c['total_minor']);
          expect(t.breakdown.toJson(), c['tax_breakdown']);
        });
      }
    }
  });
}
