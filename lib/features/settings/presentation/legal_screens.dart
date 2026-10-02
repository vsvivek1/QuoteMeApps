import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';

class LegalPage {
  const LegalPage({
    required this.slug,
    required this.title,
    required this.version,
    required this.lastUpdated,
    required this.markdown,
  });
  final String slug;
  final String title;
  final String version;
  final String lastUpdated;
  final String markdown;
}

/// Legal pages bundled from `legal/<country>/` (built by legal/build.py into
/// `assets/legal/<country>/legal.json`). The same pages are hosted on the web.
final legalPagesProvider = FutureProvider<List<LegalPage>>((ref) async {
  final country = ref.watch(countryConfigProvider).country.name;
  try {
    final raw = await rootBundle.loadString('assets/legal/$country/legal.json');
    final list = jsonDecode(raw) as List;
    return [
      for (final p in list)
        LegalPage(
          slug: p['slug'] as String,
          title: p['title'] as String,
          version: '${p['version'] ?? ''}',
          lastUpdated: '${p['last_updated'] ?? ''}',
          markdown: p['markdown'] as String,
        ),
    ];
  } catch (_) {
    return const [];
  }
});

class LegalIndexScreen extends ConsumerWidget {
  const LegalIndexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalTitle)),
      body: AsyncView(
        value: ref.watch(legalPagesProvider),
        data: (pages) => ListView(
          children: [
            for (final p in pages)
              ListTile(
                title: Text(p.title),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/legal/${p.slug}'),
              ),
            ListTile(
              title: Text(l10n.settingsLicenses),
              onTap: () => showLicensePage(context: context, applicationName: ref.read(countryConfigProvider).appName),
            ),
          ],
        ),
      ),
    );
  }
}

class LegalPageScreen extends ConsumerWidget {
  const LegalPageScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(countryConfigProvider);
    return AsyncView(
      value: ref.watch(legalPagesProvider),
      loading: const Scaffold(body: SkeletonList()),
      data: (pages) {
        final page = pages.where((p) => p.slug == slug).firstOrNull;
        if (page == null) {
          // Not bundled: open the hosted version.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            launchUrl(config.legalUrl(slug), mode: LaunchMode.inAppBrowserView);
            if (context.mounted && context.canPop()) context.pop();
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(title: Text(page.title)),
          body: Markdown(
            data: page.markdown,
            selectable: true,
            onTapLink: (_, href, _) {
              if (href == null) return;
              final uri = Uri.parse(href);
              if (uri.path.startsWith('/legal/')) {
                context.push(uri.path);
              } else {
                launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        );
      },
    );
  }
}
