import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/providers.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/features/community/presentation/community_screen.dart';
import 'package:iwant/features/community/presentation/feed_post_screen.dart';
import 'package:iwant/features/seller/presentation/quote_form_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('community feed lists public posts and filters group buys', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    demo.signInAs(demo.demoBuyerId);
    await pumpScreen(tester, c, const CommunityScreen());
    await tester.pumpAndSettle();

    expect(find.text('Ceiling fans for our apartment block'), findsOneWidget);
    expect(find.text('Plumber for a leaking kitchen tap'), findsOneWidget);
    expect(find.text('Group buy'), findsOneWidget);
    expect(find.textContaining('10 more fans unlocks'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Group buys'));
    await tester.pumpAndSettle();
    expect(find.text('Plumber for a leaking kitchen tap'), findsNothing);
    expect(find.text('Ceiling fans for our apartment block'), findsOneWidget);
  });

  testWidgets('post screen: join the group buy and comment', (tester) async {
    tester.view.physicalSize = const Size(1080, 5200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    demo.signInAs(demo.demoBuyerId);
    await pumpScreen(tester, c, const FeedPostScreen(requestId: 'demo-post-group'));
    await tester.pumpAndSettle();

    expect(find.text('Price as the group grows'), findsOneWidget);
    expect(find.text('Count me in for 4, we are in B block.'), findsOneWidget);

    await tester.tap(find.text('Join group buy'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '12');
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Join group buy')));
    await tester.pumpAndSettle();
    expect(find.text("You're in for 12 fans"), findsOneWidget);
    expect(demo.groupMembers['demo-post-group']![demo.demoBuyerId], 12);

    await tester.enterText(find.widgetWithText(TextField, 'Write a comment…'), 'Joined with 12!');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Joined with 12!'), findsOneWidget);
    expect(demo.comments['demo-post-group']!.last.body, 'Joined with 12!');
  });

  testWidgets('quote form on a group buy saves price tiers', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    demo
      ..seedCommunity()
      ..signInAs('demo-seller-1');
    await pumpScreen(tester, c, const QuoteFormScreen(requestId: 'demo-post-group'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quote-tiers')), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Unit price').first, '3000');
    final prices = find.widgetWithText(TextFormField, 'Price each');
    await tester.enterText(prices.at(0), '3000');
    await tester.enterText(find.widgetWithText(TextFormField, 'From qty').at(1), '20');
    await tester.enterText(prices.at(1), '2600');
    await tester.ensureVisible(find.textContaining('Send quote'));
    await tester.tap(find.textContaining('Send quote'));
    await tester.pumpAndSettle();

    final mine = demo.quotes.values.where((q) => demo.quoteSellerIds[q.id] == 'demo-seller-1').single;
    expect(
      [for (final t in demo.quoteTiers[mine.id]!) (t.minQty, t.unitPrice.minorUnits.toInt())],
      [(1, 300000), (20, 260000)],
    );
  });
}
