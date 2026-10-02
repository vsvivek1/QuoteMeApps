import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';

/// Shown instead of the app while `profiles.status` is not `active`.
class AccountBlockedScreen extends ConsumerWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(myProfileProvider).value;
    final config = ref.watch(countryConfigProvider);
    final until = profile?.suspendedUntil;
    final body = switch (profile?.accountStatus) {
      'suspended' when until != null => l10n.accountSuspendedBody(context.date(until)),
      'suspended' => l10n.accountSuspendedBodyNoDate,
      'deleted' => l10n.accountDeletedBody,
      _ => l10n.accountBannedBody,
    };
    return Scaffold(
      body: SafeArea(
        child: MaxWidth(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.block_rounded, size: 56, color: context.colors.error),
                const SizedBox(height: 16),
                Text(l10n.accountBlockedTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
                const SizedBox(height: 12),
                Text(body, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => launchUrl(config.legalUrl('contact-support'), mode: LaunchMode.externalApplication),
                  child: Text(l10n.contactSupport),
                ),
                TextButton(onPressed: () => context.push('/legal'), child: Text(l10n.helpTitle)),
                TextButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: Text(l10n.settingsSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
