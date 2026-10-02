import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/features/sellers/domain/manual_payment.dart';
import 'package:iwant_admin/features/sellers/domain/seller_models.dart';

void main() {
  group('parseAmountToMinor', () {
    test('whole and decimal rupees become integer paise', () {
      expect(parseAmountToMinor('499'), 49900);
      expect(parseAmountToMinor('499.5'), 49950);
      expect(parseAmountToMinor('499.50'), 49950);
      expect(parseAmountToMinor('499.05'), 49905);
      expect(parseAmountToMinor('499.'), 49900);
      expect(parseAmountToMinor('.5'), 50);
      expect(parseAmountToMinor('0.01'), 1);
      expect(parseAmountToMinor('007'), 700);
    });

    test('grouping, currency signs and spaces are accepted', () {
      expect(parseAmountToMinor('1,499.00'), 149900);
      expect(parseAmountToMinor('1,00,000'), 10000000);
      expect(parseAmountToMinor('  ₹ 4,999 '), 499900);
      expect(parseAmountToMinor('Rs. 299'), 29900);
      expect(parseAmountToMinor('INR 2999.99'), 299999);
      expect(parseAmountToMinor(r'$19.99'), 1999);
    });

    test('no floating point drift', () {
      // 0.29 * 100 == 28.999999999999996 as a double.
      expect(parseAmountToMinor('0.29'), 29);
      expect(parseAmountToMinor('1.15'), 115);
      expect(parseAmountToMinor('999999999.99'), 99999999999);
    });

    test('invalid amounts are rejected', () {
      for (final bad in ['', ' ', '.', '0', '0.00', '-5', '+5', '4.999', '1e3', 'abc', '12a', '1.2.3', '1 000x']) {
        expect(parseAmountToMinor(bad), isNull, reason: bad);
      }
      expect(parseAmountToMinor('1234567890'), isNull, reason: 'over 9 major digits');
    });
  });

  test('formatMinor groups thousands with integer maths', () {
    expect(formatMinor(49900), '499.00');
    expect(formatMinor(149905), '1,499.05');
    expect(formatMinor(5), '0.05');
    expect(formatMinor(123456789), '1,234,567.89');
  });

  test('normalizeReference', () {
    expect(normalizeReference(' 4123 5678 9012 '), '412356789012');
    expect(normalizeReference('pay_ABC123xyz'), 'PAY_ABC123XYZ');
    expect(normalizeReference('NEFT/N123-45.6'), 'NEFT/N123-45.6');
    expect(normalizeReference(''), isNull);
    expect(normalizeReference('ab1'), isNull);
    expect(normalizeReference('UTR#123456'), isNull);
    expect(normalizeReference('A' * 65), isNull);
  });

  group('manualPlanExpiry', () {
    final now = DateTime(2026, 10, 2, 15, 30); // local time

    test('Pro monthly runs through the end of today + 30 days', () {
      final e = manualPlanExpiry(ManualPlan.proMonthly, now)!;
      expect(e.isUtc, isTrue);
      expect(e.toLocal(), DateTime(2026, 11, 2));
      expect(e.toLocal().subtract(const Duration(seconds: 1)).day, 1); // last day: Nov 1
    });

    test('Pro annual is 365 days', () {
      expect(manualPlanExpiry(ManualPlan.proAnnual, now)!.toLocal(), DateTime(2027, 10, 3));
    });

    test('month and year rollover', () {
      expect(manualPlanExpiry(ManualPlan.proMonthly, DateTime(2026, 12, 15, 9))!.toLocal(), DateTime(2027, 1, 15));
    });

    test('credits never expire', () {
      expect(manualPlanExpiry(ManualPlan.credits10, now), isNull);
      expect(manualPlanExpiry(ManualPlan.credits50, now), isNull);
    });
  });

  test('plans map to the RPC tier and credits', () {
    expect([for (final p in ManualPlan.values) p.id],
        ['seller_pro_monthly', 'seller_pro_annual', 'credits_10', 'credits_50']);
    expect(ManualPlan.proMonthly.tier, 'pro');
    expect(ManualPlan.proMonthly.credits, 0);
    expect(ManualPlan.credits10.tier, 'credits');
    expect(ManualPlan.credits10.credits, 10);
    expect(ManualPlan.credits50.credits, 50);
  });

  group('note', () {
    test('compact JSON with method, amount, reference and payer', () {
      final note = buildManualPaymentNote(
        plan: ManualPlan.proAnnual,
        method: PaymentMethod.upi,
        amountMinor: 499900,
        currency: 'INR',
        reference: '412356789012',
        payerName: '  Ravi   Kumar ',
      );
      expect(note,
          '{"kind":"manual_payment","plan":"seller_pro_annual","method":"upi","amount_minor":499900,'
          '"currency":"INR","ref":"412356789012","payer":"Ravi Kumar","bank_checked":true}');
      expect(parseManualPaymentNote(note)!['amount_minor'], 499900);
    });

    test('payer is optional and quotes are escaped', () {
      final note = buildManualPaymentNote(
        plan: ManualPlan.credits10,
        method: PaymentMethod.bankTransfer,
        amountMinor: 9900,
        currency: 'INR',
        reference: 'N123',
        payerName: ' ',
      );
      expect((jsonDecode(note) as Map).containsKey('payer'), isFalse);
      final quoted = buildManualPaymentNote(
        plan: ManualPlan.credits10,
        method: PaymentMethod.other,
        amountMinor: 1,
        currency: 'INR',
        reference: 'N123',
        payerName: 'A "B" C',
      );
      expect(parseManualPaymentNote(quoted)!['payer'], 'A "B" C');
    });

    test('other notes are not manual payments', () {
      expect(parseManualPaymentNote(null), isNull);
      expect(parseManualPaymentNote('partner deal'), isNull);
      expect(parseManualPaymentNote('{broken'), isNull);
      expect(parseManualPaymentNote('{"kind":"other"}'), isNull);
    });

    test('ManualPaymentGrant builds the RPC arguments', () {
      final g = ManualPaymentGrant(
        sellerId: 's-1',
        plan: ManualPlan.proMonthly,
        method: PaymentMethod.upi,
        amountMinor: parseAmountToMinor('499')!,
        currency: 'INR',
        reference: normalizeReference('utr 1234 5678')!,
        payerName: 'Asha',
        now: DateTime(2026, 10, 2, 10),
      );
      expect(g.tier, 'pro');
      expect(g.credits, 0);
      expect(g.expiresAt!.toLocal(), DateTime(2026, 11, 2));
      final n = parseManualPaymentNote(g.note)!;
      expect(n['plan'], 'seller_pro_monthly');
      expect(n['ref'], 'UTR12345678');
      expect(n['amount_minor'], 49900);
    });
  });

  group('CurrentEntitlement', () {
    final now = DateTime.utc(2026, 10, 2);
    EntitlementRecord ent(String id, String tier,
            {String status = 'active', int credits = 0, DateTime? expires, int ageDays = 1}) =>
        EntitlementRecord(
          id: id,
          sellerId: 's',
          store: 'manual',
          productId: 'admin_grant_$tier',
          tier: tier,
          status: status,
          creditsBalance: credits,
          expiresAt: expires,
          createdAt: now.subtract(Duration(days: ageDays)),
        );

    test('empty', () {
      final c = CurrentEntitlement.from(const [], now);
      expect(c.isEmpty, isTrue);
      expect(c.hasPro, isFalse);
    });

    test('latest live Pro and the sum of live credits', () {
      final c = CurrentEntitlement.from([
        ent('old', 'pro', expires: now.subtract(const Duration(days: 1))),
        ent('short', 'pro', expires: now.add(const Duration(days: 5))),
        ent('long', 'pro', expires: now.add(const Duration(days: 300))),
        ent('revoked', 'pro', status: 'revoked', expires: now.add(const Duration(days: 900))),
        ent('c1', 'credits', credits: 10),
        ent('c2', 'credits', credits: 4, expires: now.add(const Duration(days: 1))),
        ent('c3', 'credits', credits: 50, expires: now.subtract(const Duration(days: 1))),
        ent('c4', 'credits', credits: 50, status: 'refunded'),
      ], now);
      expect(c.pro!.id, 'long');
      expect(c.creditsBalance, 14);
    });
  });

  test('phoneDigits tells phone searches from name searches', () {
    expect(phoneDigits('+91 98765 43210'), '919876543210');
    expect(phoneDigits('(512) 555-0101'), '5125550101');
    expect(phoneDigits('123'), isNull);
    expect(phoneDigits('Sharma 98765'), isNull);
    expect(phoneDigits('Bright Prints'), isNull);
  });
}
