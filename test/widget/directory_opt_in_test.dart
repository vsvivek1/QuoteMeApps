import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/providers.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/country/usa/usa_config.dart';
import 'package:iwant/features/seller/application/seller_providers.dart';
import 'package:iwant/features/seller/presentation/directory_opt_in_tile.dart';

import '../helpers/pump_app.dart';

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seller = ref.watch(mySellerProvider).value;
    return Scaffold(body: seller == null ? const SizedBox() : DirectoryOptInTile(seller: seller));
  }
}

void main() {
  testWidgets('seller directory toggle is off by default and saves through the repository', (tester) async {
    final c = await demoContainer(usaConfig);
    final demo = c.read(backendProvider).demo!;
    demo.signInAs('demo-seller-0');
    expect(demo.sellers['demo-seller-0']!.directoryOptIn, isFalse);
    await pumpScreen(tester, c, const _Host());
    await tester.pumpAndSettle();

    expect(find.text('Show my business on the I Want USA website'), findsOneWidget);
    expect(find.textContaining('Never your phone number or address'), findsOneWidget);
    final tile = find.byKey(const Key('directoryOptIn'));
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(demo.sellers['demo-seller-0']!.directoryOptIn, isTrue);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(find.textContaining("You're listed"), findsOneWidget);

    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(demo.sellers['demo-seller-0']!.directoryOptIn, isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    await tester.pump(const Duration(seconds: 5));
  });

  test('demo repository: opt-in requires a seller profile', () async {
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    demo.signInAs(demo.demoBuyerId);
    final repo = c.read(sellerRepositoryProvider);
    expect(demo.sellers.containsKey(demo.demoBuyerId), isFalse);
    await expectLater(repo.setDirectoryOptIn(true), throwsStateError);
  });
}
