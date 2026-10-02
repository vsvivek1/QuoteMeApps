import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/config/country_config.dart';
import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';

final _versionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = ref.watch(themeModeControllerProvider);
    final version = ref.watch(_versionProvider).value ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: MaxWidth(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(l10n.settingsLanguage),
              onTap: () => context.push('/settings/language'),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: Text(l10n.settingsTheme),
              trailing: DropdownButton<ThemeMode>(
                value: theme,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.themeSystem)),
                  DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.themeLight)),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.themeDark)),
                ],
                onChanged: (m) => ref.read(themeModeControllerProvider.notifier).set(m!),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(l10n.settingsNotifications),
              onTap: () => context.push('/settings/notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.settingsPrivacy),
              onTap: () => context.push('/settings/privacy'),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text(l10n.settingsBlocked),
              onTap: () => context.push('/settings/blocked'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: Text(l10n.settingsHelp),
              onTap: () => context.push('/help'),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: Text(l10n.settingsLegal),
              onTap: () => context.push('/legal'),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: Text(l10n.settingsLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: ref.read(countryConfigProvider).appName,
                applicationVersion: version,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(l10n.settingsSignOut),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/welcome');
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: context.colors.error),
              title: Text(l10n.settingsDeleteAccount, style: TextStyle(color: context.colors.error)),
              onTap: () => context.push('/settings/delete-account'),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.settingsVersion(version), style: context.text.bodySmall, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local notification preferences (per-channel consent). Server-side digest
/// settings for sellers live on the business profile.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  bool _get(String k) => _prefs.getBool('notif_$k') ?? k != 'marketing';
  Future<void> _set(String k, bool v) async {
    await _prefs.setBool('notif_$k', v);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = {
      'quotes': l10n.notifPrefNewQuotes,
      'messages': l10n.notifPrefMessages,
      'leads': l10n.notifPrefLeads,
      'marketing': l10n.notifPrefMarketing,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsNotifications)),
      body: ListView(
        children: [
          for (final e in items.entries)
            SwitchListTile(value: _get(e.key), onChanged: (v) => _set(e.key, v), title: Text(e.value)),
        ],
      ),
    );
  }
}

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final analyticsOn = prefs.getBool('analytics_consent') ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPrivacy)),
      body: ListView(
        children: [
          SwitchListTile(
            value: analyticsOn,
            title: Text(l10n.privacyAnalytics),
            onChanged: (v) async {
              await prefs.setBool('analytics_consent', v);
              await ref.read(analyticsProvider).setCollectionEnabled(v);
              setState(() {});
            },
          ),
          if (config.country == Country.usa)
            ListTile(
              leading: const Icon(Icons.do_not_disturb_on_outlined),
              title: Text(l10n.privacyDoNotSell),
              onTap: () => context.push('/legal/ccpa-notice'),
            ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.privacyDownload),
            onTap: () => launchUrl(config.legalUrl('contact-support'), mode: LaunchMode.externalApplication),
          ),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(l10n.privacyLink),
            onTap: () => context.push('/legal/privacy'),
          ),
        ],
      ),
    );
  }
}

class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  late Future<Set<String>> _blocked = ref.read(safetyRepositoryProvider).blockedUserIds();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsBlocked)),
      body: FutureBuilder<Set<String>>(
        future: _blocked,
        builder: (context, snap) {
          final ids = snap.data?.toList() ?? const [];
          if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 2);
          if (ids.isEmpty) return EmptyState(icon: Icons.block_outlined, message: l10n.notificationsEmpty);
          return ListView(
            children: [
              for (final id in ids)
                ListTile(
                  title: Text(id),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(safetyRepositoryProvider).unblock(id);
                      setState(() => _blocked = ref.read(safetyRepositoryProvider).blockedUserIds());
                    },
                    child: Text(l10n.unblock),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
