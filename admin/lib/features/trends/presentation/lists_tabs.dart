import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../application/trends_providers.dart';
import '../domain/trends_models.dart';
import 'trends_widgets.dart';

// Topics ---------------------------------------------------------------------------------------------

/// Topics by status; "fired" = waiting for drafting.
class TopicsTab extends ConsumerStatefulWidget {
  const TopicsTab({super.key});

  @override
  ConsumerState<TopicsTab> createState() => _TopicsTabState();
}

class _TopicsTabState extends ConsumerState<TopicsTab> {
  TopicStatus? _status = TopicStatus.fired;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final topics = ref.watch(trendTopicsProvider(_status));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in <TopicStatus?>[...TopicStatus.values, null])
          ChoiceChip(
            label: Text(s == null ? l.all : topicStatusLabel(context, s)),
            selected: _status == s,
            onSelected: (_) => setState(() => _status = s),
          ),
      ]),
      const SizedBox(height: 8),
      if (_status == TopicStatus.fired) Text(l.trendsFiredHelp, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      AsyncView(
        value: topics,
        onRetry: () => ref.invalidate(trendTopicsProvider(_status)),
        builder: (rows) => rows.isEmpty
            ? Padding(padding: const EdgeInsets.all(24), child: EmptyState(l.trendsNoTopics))
            : Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l.trendsColTopic)),
                      DataColumn(label: Text(l.trendsColPlace)),
                      DataColumn(label: Text(l.trendsColStatus)),
                      DataColumn(label: Text(l.trendsColVelocity)),
                      DataColumn(label: Text(l.trendsColSignals), numeric: true),
                      DataColumn(label: Text(l.trendsColDomains)),
                      DataColumn(label: Text(l.trendsColFired)),
                      DataColumn(label: Text(l.trendsColReason)),
                    ],
                    rows: [
                      for (final t in rows)
                        DataRow(cells: [
                          DataCell(Text(t.title)),
                          DataCell(Text('${t.placeName ?? t.placeSlug ?? '-'} · ${countryLabel(context, t.country)}')),
                          DataCell(TopicStatusChip(t.status)),
                          DataCell(VelocityBar(t.velocity, width: 60)),
                          DataCell(Text('${t.signalCount}')),
                          DataCell(ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 280),
                            child: Text(t.domains.join(', '), style: Theme.of(context).textTheme.bodySmall),
                          )),
                          DataCell(Text(fmtDateTime(t.firedAt))),
                          DataCell(Text(t.statusReason ?? '-')),
                        ]),
                    ],
                  ),
                ),
              ),
      ),
    ]);
  }
}

// Drafts ---------------------------------------------------------------------------------------------

/// Published / queued / review / rejected / noindex lists with the gate chips.
class DraftsTab extends ConsumerStatefulWidget {
  const DraftsTab({super.key});

  @override
  ConsumerState<DraftsTab> createState() => _DraftsTabState();
}

class _DraftsTabState extends ConsumerState<DraftsTab> {
  DraftStatus? _status = DraftStatus.published;
  static const _order = [DraftStatus.published, DraftStatus.queued, DraftStatus.review, DraftStatus.rejected, DraftStatus.noindex];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final drafts = ref.watch(trendDraftsProvider(_status));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final s in <DraftStatus?>[..._order, null])
          ChoiceChip(
            label: Text(s == null ? l.all : draftStatusLabel(context, s)),
            selected: _status == s,
            onSelected: (_) => setState(() => _status = s),
          ),
      ]),
      const SizedBox(height: 12),
      AsyncView(
        value: drafts,
        onRetry: () => ref.invalidate(trendDraftsProvider(_status)),
        builder: (rows) => rows.isEmpty
            ? Padding(padding: const EdgeInsets.all(24), child: EmptyState(l.trendsNoDrafts))
            : Column(children: [for (final d in rows) DraftCard(d)]),
      ),
    ]);
  }
}

