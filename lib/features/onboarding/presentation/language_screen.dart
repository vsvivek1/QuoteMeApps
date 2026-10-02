import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';

const _languageNames = {
  'en': 'English',
  'hi': 'हिन्दी',
  'es': 'Español',
};

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key, this.fromSettings = false});
  final bool fromSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(countryConfigProvider);
    final current = ref.watch(localeControllerProvider) ?? Localizations.localeOf(context);
    return Scaffold(
      appBar: fromSettings ? AppBar(title: Text(context.l10n.settingsLanguage)) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (!fromSettings) ...[
              const SizedBox(height: 32),
              Icon(Icons.translate_rounded, size: 48, color: context.colors.primary),
              const SizedBox(height: 16),
              Text(context.l10n.languageTitle, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text(context.l10n.languageSubtitle, style: context.text.bodyMedium),
              const SizedBox(height: 24),
            ],
            RadioGroup<String>(
              groupValue: current.languageCode,
              onChanged: (code) async {
                final locale = config.supportedLocales.firstWhere((l) => l.languageCode == code);
                await ref.read(localeControllerProvider.notifier).set(locale);
                if (!context.mounted) return;
                if (fromSettings) {
                  context.pop();
                } else {
                  context.go('/welcome');
                }
              },
              child: Column(
                children: [
                  for (final l in config.supportedLocales)
                    Card(
                      child: RadioListTile<String>(
                        value: l.languageCode,
                        title: Text(_languageNames[l.languageCode] ?? l.languageCode,
                            style: context.text.titleMedium),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
