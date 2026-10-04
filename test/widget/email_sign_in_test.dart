import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/config/app_env.dart';
import 'package:iwant/core/demo/demo_backend.dart';
import 'package:iwant/core/providers.dart';
import 'package:iwant/country/india/india_config.dart';
import 'package:iwant/features/auth/presentation/email_screen.dart';
import 'package:iwant/features/auth/presentation/welcome_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('email sign-in validates the address, then verifies the 6-digit code', (tester) async {
    final c = await demoContainer(indiaConfig);
    final demo = c.read(backendProvider).demo!;
    await pumpScreen(tester, c, const EmailScreen());

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Asha@Example.com');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('We sent a 6-digit code to asha@example.com'), findsOneWidget);
    expect(find.text('Resend in 30s'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(find.text("That code didn't work. Check it and try again."), findsOneWidget);
    expect(demo.currentUserId, isNull);

    await tester.enterText(find.byType(TextField), DemoBackend.demoOtp);
    await tester.pumpAndSettle();
    expect(demo.currentUserId, isNotNull);
    expect(demo.profiles[demo.currentUserId]!.email, 'asha@example.com');

    // Let the resend timer finish so no timers are pending.
    await tester.pump(const Duration(seconds: 31));
  });

  testWidgets('welcome shows phone, Google and email by default', (tester) async {
    final c = await demoContainer(indiaConfig);
    await pumpScreen(tester, c, const WelcomeScreen());

    expect(find.text('Continue with phone'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
  });

  testWidgets('welcome hides phone sign-in when PHONE_AUTH_ENABLED is false', (tester) async {
    final c = await demoContainer(
      indiaConfig,
      env: const AppEnv(env: Env.prod, forceDemo: true, phoneAuthEnabled: false),
    );
    await pumpScreen(tester, c, const WelcomeScreen());

    expect(find.text('Continue with phone'), findsNothing);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });
}
