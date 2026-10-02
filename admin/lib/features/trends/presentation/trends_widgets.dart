import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../application/trends_providers.dart';
import '../domain/trends_models.dart';

String countryLabel(BuildContext context, TrendsCountry? c) => switch (c) {
      TrendsCountry.usa => context.l10n.trendsCountryUsa,
      TrendsCountry.india => context.l10n.trendsCountryIndia,
      null => context.l10n.all,
    };

String topicStatusLabel(BuildContext context, TopicStatus s) {
  final l = context.l10n;
  return switch (s) {
    TopicStatus.watching => l.trendsTopicWatching,
    TopicStatus.fired => l.trendsTopicFired,
    TopicStatus.review => l.trendsTopicReview,
    TopicStatus.drafted => l.trendsTopicDrafted,
    TopicStatus.published => l.trendsTopicPublished,
    TopicStatus.waitingSources => l.trendsTopicWaitingSources,
    TopicStatus.dropped => l.trendsTopicDropped,
    TopicStatus.ended => l.trendsTopicEnded,
  };
}

String draftStatusLabel(BuildContext context, DraftStatus s) {
  final l = context.l10n;
  return switch (s) {
    DraftStatus.queued => l.trendsDraftQueued,
    DraftStatus.review => l.trendsDraftReview,
    DraftStatus.rejected => l.trendsDraftRejected,
    DraftStatus.published => l.trendsDraftPublished,
    DraftStatus.noindex => l.trendsDraftNoindex,
  };
}

String draftActionLabel(BuildContext context, DraftAction a) {
  final l = context.l10n;
  return switch (a) {
    DraftAction.reject => l.trendsActionReject,
    DraftAction.noindex => l.trendsActionNoindex,
    DraftAction.reindex => l.trendsActionIndex,
    DraftAction.unpublish => l.trendsActionUnpublish,
  };
}

String gateLabel(BuildContext context, String key) {
  final l = context.l10n;
  final name = switch (key) {
    'sources' => l.trendsGateSources,
    'sensitive' => l.trendsGateSensitive,
    'originality' => l.trendsGateOriginality,
    'facts' => l.trendsGateFacts,
    'value' => l.trendsGateValue,
    'balance' => l.trendsGateBalance,
    'caps' => l.trendsGateCaps,
    _ => key,
  };
  final n = GateResult.numbers[key];
  return n == null ? name : '$n. $name';
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: icon == null ? null : Icon(icon, size: 16),
        label: Text(label),
        backgroundColor: color,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

class TopicStatusChip extends StatelessWidget {
  const TopicStatusChip(this.status, {super.key});
  final TopicStatus status;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final color = switch (status) {
      TopicStatus.fired || TopicStatus.drafted => s.tertiaryContainer,
      TopicStatus.published => s.primaryContainer,
      TopicStatus.review || TopicStatus.waitingSources => s.secondaryContainer,
      TopicStatus.dropped => s.errorContainer,
      TopicStatus.watching || TopicStatus.ended => s.surfaceContainerHighest,
    };
    return StatusPill(topicStatusLabel(context, status), color: color);
  }
}

class DraftStatusChip extends StatelessWidget {
  const DraftStatusChip(this.draft, {super.key});
  final TrendDraft draft;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final l = context.l10n;
    final color = switch (draft.status) {
      DraftStatus.published => s.primaryContainer,
      DraftStatus.queued => s.tertiaryContainer,
      DraftStatus.review => s.secondaryContainer,
      DraftStatus.rejected => s.errorContainer,
      DraftStatus.noindex => s.surfaceContainerHighest,
    };
    var label = draftStatusLabel(context, draft.status);
    if (draft.status == DraftStatus.queued) {
      label = '$label: ${draft.waitingForCaps ? l.trendsQueuedCaps : l.trendsQueuedDraft}';
    } else if (draft.status == DraftStatus.review) {
      label = '$label: ${draft.effectiveReviewStage == 'topic' ? l.trendsStageTopic : l.trendsStageContent}';
    }
    return StatusPill(label, color: color);
  }
}

/// One chip per gate that ran, in pipeline order: green pass, red fail, grey waiting.
class GateChips extends StatelessWidget {
  const GateChips(this.gates, {super.key});
  final List<GateResult> gates;

  @override
  Widget build(BuildContext context) {
    if (gates.isEmpty) return Text(context.l10n.trendsNoGates, style: Theme.of(context).textTheme.bodySmall);
    final s = Theme.of(context).colorScheme;
    return Wrap(spacing: 4, runSpacing: 4, children: [
      for (final g in gates)
        Tooltip(
          message: g.summary.isEmpty ? gateLabel(context, g.key) : '${gateLabel(context, g.key)}: ${g.summary}',
          child: StatusPill(
            gateLabel(context, g.key),
            icon: switch (g.passed) {
              true => Icons.check_circle_outline,
              false => Icons.cancel_outlined,
              null => Icons.hourglass_empty,
            },
            color: switch (g.passed) {
              true => s.primaryContainer,
              false => s.errorContainer,
              null => s.surfaceContainerHighest,
            },
          ),
        ),
    ]);
  }
}

