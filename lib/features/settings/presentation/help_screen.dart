import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final faqs = [
      (l10n.faqQ1, l10n.faqA1),
      (l10n.faqQ2, l10n.faqA2),
      (l10n.faqQ3, l10n.faqA3),
      (l10n.faqQ4, l10n.faqA4),
      (l10n.faqQ5, l10n.faqA5),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(children: [
        for (final (q, a) in faqs)
          ExpansionTile(title: Text(q), children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(a))]),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.support_agent_rounded),
          title: Text(l10n.contactSupport),
          onTap: () => launchUrl(config.legalUrl('contact-support'), mode: LaunchMode.externalApplication),
        ),
      ]),
    );
  }
}
