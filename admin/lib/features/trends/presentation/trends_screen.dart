import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../application/trends_providers.dart';
import '../domain/trends_models.dart';
import 'board_tab.dart';
import 'controls_tab.dart';
import 'lists_tabs.dart';
import 'trends_widgets.dart';

/// Trends news site (Section 21.10): live board by place, fired topics,
/// drafts with gate results, the sensitive-topic review queue and the
/// controls (kill switch, pipeline, Run now, ramp, caps, thresholds, health).
class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final country = ref.watch(trendsCountryFilterProvider);
    final queue = ref.watch(trendReviewQueueProvider).value;
    final settings = ref.watch(trendSettingsProvider).value;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navTrends),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SegmentedButton<TrendsCountry?>(
                key: const ValueKey('trends-country'),
                showSelectedIcon: false,
                segments: [
                  for (final c in <TrendsCountry?>[null, ...TrendsCountry.values])
                    ButtonSegment(value: c, label: Text(countryLabel(context, c))),
                ],
                selected: {country},
                onSelectionChanged: (v) => ref.read(trendsCountryFilterProvider.notifier).set(v.first),
              ),
            ),
            IconButton(
              tooltip: l.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => invalidateTrends(ref),
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l.trendsTabBoard),
            Tab(text: l.trendsTabTopics),
            Tab(text: l.trendsTabDrafts),
            Tab(text: queue == null || queue.isEmpty ? l.trendsTabReview : '${l.trendsTabReview} (${queue.length})'),
            Tab(text: l.trendsTabControls),
          ]),
        ),
        body: Column(children: [
          if (settings != null && settings.publishing.paused) _PausedBanner(settings.publishing),
          const Expanded(child: TabBarView(children: [BoardTab(), TopicsTab(), DraftsTab(), ReviewTab(), ControlsTab()])),
        ]),
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner(this.p);
  final PublishingState p;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final l = context.l10n;
    return Material(
      color: s.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Icon(Icons.pause_circle_outline, color: s.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.trendsPausedBanner(
                p.autoPaused ? l.trendsPausedByAuto : (p.pausedBy ?? '-'),
                p.pausedReason ?? '-',
                fmtDateTime(p.pausedAt),
              ),
              style: TextStyle(color: s.onErrorContainer),
            ),
          ),
        ]),
      ),
    );
  }
}