class DraftCard extends StatelessWidget {
  const DraftCard(this.d, {super.key, this.trailing});
  final TrendDraft d;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final meta = [
      '${d.place ?? d.placeSlug ?? '-'} · ${countryLabel(context, d.country)}',
      if (d.velocity != null) l.trendsVelocity(d.velocity!.round()),
      if (d.publishedAt != null) l.trendsPublishedAt(fmtDateTime(d.publishedAt))
      else l.trendsCreatedAt(fmtDateTime(d.createdAt)),
      if (d.slug != null) '/${d.slug}',
      if (d.visits14dAfterEnd != null) l.trendsVisits(d.visits14dAfterEnd!),
      if (d.model != null) d.model!,
    ];
    return Card(
      child: InkWell(
        onTap: () => context.go(Routes.trendDraft(d.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(d.headline ?? d.slug ?? d.id, style: t.titleMedium),
                  DraftStatusChip(d),
                  if (d.sensitive) StatusPill(l.trendsSensitive, icon: Icons.shield_outlined),
                  if (d.dirty) StatusPill(l.trendsDirty, icon: Icons.sync),
                ]),
                const SizedBox(height: 4),
                Text(meta.join('  ·  '), style: t.bodySmall),
                const SizedBox(height: 8),
                GateChips(d.gates),
                if (d.failedGate != null || d.reason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    [if (d.failedGate != null) l.trendsFailedGate(d.failedGate!), if (d.reason != null) d.reason!].join(': '),
                    style: t.bodySmall?.copyWith(
                        color: d.status == DraftStatus.rejected ? Theme.of(context).colorScheme.error : null),
                  ),
                ],
                if (d.noindexReason != null) Text(l.trendsNoindexReason(d.noindexReason!), style: t.bodySmall),
                if (d.reviewedAt != null || d.topicReviewedAt != null)
                  Text(
                    [
                      if (d.topicReviewedAt != null) l.trendsTopicReviewedBy(d.topicReviewedBy ?? '-', fmtDateTime(d.topicReviewedAt)),
                      if (d.reviewedAt != null) l.trendsReviewedBy(d.reviewerName ?? d.reviewerId ?? '-', fmtDateTime(d.reviewedAt)),
                    ].join('  ·  '),
                    style: t.bodySmall,
                  ),
              ]),
            ),
            trailing ?? DraftMenuButton(d),
          ]),
        ),
      ),
    );
  }
}

// Review queue --------------------------------------------------------------------------------------

/// Sensitive topics: stage `topic` (nothing drafted yet) or `content` (finished text).
class ReviewTab extends ConsumerWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(trendReviewQueueProvider);
    return AsyncView(
      value: queue,
      onRetry: () => ref.invalidate(trendReviewQueueProvider),
      builder: (items) => ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.trendsReviewHelp, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: EmptyState(l.trendsReviewEmpty, icon: Icons.task_alt))
        else
          for (final d in items) _ReviewCard(d),
      ]),
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard(this.d);
  final TrendDraft d;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  bool _busy = false;

  Future<void> _decide(bool approve) async {
    final l = context.l10n;
    final d = widget.d;
    final topicStage = d.effectiveReviewStage == 'topic';
    final note = await askReason(
      context,
      title: approve
          ? (topicStage ? l.trendsApproveTopicTitle : l.trendsApproveContentTitle)
          : (topicStage ? l.trendsRejectTopicTitle : l.trendsRejectContentTitle),
      hint: l.trendsReviewNoteHint,
      required: !approve,
    );
    if (note == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(trendsRepositoryProvider).review(d.id, approve: approve, note: note);
      invalidateTrends(ref, draftId: d.id);
      ref.invalidate(auditLogProvider);
      if (mounted) context.toast(approve ? l.trendsApproved : l.trendsRejected);
    } on TrendsException catch (e) {
      if (!mounted) return;
      showTrendsError(context, e);
      if (e.code == 'draft_not_in_review') invalidateTrends(ref);
    } catch (e) {
      if (mounted) showTrendsError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = widget.d;
    final t = Theme.of(context).textTheme;
    final topicStage = d.effectiveReviewStage == 'topic';
    final article = d.article == null ? null : TrendArticleView(d.article!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(d.headline ?? d.id, style: t.titleMedium),
            StatusPill(topicStage ? l.trendsStageTopic : l.trendsStageContent, icon: Icons.shield_outlined),
            Text('${d.place ?? '-'} · ${countryLabel(context, d.country)} · ${l.trendsWaitingSince(fmtDateTime(d.createdAt))}',
                style: t.bodySmall),
          ]),
          const SizedBox(height: 6),
          Text(l.trendsSensitiveReasons(d.sensitiveReasons.isEmpty ? '-' : d.sensitiveReasons.join(', ')), style: t.bodyMedium),
          const SizedBox(height: 6),
          Text(topicStage ? l.trendsTopicStageHelp : l.trendsContentStageHelp, style: t.bodySmall),
          const SizedBox(height: 8),
          GateChips(d.gates),
          if (article != null) ...[
            const SizedBox(height: 8),
            for (final line in article.summary) Text('• $line'),
          ],
          if (d.topicReviewedAt != null)
            Text(l.trendsTopicReviewedBy(d.topicReviewedBy ?? '-', fmtDateTime(d.topicReviewedAt)), style: t.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.trendDraft(d.id)),
              icon: const Icon(Icons.article_outlined),
              label: Text(topicStage ? l.trendsShowHeadlines : l.trendsReadArticle),
            ),
            FilledButton.icon(
              key: ValueKey('trends-approve-${d.id}'),
              onPressed: _busy ? null : () => _decide(true),
              icon: const Icon(Icons.check),
              label: Text(topicStage ? l.trendsApproveTopic : l.trendsApproveContent),
            ),
            OutlinedButton.icon(
              key: ValueKey('trends-reject-${d.id}'),
              onPressed: _busy ? null : () => _decide(false),
              icon: const Icon(Icons.close),
              label: Text(l.reject),
            ),
          ]),
        ]),
      ),
    );
  }
}
