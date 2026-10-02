import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/shell.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/request_providers.dart';
import 'widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final profile = ref.watch(myProfileProvider).value;
    final requests = ref.watch(myRequestsProvider);
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final top = cats.where((c) => c.parentId == null && !c.isBlocked && c.icon != 'gavel').toList();
    final name = profile?.name?.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: const [NotificationsBell()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myRequestsProvider),
        child: MaxWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  name == null ? l10n.homeGreetingAnon : l10n.homeGreeting(name),
                  style: context.text.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _PostButton(onTap: () => context.push('/post')),
              ),
              SectionHeader(
                l10n.activeRequests,
                trailing: TextButton(onPressed: () => context.go('/requests'), child: Text(l10n.seeAll)),
              ),
              requests.when(
                data: (list) {
                  final active = list.where((r) => r.isOpen).take(3).toList();
                  if (active.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.noActiveRequests, style: context.text.bodyMedium),
                    );
                  }
                  return Column(
                    children: [
                      for (final r in active)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: RequestCard(request: r),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (_, _) => ErrorView(onRetry: () => ref.invalidate(myRequestsProvider)),
              ),
              SectionHeader(l10n.browseCategories),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: top.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final c = top[i];
                    return SizedBox(
                      width: 88,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => context.push('/post?c=${c.id}'),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: context.colors.secondaryContainer,
                              child: Icon(categoryIcon(c.icon), color: context.colors.onSecondaryContainer),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c.name(context.lang),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SectionHeader(l10n.howItWorks),
              for (final (i, t) in [l10n.welcomeBody1, l10n.welcomeBody2, l10n.welcomeBody3].indexed)
                ListTile(
                  leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                  title: Text(t),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  const _PostButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.whatDoYouNeed,
      child: Material(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.whatDoYouNeed,
                        style: context.text.titleLarge?.copyWith(
                          color: context.colors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.whatDoYouNeedHint,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colors.onPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: context.colors.onPrimary,
                  child: Icon(Icons.add_rounded, size: 30, color: context.colors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
