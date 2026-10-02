import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/domain/category.dart';
import '../../safety/presentation/report_sheet.dart';
import '../application/seller_providers.dart';

/// Public seller profile, as buyers see it.
class SellerProfileScreen extends ConsumerWidget {
  const SellerProfileScreen({super.key, required this.sellerId});
  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final seller = ref.watch(sellerByIdProvider(sellerId));
    final me = ref.watch(authSessionProvider).value?.userId;
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};
    return AsyncView(
      value: seller,
      loading: const Scaffold(body: SkeletonList()),
      data: (s) {
        if (s == null) return Scaffold(appBar: AppBar(), body: const ErrorView());
        final isMe = s.id == me;
        final link = config.sellerLink(s.id).toString();
        return Scaffold(
          appBar: AppBar(
            title: Text(isMe ? l10n.sellerProfileTitle : s.businessName),
            actions: [
              IconButton(
                tooltip: l10n.sellerShareShop,
                onPressed: () => SharePlus.instance.share(ShareParams(
                    text: l10n.sellerShareText(s.businessName, config.appName, link))),
                icon: const Icon(Icons.share_outlined),
              ),
              if (isMe)
                IconButton(tooltip: l10n.edit, onPressed: () => context.push('/seller/onboarding'), icon: const Icon(Icons.edit_outlined))
              else
                PopupMenuButton<String>(
                  onSelected: (v) => v == 'report'
                      ? showReportSheet(context, ref, targetType: 'seller', targetId: s.id)
                      : confirmBlock(context, ref, userId: s.id, name: s.businessName),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'report', child: Text(l10n.report)),
                    PopupMenuItem(value: 'block', child: Text(l10n.block)),
                  ],
                ),
            ],
          ),
          body: MaxWidth(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                CircleAvatar(radius: 36, child: Text(s.businessName.characters.first, style: context.text.headlineMedium)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.businessName, style: context.text.titleLarge),
                    if (s.isVerified) const VerifiedBadge(),
                    if (s.ratingCount > 0) RatingStars(rating: s.ratingAvg, count: s.ratingCount),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              if (s.description.isNotEmpty) Text(s.description),
              const SizedBox(height: 12),
              Wrap(spacing: 16, runSpacing: 8, children: [
                if (s.yearsInBusiness != null) Text(l10n.sellerYears(s.yearsInBusiness!)),
                if (s.avgResponseMins != null) Text(l10n.sellerResponds(context.shortDuration(Duration(minutes: s.avgResponseMins!)))),
                if (s.locality != null) Text(s.locality!),
              ]),
              if (s.brands.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final b in s.brands) Chip(label: Text(b))]),
              ],
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final id in s.categoryIds.take(12))
                  if (cats[id] != null) Chip(label: Text(cats[id]!.name(context.lang)), visualDensity: VisualDensity.compact),
              ]),
              const Divider(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.reviews_outlined),
                title: Text(l10n.reviewsTitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/s/${s.id}/reviews'),
              ),
              if (isMe) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(l10n.verificationTitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/seller/verification'),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}
