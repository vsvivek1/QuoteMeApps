import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/app.dart';
import 'package:iwant_admin/core/config/admin_env.dart';
import 'package:iwant_admin/core/demo/demo_store.dart';
import 'package:iwant_admin/core/providers.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [adminEnvProvider.overrideWithValue(const AdminEnv(country: 'india'))],
      child: const AdminApp(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('demo: non-admin is refused, admin reaches the dashboard', (tester) async {
    await pumpApp(tester);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), DemoStore.sellerEmail);
    await tester.enterText(find.byType(TextFormField).at(1), DemoStore.sellerPassword);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not have the admin role'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), DemoStore.adminEmail);
    await tester.enterText(find.byType(TextFormField).at(1), DemoStore.adminPassword);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Queues'), findsOneWidget);
    expect(find.textContaining('I Want India Admin'), findsWidgets);

    await tester.tap(find.text('Outreach CRM').first);
    await tester.pumpAndSettle();
    expect(find.text('Sourced'), findsWidgets);
    expect(find.text('Northside Cooling (demo)'), findsOneWidget);
  });
}
