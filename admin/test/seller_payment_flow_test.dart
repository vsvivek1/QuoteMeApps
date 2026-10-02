import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/app.dart';
import 'package:iwant_admin/core/config/admin_env.dart';
import 'package:iwant_admin/core/demo/demo_store.dart';
import 'package:iwant_admin/core/providers.dart';
import 'package:iwant_admin/features/sellers/domain/manual_payment.dart';

void main() {
  testWidgets('demo: find a seller by phone and record a UPI payment', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [adminEnvProvider.overrideWithValue(const AdminEnv(country: 'india'))],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AdminApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), DemoStore.adminEmail);
    await tester.enterText(find.byType(TextFormField).at(1), DemoStore.adminPassword);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sellers').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '98765 43210');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Sharma Cooling Services (demo)'), findsOneWidget);

    await tester.tap(find.text('Sharma Cooling Services (demo)'));
    await tester.pumpAndSettle();
    expect(find.text('No paid plan'), findsOneWidget);

    await tester.tap(find.text('Record manual payment'));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    final fields = find.descendant(of: dialog, matching: find.byType(TextFormField));
    await tester.enterText(fields.at(0), '499.50');
    await tester.enterText(fields.at(1), '4123 5678 9012');
    await tester.enterText(fields.at(2), 'Ravi Kumar');

    // Grant stays disabled until the bank check is ticked.
    final grant = find.widgetWithText(FilledButton, 'Grant plan');
    expect(tester.widget<FilledButton>(grant).onPressed, isNull);
    await tester.tap(find.text('I have checked this payment arrived in the company bank account'));
    await tester.pump();
    await tester.tap(grant);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Pro until'), findsWidgets);
    expect(find.textContaining('ref 412356789012'), findsOneWidget);

    final store = container.read(adminBackendProvider).demo!;
    final row = store.entitlements.last;
    expect(row.sellerId, 's-0');
    expect(row.tier, 'pro');
    final note = parseManualPaymentNote(row.note)!;
    expect(note['method'], 'upi');
    expect(note['amount_minor'], 49950);
    expect(note['ref'], '412356789012');
    expect(note['payer'], 'Ravi Kumar');
    expect(store.audit.first.action, 'admin_grant_entitlement');

    // The same reference cannot be used twice.
    await tester.tap(find.text('Record manual payment'));
    await tester.pumpAndSettle();
    final f2 = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    await tester.enterText(f2.at(0), '499');
    await tester.enterText(f2.at(1), '412356789012');
    await tester.tap(find.text('I have checked this payment arrived in the company bank account'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Grant plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('already used'), findsOneWidget);
    expect(store.entitlements.where((e) => e.sellerId == 's-0'), hasLength(1));
  });
}
