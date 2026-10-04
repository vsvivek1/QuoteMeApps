import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../domain/auth_repository.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } on AuthFailure catch (e) {
      if (mounted) {
        context.toast(e.code == 'cancelled' ? context.l10n.authCancelled : context.l10n.authFailed);
      }
    } catch (_) {
      if (mounted) context.toast(context.l10n.authFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(countryConfigProvider);
    final auth = ref.watch(authRepositoryProvider);
    final phoneEnabled = ref.watch(appEnvProvider).phoneAuthEnabled;
    final l10n = context.l10n;
    final showApple = kIsWeb || Platform.isIOS || Platform.isMacOS || Platform.isAndroid;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    config.appName,
                    style: context.text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.welcomeTitle, style: context.text.headlineSmall),
                  const SizedBox(height: 24),
                  for (final (icon, text) in [
                    (Icons.edit_note_rounded, l10n.welcomeBody1),
                    (Icons.storefront_rounded, l10n.welcomeBody2),
                    (Icons.compare_arrows_rounded, l10n.welcomeBody3),
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: context.colors.primaryContainer,
                        child: Icon(icon, color: context.colors.onPrimaryContainer),
                      ),
                      title: Text(text),
                    ),
                  const SizedBox(height: 32),
                  // PHONE_AUTH_ENABLED=false (no SMS provider) leaves Google on top.
                  if (phoneEnabled) ...[
                    FilledButton.icon(
                      onPressed: _busy ? null : () => context.push('/auth/phone'),
                      icon: const Icon(Icons.phone_iphone_rounded),
                      label: Text(l10n.signInPhone),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Google branding: white button, Google "G", "Continue with Google".
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
                    icon: const _GoogleG(),
                    label: Text(l10n.signInGoogle),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => context.push('/auth/email'),
                    icon: const Icon(Icons.mail_outline_rounded),
                    label: Text(l10n.signInEmail),
                  ),
                  if (showApple) ...[
                    const SizedBox(height: 12),
                    // Apple branding: black button, Apple logo, "Sign in with Apple".
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      onPressed: _busy ? null : () => _run(auth.signInWithApple),
                      icon: const Icon(Icons.apple, size: 24),
                      label: Text(l10n.signInApple),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _LegalLine(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF4285F4)),
  );
}

class _LegalLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final full = l10n.signInLegal('\u0001', '\u0002');
    final parts = full.split(RegExp('[\u0001\u0002]'));
    final style = context.text.bodySmall;
    final link = style?.copyWith(color: context.colors.primary, decoration: TextDecoration.underline);
    final termsFirst = full.indexOf('\u0001') < full.indexOf('\u0002');
    final first = termsFirst ? ('terms', l10n.termsLink) : ('privacy', l10n.privacyLink);
    final second = termsFirst ? ('privacy', l10n.privacyLink) : ('terms', l10n.termsLink);
    return Text.rich(
      textAlign: TextAlign.center,
      TextSpan(
        style: style,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: first.$2,
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => context.push('/legal/${first.$1}'),
          ),
          TextSpan(text: parts.length > 1 ? parts[1] : ''),
          TextSpan(
            text: second.$2,
            style: link,
            recognizer: TapGestureRecognizer()..onTap = () => context.push('/legal/${second.$1}'),
          ),
          TextSpan(text: parts.length > 2 ? parts[2] : ''),
        ],
      ),
    );
  }
}
