import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import '../utils/context_x.dart';
import 'router.dart';

class _Dest {
  const _Dest(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String Function(BuildContext) label;
}

final _dests = <_Dest>[
  _Dest(Routes.dashboard, Icons.insights_outlined, (c) => c.l10n.navDashboard),
  _Dest(Routes.verification, Icons.verified_user_outlined, (c) => c.l10n.navVerification),
  _Dest(Routes.sellers, Icons.storefront_outlined, (c) => c.l10n.navSellers),
  _Dest(Routes.moderation, Icons.flag_outlined, (c) => c.l10n.navModeration),
  _Dest(Routes.categories, Icons.category_outlined, (c) => c.l10n.navCategories),
  _Dest(Routes.flags, Icons.toggle_on_outlined, (c) => c.l10n.navFlags),
  _Dest(Routes.outreach, Icons.view_kanban_outlined, (c) => c.l10n.navOutreach),
  _Dest(Routes.brochures, Icons.picture_as_pdf_outlined, (c) => c.l10n.navBrochures),
  _Dest(Routes.seo, Icons.travel_explore_outlined, (c) => c.l10n.navSeo),
  _Dest(Routes.trends, Icons.trending_up, (c) => c.l10n.navTrends),
];

/// Navigation rail + top bar with country, environment and demo badges.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(countryConfigProvider);
    final env = ref.watch(adminEnvProvider);
    final session = ref.watch(adminSessionProvider).value;
    final index = _dests.indexWhere((d) => location.startsWith(d.path));
    final l = context.l10n;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Image.asset(config.logoAsset, height: 28, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const SizedBox(width: 10),
          Flexible(child: Text(l.adminTitle(config.appName), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 12),
          Chip(label: Text(env.env.toUpperCase()), visualDensity: VisualDensity.compact),
          if (env.isDemo) ...[
            const SizedBox(width: 6),
            Chip(
              label: Text(l.demoMode),
              backgroundColor: scheme.tertiaryContainer,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ]),
        actions: [
          if (session != null && wide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(session.email, style: Theme.of(context).textTheme.bodySmall)),
            ),
          IconButton(
            tooltip: l.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(adminAuthRepositoryProvider).signOut(),
          ),
        ],
      ),
      drawer: wide
          ? null
          : NavigationDrawer(
              selectedIndex: index < 0 ? null : index,
              onDestinationSelected: (i) {
                Navigator.pop(context);
                context.go(_dests[i].path);
              },
              children: [
                const SizedBox(height: 16),
                for (final d in _dests) NavigationDrawerDestination(icon: Icon(d.icon), label: Text(d.label(context))),
              ],
            ),
      body: Row(children: [
        if (wide)
          NavigationRail(
            selectedIndex: index < 0 ? null : index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => context.go(_dests[i].path),
            destinations: [
              for (final d in _dests) NavigationRailDestination(icon: Icon(d.icon), label: Text(d.label(context))),
            ],
          ),
        if (wide) const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}
