import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/router.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../auth/domain/app_user.dart';
import '../../seller/application/seller_providers.dart';
import '../../seller/presentation/directory_opt_in_tile.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _switch(BuildContext context, WidgetRef ref, AppMode mode) async {
    await ref.read(profileRepositoryProvider).setActiveMode(mode);
    if (context.mounted) context.go(homeFor(mode));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(myProfileProvider).value;
    final mode = ref.watch(appModeProvider);
    final seller = ref.watch(mySellerProvider).value;
    final isSeller = profile?.isSeller ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: MaxWidth(
        child: ListView(
          children: [
            ListTile(
              leading: CircleAvatar(radius: 28, child: Text((profile?.name ?? '?').characters.first.toUpperCase())),
              title: Text(profile?.name ?? '', style: context.text.titleLarge),
              subtitle: Text(profile?.phone ?? profile?.email ?? ''),
              trailing: profile?.phone == null && ref.watch(appEnvProvider).phoneAuthEnabled
                  ? TextButton(onPressed: () => context.push('/auth/link-phone'), child: Text(l10n.addPhoneTitle))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<AppMode>(
                segments: [
                  ButtonSegment(
                    value: AppMode.buyer,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text(l10n.modeBuyer),
                  ),
                  ButtonSegment(
                    value: AppMode.seller,
                    icon: const Icon(Icons.storefront_outlined),
                    label: Text(l10n.modeSeller),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) {
                  if (s.first == AppMode.seller && !isSeller) {
                    context.push('/seller/onboarding');
                  } else {
                    _switch(context, ref, s.first);
                  }
                },
              ),
            ),
            if (!isSeller)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: context.colors.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.storefront_rounded),
                    title: Text(l10n.becomeSeller),
                    subtitle: Text(l10n.becomeSellerBody),
                    onTap: () => context.push('/seller/onboarding'),
                  ),
                ),
              ),
            if (mode == AppMode.seller && seller != null) ...[
              SectionHeader(seller.businessName),
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(l10n.sellerViewPublic),
                onTap: () => context.push('/s/${seller.id}'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.sellerProfileTitle),
                onTap: () => context.push('/seller/onboarding'),
              ),
              DirectoryOptInTile(seller: seller),
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(l10n.verificationTitle),
                trailing: seller.isVerified ? const VerifiedBadge(compact: true) : null,
                onTap: () => context.push('/seller/verification'),
              ),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: Text(l10n.dashboardTitle),
                onTap: () => context.push('/seller/dashboard'),
              ),
              ListTile(
                leading: const Icon(Icons.bookmarks_outlined),
                title: Text(l10n.templatesTitle),
                onTap: () => context.push('/seller/templates'),
              ),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.planTitle),
                onTap: () => context.push('/seller/plan'),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(l10n.ordersTitle),
              onTap: () => context.push('/orders'),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none_rounded),
              title: Text(l10n.notificationsTitle),
              onTap: () => context.push('/notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: Text(l10n.settingsHelp),
              onTap: () => context.push('/help'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settingsTitle),
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
