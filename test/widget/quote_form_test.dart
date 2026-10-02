import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/providers.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/country/usa/usa_config.dart';
import 'package:iwant/features/requests/domain/buyer_request.dart';
import 'package:iwant/features/seller/presentation/quote_form_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  Future<String> seedRequest(dynamic demo, String state) async {
    demo.signInAs(demo.demoBuyerId);
    final cat = demo.categories.firstWhere((c) => c.names['en'] == 'TVs');
    final r = demo.createRequest(demo.demoBuyerId, RequestDraft(text: 'TV', categoryId: cat.id, state: state), title: '55 inch TV');
    demo.requests[r.id] = r.copyWith(priorityUntil: DateTime(2000));
    return r.id as String;
  }

  testWidgets('India quote form shows live CGST/SGST split and sends', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    final id = await seedRequest(demo, 'Karnataka');
    demo.signInAs('demo-seller-0');
    await pumpScreen(tester, c, QuoteFormScreen(requestId: id));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Unit price'), '40000');
    await tester.pumpAndSettle();
    expect(find.text('CGST 9%'), findsOneWidget);
    expect(find.text('₹3,600.00'), findsNWidgets(2)); // CGST and SGST
    expect(find.text('₹47,200.00'), findsOneWidget);

    await tester.tap(find.textContaining('Send quote'));
    await tester.pumpAndSettle();
    expect(demo.quotes.values.single.total.minorUnits.toInt(), 4720000);
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('USA quote form uses a seller-entered sales tax rate', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final c = await demoContainer(usaConfig);
    final demo = c.read(backendProvider).demo!;
    final id = await seedRequest(demo, 'Texas');
    demo.signInAs('demo-seller-0');
    await pumpScreen(tester, c, QuoteFormScreen(requestId: id));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Unit price'), '1000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Sales tax rate (%)'), '8.25');
    await tester.pumpAndSettle();
    expect(find.text('Sales tax 8.25%'), findsOneWidget);
    expect(find.text(r'$82.50'), findsOneWidget);
    expect(find.text(r'$1,082.50'), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
  });
}
