import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../application/settings_providers.dart';
import '../domain/settings_models.dart';

/// Monetization switch, early-partner date, outreach flag and every other
/// remote flag / limit in `app_settings` for this country project.
class FlagsScreen extends ConsumerWidget {
  const FlagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navFlags),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(appSettingsProvider),
          ),
        ],
      ),
      body: AsyncView(
        value: ref.watch(appSettingsProvider),
        onRetry: () => ref.invalidate(appSettingsProvider),
        builder: (settings) {
          final byKey = {for (final s in settings) s.key: s};
          final others = settings
              .where((s) => !const {'monetization_enabled', 'early_partner_free_until', 'outreach_enabled'}.contains(s.key))
              .toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            _MonetizationCard(
              enabled: byKey['monetization_enabled']?.value == true,
              freeUntil: DateTime.tryParse('${byKey['early_partner_free_until']?.value ?? ''}'),
            ),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                title: Text(l.outreachFlag),
                subtitle: Text(l.outreachFlagHelp),
                value: byKey['outreach_enabled']?.value == true,
                onChanged: (v) => _save(context, ref, 'outreach_enabled', v),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.remoteFlags, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.remoteFlagsHelp, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                for (final s in others) ...[_SettingTile(s), const Divider(height: 1)],
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

Future<void> _save(BuildContext context, WidgetRef ref, String key, Object? value) async {
  final l = context.l10n;
  try {
    await ref.read(settingsRepositoryProvider).set(key, value);
    ref
      ..invalidate(appSettingsProvider)
      ..invalidate(auditLogProvider);
    if (context.mounted) context.toast(l.saved);
  } catch (e) {
    if (context.mounted) context.toast('$e', error: true);
  }
}

class _MonetizationCard extends ConsumerWidget {
  const _MonetizationCard({required this.enabled, required this.freeUntil});
  final bool enabled;
  final DateTime? freeUntil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.monetizationTitle, style: Theme.of(context).textTheme.titleMedium)),
            Switch(
              value: enabled,
              onChanged: (v) async {
                final ok = await confirmDialog(
                  context,
                  title: v ? l.monetizationOnTitle : l.monetizationOffTitle,
                  body: v ? l.monetizationOnBody(fmtDate(freeUntil)) : l.monetizationOffBody,
                );
                if (ok && context.mounted) await _save(context, ref, 'monetization_enabled', v);
              },
            ),
          ]),
          Text(enabled ? l.monetizationOn : l.monetizationOff),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text('${l.earlyPartnerUntil}: ${freeUntil == null ? l.notSetYet : fmtDate(freeUntil)}')),
            OutlinedButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365 * 3)),
                  initialDate: freeUntil ?? now.add(const Duration(days: 182)),
                );
                if (picked != null && context.mounted) {
                  await _save(context, ref, 'early_partner_free_until', picked.toUtc().toIso8601String());
                }
              },
              child: Text(l.changeDate),
            ),
          ]),
          const SizedBox(height: 4),
          Text(l.earlyPartnerHelp, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _SettingTile extends ConsumerWidget {
  const _SettingTile(this.s);
  final AppSetting s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final v = s.value;
    final subtitle = [s.description ?? '', if (s.isPublic) l.publicFlag].where((e) => e.isNotEmpty).join(' · ');
    if (v is bool) {
      return SwitchListTile(
        title: Text(s.key),
        subtitle: Text(subtitle),
        value: v,
        onChanged: (nv) => _save(context, ref, s.key, nv),
      );
    }
    return ListTile(
      title: Text(s.key),
      subtitle: Text(subtitle),
      trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(v == null ? '-' : '$v', style: Theme.of(context).textTheme.titleSmall),
        IconButton(
          tooltip: l.edit,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final text = await askReason(context, title: s.key, hint: v == null ? '' : '$v');
            if (text == null || !context.mounted) return;
            final Object? parsed = v is num ? num.tryParse(text) : (text == 'null' ? null : text);
            if (v is num && parsed == null) {
              context.toast(l.invalidNumber, error: true);
              return;
            }
            await _save(context, ref, s.key, parsed);
          },
        ),
      ]),
    );
  }
}
