import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../application/trends_providers.dart';
import '../domain/trends_models.dart';
import 'controls_tab.dart';
import 'trends_widgets.dart';

/// One draft: gate results, review record, the article rendered like the
/// site, the headlines behind it and its decision log.
class TrendDraftScreen extends ConsumerWidget {
  const TrendDraftScreen({super.key, required this.draftId});
  final String draftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final detail = ref.watch(trendDraftDetailProvider(draftId));
    final d = detail.value?.draft;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.trends)),
        title: Text(d?.headline ?? d?.slug ?? l.trendsDraft),
        actions: [
          if (d != null) DraftMenuButton(d, includeOpen: false),
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(trendDraftDetailProvider(draftId)),
          ),
        ],
      ),
      body: AsyncView(
        value: detail,
        onRetry: () => ref.invalidate(trendDraftDetailProvider(draftId)),
        builder: (x) => ListView(padding: const EdgeInsets.all(16), children: [
          _Header(x),
          const SizedBox(height: 12),
          _Gates(x.draft),
          const SizedBox(height: 12),
          if (x.article != null) _Article(TrendArticleView(x.article!)) else _NoArticle(x.draft),
          const SizedBox(height: 12),
          _Signals(x.signals),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.trendsDecisionLog, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (x.log.isEmpty) Text(l.trendsNoLog) else TrendLogList(x.log),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.x);
  final TrendDraftDetail x;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = x.draft;
    final t = Theme.of(context).textTheme;
    Widget row(String k, String? v) => v == null || v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 180, child: Text(k, style: t.bodySmall)),
              Expanded(child: SelectableText(v)),
            ]),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, runSpacing: 4, children: [
            DraftStatusChip(d),
            if (d.sensitive) StatusPill(l.trendsSensitive, icon: Icons.shield_outlined),
            if (d.dirty) StatusPill(l.trendsDirty, icon: Icons.sync),
          ]),
          const SizedBox(height: 8),
          row(l.trendsColPlace, '${d.place ?? '-'} · ${countryLabel(context, d.country)}'),
          row(l.trendsColTopic, x.topic?.title),
          row(l.trendsSlug, d.slug),
          row(l.trendsColVelocity, d.velocity?.round().toString()),
          row(l.trendsSensitiveReasonsLabel, d.sensitiveReasons.join(', ')),
          row(l.trendsFailedGateLabel, [d.failedGate, d.reason].whereType<String>().join(': ')),
          row(l.trendsTopicReviewLabel,
              d.topicReviewedAt == null ? null : l.trendsTopicReviewedBy(d.topicReviewedBy ?? '-', fmtDateTime(d.topicReviewedAt))),
          row(l.trendsContentReviewLabel,
              d.reviewedAt == null ? null : l.trendsReviewedBy(d.reviewerName ?? d.reviewerId ?? '-', fmtDateTime(d.reviewedAt))),
          row(l.note, d.reviewNote),
          row(l.trendsModel, d.model == null ? null : '${d.model} (${l.trendsRewrites(d.rewrites)})'),
          row(l.trendsPublishedLabel, d.publishedAt == null ? null : fmtDateTime(d.publishedAt)),
          row(l.trendsLastUpdateLabel, d.lastUpdateAt == null ? null : fmtDateTime(d.lastUpdateAt)),
          row(l.trendsNoindexLabel, d.noindexReason),
          row(l.trendsSupersededLabel, d.supersededBy),
          row(l.trendsVisitsLabel, d.visits14dAfterEnd?.toString()),
          row(l.trendsStorageLabel, d.storagePath),
        ]),
      ),
    );
  }
}

class _Gates extends StatelessWidget {
  const _Gates(this.d);
  final TrendDraft d;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.trendsGates, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (d.gates.isEmpty) Text(l.trendsNoGates),
          for (final g in d.gates)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                switch (g.passed) {
                  true => Icons.check_circle,
                  false => Icons.cancel,
                  null => Icons.hourglass_empty,
                },
                color: switch (g.passed) {
                  true => s.primary,
                  false => s.error,
                  null => s.outline,
                },
              ),
              title: Text(gateLabel(context, g.key)),
              subtitle: g.summary.isEmpty ? null : Text(g.summary),
            ),
        ]),
      ),
    );
  }
}

class _NoArticle extends StatelessWidget {
  const _NoArticle(this.d);
  final TrendDraft d;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(d.status == DraftStatus.review ? context.l10n.trendsTopicStageHelp : context.l10n.trendsNoArticle),
        ),
      );
}

class _Article extends StatelessWidget {
  const _Article(this.a);
  final TrendArticleView a;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    Widget section(String title, String? body) => body == null || body.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.titleSmall),
              const SizedBox(height: 4),
              Text(body),
            ]),
          );
    final pa = a.perspective('a');
    final pb = a.perspective('b');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.trendsArticle, style: t.labelLarge),
          const SizedBox(height: 8),
          Text(a.headline, style: t.headlineSmall),
          const SizedBox(height: 8),
          for (final line in a.summary) Text('• $line'),
          if (a.framing != null) section(l.trendsFraming, a.framing),
          if (pa != null) section(pa.label, pa.body),
          if (pb != null) section(pb.label, pb.body),
          section(l.trendsWhereAgree, a.agree),
          section(l.trendsLocalAngle, a.localAngle),
          section(l.trendsContext, a.context),
          section(l.trendsWatchNext, a.watchNext),
          if (a.updates.isNotEmpty)
            section(l.trendsUpdates, [for (final u in a.updates) '${fmtDateTime(u.at)}: ${u.text}'].join('\n')),
          if (a.corrections.isNotEmpty)
            section(l.trendsCorrections, [for (final c in a.corrections) '${fmtDateTime(c.at)}: ${c.text}'].join('\n')),
          if (a.sources.isNotEmpty)
            section(l.trendsSourcesSection,
                [for (final s in a.sources) '${s.publisher}${s.title == null ? '' : ': ${s.title}'} (${s.url ?? '-'})'].join('\n')),
          if (a.appLink != null) section(l.trendsAppLink, '${a.appLink!.label} (${a.appLink!.url ?? '-'})'),
          section(l.trendsReviewStamp, a.approvedBy == null ? null : '${a.approvedBy} · ${fmtDateTime(a.approvedAt)}'),
        ]),
      ),
    );
  }
}

class _Signals extends StatelessWidget {
  const _Signals(this.signals);
  final List<TrendSignal> signals;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.trendsSignals(signals.length), style: t.titleMedium),
          const SizedBox(height: 8),
          if (signals.isEmpty) Text(l.trendsNoSignals),
          for (final s in signals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.publisher ?? s.publisherDomain ?? s.sourceKind} · ${s.sourceKind}${s.citable ? '' : ' · ${l.trendsNotCitable}'}'
                    ' · ${fmtDateTime(s.firstSeen)}', style: t.bodySmall),
                Text(s.snippet ?? s.topic),
                if (s.url != null) SelectableText(s.url!, style: t.bodySmall),
              ]),
            ),
        ]),
      ),
    );
  }
}
