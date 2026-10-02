import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/providers.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/features/requests/presentation/post_request_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('post request wizard: describe, suggest category, details, location, post', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    demo.signInAs(demo.demoBuyerId);
    // Demo market simulation uses timers; disable by not awaiting them.
    await pumpScreen(tester, c, const PostRequestScreen());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Need a double door fridge 300 litre');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Refrigerators'), findsWidgets);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    // Step 2: category fields render from field_schema.
    expect(find.text('Capacity'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Capacity'), '300');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Step 3: invalid PIN is rejected.
    await tester.enterText(find.widgetWithText(TextFormField, 'PIN code'), '012345');
    await tester.tap(find.text('Post request'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid PIN code'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'PIN code'), '560034');
    await tester.tap(find.text('Post request'));
    await tester.pumpAndSettle();
    expect(find.text('Request posted'), findsOneWidget);
    expect(demo.requests.values.single.fields['capacity_l'], 300);
    expect(demo.requests.values.single.locationCode, '560034');

    // Let the simulated sellers' timers finish so the test exits cleanly.
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('blocked category explains why and disables Next', (tester) async {
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    demo.signInAs(demo.demoBuyerId);
    await pumpScreen(tester, c, const PostRequestScreen());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'I want a personal loan');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining("can't take requests"), findsOneWidget);
    final next = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Next'));
    expect(next.onPressed, isNull);
  });
}
