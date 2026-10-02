import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/core/config/admin_country.dart';
import 'package:iwant_admin/features/brochures/application/brochure_pdf.dart';

void main() {
  test('builds a PDF brochure with signup QR for each format', () async {
    for (final format in BrochureFormat.values) {
      final bytes = await buildBrochurePdf(BrochureSpec(
        config: AdminCountryConfig.usa,
        city: 'Dallas',
        state: 'Texas',
        categoryName: 'HVAC',
        language: 'es',
        foundingUntil: 'Apr 1, 2027',
        signupUrl: AdminCountryConfig.usa.signupUrl(source: 'brochure', medium: 'print', city: 'Dallas', category: 'hvac'),
        format: format,
      ));
      expect(latin1.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(2000));
    }
  });

  test('signup links carry UTM tags', () {
    final u = AdminCountryConfig.india.signupUrl(source: 'brochure', medium: 'print', campaign: 'pune-ac-repair-en');
    expect(u.host, 'iwantindia.app');
    expect(u.queryParameters['utm_source'], 'brochure');
    expect(u.queryParameters['utm_campaign'], 'pune-ac-repair-en');
  });
}