/// Velocity 0-100 as a short bar plus the number.
class VelocityBar extends StatelessWidget {
  const VelocityBar(this.velocity, {super.key, this.width = 90});
  final double velocity;
  final double width;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final v = velocity.clamp(0, 100) / 100;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v.toDouble(),
            minHeight: 8,
            color: velocity >= 60 ? s.tertiary : s.primary,
            backgroundColor: s.surfaceContainerHighest,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text(velocity.round().toString(), style: Theme.of(context).textTheme.labelMedium),
    ]);
  }
}

/// Friendly text for an error from the trends RPCs / functions.
String trendsErrorText(BuildContext context, Object e) {
  final l = context.l10n;
  if (e is TrendsRateLimited) return l.trendsRateLimited(e.limit, retryMinutes(e.retryAfterSeconds));
  if (e is TrendsException) {
    return switch (e.code) {
      'draft_not_in_review' => l.trendsErrNotInReview,
      'admin_only' => l.trendsErrAdminOnly,
      _ => e.toString(),
    };
  }
  return '$e';
}

void showTrendsError(BuildContext context, Object e) => context.toast(trendsErrorText(context, e), error: true);

/// Draft row actions shared by the drafts list and the detail screen.
enum DraftMenuItem { open, reject, noindex, reindex, unpublish, correction, traffic, supersede }

List<DraftMenuItem> draftMenuItems(TrendDraft d, {bool includeOpen = true}) => [
      if (includeOpen) DraftMenuItem.open,
      for (final a in allowedDraftActions(d)) DraftMenuItem.values.byName(a.name),
      if (d.status == DraftStatus.published || d.status == DraftStatus.noindex) ...[
        DraftMenuItem.correction,
        DraftMenuItem.traffic,
        if (d.supersededBy == null) DraftMenuItem.supersede,
      ],
    ];

String draftMenuLabel(BuildContext context, DraftMenuItem m) {
  final l = context.l10n;
  return switch (m) {
    DraftMenuItem.open => l.trendsOpenDraft,
    DraftMenuItem.reject => draftActionLabel(context, DraftAction.reject),
    DraftMenuItem.noindex => draftActionLabel(context, DraftAction.noindex),
    DraftMenuItem.reindex => draftActionLabel(context, DraftAction.reindex),
    DraftMenuItem.unpublish => draftActionLabel(context, DraftAction.unpublish),
    DraftMenuItem.correction => l.trendsAddCorrection,
    DraftMenuItem.traffic => l.trendsRecordTraffic,
    DraftMenuItem.supersede => l.trendsSupersede,
  };
}

Future<void> runDraftMenuItem(BuildContext context, WidgetRef ref, TrendDraft d, DraftMenuItem m) async {
  final l = context.l10n;
  final repo = ref.read(trendsRepositoryProvider);
  Future<void> run(Future<Object?> Function() f, String done) async {
    try {
      await f();
      invalidateTrends(ref, draftId: d.id);
      ref.invalidate(auditLogProvider);
      if (context.mounted) context.toast(done);
    } catch (e) {
      if (context.mounted) showTrendsError(context, e);
    }
  }

  switch (m) {
    case DraftMenuItem.open:
      context.go(Routes.trendDraft(d.id));
    case DraftMenuItem.reject || DraftMenuItem.noindex || DraftMenuItem.reindex || DraftMenuItem.unpublish:
      final action = DraftAction.values.byName(m.name);
      final reason = await askReason(context,
          title: l.trendsActionTitle(draftActionLabel(context, action), d.headline ?? d.slug ?? d.id),
          hint: l.reason,
          required: action == DraftAction.reject || action == DraftAction.unpublish);
      if (reason == null || !context.mounted) return;
      await run(() => repo.setDraftStatus(d.id, action, reason: reason), l.saved);
    case DraftMenuItem.correction:
      final text = await askReason(context, title: l.trendsAddCorrection, hint: l.trendsCorrectionHint);
      if (text == null || !context.mounted) return;
      if (text.trim().length < 10) {
        context.toast(l.trendsCorrectionTooShort, error: true);
        return;
      }
      await run(() => repo.addCorrection(d.id, text), l.trendsCorrectionAdded);
    case DraftMenuItem.traffic:
      final v = await askReason(context, title: l.trendsRecordTrafficTitle(d.slug ?? ''), hint: l.trendsVisitsHint);
      if (v == null || !context.mounted) return;
      final n = int.tryParse(v.trim());
      if (n == null || n < 0 || d.slug == null) {
        context.toast(l.trendsInvalidNumber, error: true);
        return;
      }
      await run(() => repo.recordTraffic(d.slug!, n), l.saved);
    case DraftMenuItem.supersede:
      final by = await askReason(context, title: l.trendsSupersedeTitle(d.slug ?? ''), hint: l.trendsSupersedeHint);
      if (by == null || !context.mounted || d.slug == null) return;
      await run(() => repo.supersede(d.slug!, by.trim()), l.saved);
  }
}

class DraftMenuButton extends ConsumerWidget {
  const DraftMenuButton(this.draft, {super.key, this.includeOpen = true});
  final TrendDraft draft;
  final bool includeOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = draftMenuItems(draft, includeOpen: includeOpen);
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<DraftMenuItem>(
      tooltip: context.l10n.trendsActions,
      onSelected: (m) => runDraftMenuItem(context, ref, draft, m),
      itemBuilder: (_) => [for (final m in items) PopupMenuItem(value: m, child: Text(draftMenuLabel(context, m)))],
    );
  }
}
