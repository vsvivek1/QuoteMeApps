import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/analytics/analytics.dart';
import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../safety/presentation/report_sheet.dart';
import '../domain/review.dart';

final _reviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>(
  (ref, userId) => ref.watch(reviewRepositoryProvider).reviewsFor(userId),
);

class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  int _stars = 0;
  final _tags = <String>{};
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(reviewRepositoryProvider)
        .submitReview(orderId: widget.orderId, stars: _stars, tags: _tags.toList(), text: _text.text.trim());
    await ref.read(analyticsProvider).log(AnalyticsEvent.reviewSubmitted, {'stars': _stars});
    if (!mounted) return;
    context.toast(context.l10n.reviewThanks);
    context.pop();
    if (_stars >= 4) {
      final r = InAppReview.instance;
      if (await r.isAvailable()) await r.requestReview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tags = {
      'on_time': l10n.reviewTagOnTime,
      'good_price': l10n.reviewTagGoodPrice,
      'professional': l10n.reviewTagProfessional,
      'quality': l10n.reviewTagQuality,
      'responsive': l10n.reviewTagResponsive,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewTitle)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 44,
                    tooltip: '$i',
                    onPressed: () => setState(() => _stars = i),
                    icon: Icon(
                      i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in tags.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _tags.contains(e.key),
                    onSelected: (on) => setState(() => on ? _tags.add(e.key) : _tags.remove(e.key)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(hintText: l10n.reviewTextHint),
            ),
            const SizedBox(height: 24),
            BusyButton(label: l10n.reviewSubmit, onPressed: _stars == 0 ? null : _submit),
          ],
        ),
      ),
    );
  }
}

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(authSessionProvider).value?.userId;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewsTitle)),
      body: AsyncView(
        value: ref.watch(_reviewsProvider(userId)),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.reviews_outlined, message: l10n.reviewsEmpty)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RatingStars(rating: r.stars.toDouble()),
                          const SizedBox(width: 8),
                          Expanded(child: Text(r.authorName ?? '', style: context.text.labelLarge)),
                          Text(timeago.format(r.createdAt, locale: context.lang), style: context.text.labelSmall),
                          IconButton(
                            tooltip: l10n.report,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => showReportSheet(context, ref, targetType: 'review', targetId: r.id),
                            icon: const Icon(Icons.flag_outlined, size: 18),
                          ),
                        ],
                      ),
                      if (r.text.isNotEmpty) Text(r.text),
                      if (r.sellerReply != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.reviewSellerReply, style: context.text.labelMedium),
                              Text(r.sellerReply!),
                            ],
                          ),
                        )
                      else if (r.toId == me)
                        TextButton(onPressed: () => _reply(context, ref, r), child: Text(l10n.reviewReply)),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Future<void> _reply(BuildContext context, WidgetRef ref, Review r) async {
    final c = TextEditingController();
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.reviewReply),
        content: TextField(controller: c, maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.send)),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await ref.read(reviewRepositoryProvider).reply(r.id, c.text.trim());
      ref.invalidate(_reviewsProvider(userId));
    }
  }
}
