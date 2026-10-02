import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../application/trends_providers.dart';
import '../domain/trends_models.dart';
import 'setting_editor_dialog.dart';
import 'trends_widgets.dart';

/// Kill switch, pipeline switch, Run now, ramp per country, health inputs,
/// caps / thresholds editor and the decision log.
class ControlsTab extends ConsumerWidget {
  const ControlsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(trendSettingsProvider);
    return AsyncView(
      value: settings,
      onRetry: () => ref.invalidate(trendSettingsProvider),
      builder: (s) => ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          SizedBox(width: 520, child: _KillSwitchCard(s.publishing)),
          SizedBox(width: 520, child: _PipelineCard(s.pipelineEnabled)),
        ]),
        const SizedBox(height: 12),
        _RunNowCard(s),
        const SizedBox(height: 12),
        _RampCard(s),
        const SizedBox(height: 12),
        _HealthCard(s),
        const SizedBox(height: 12),
        _SettingsCard(s),
        const SizedBox(height: 12),
        const _LogCard(),
      ]),
    );
  }
}

void _afterChange(WidgetRef ref) {
  invalidateTrends(ref);
  ref.invalidate(auditLogProvider);
}

/// Confirmation with an optional or required reason; returns null when cancelled.
Future<String?> confirmWithReason(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool reasonRequired = false,
  bool destructive = false,
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _ReasonConfirmDialog(
        title: title,
        body: body,
        action: action,
        reasonRequired: reasonRequired,
        destructive: destructive,
      ),
    );

class _ReasonConfirmDialog extends StatefulWidget {
  const _ReasonConfirmDialog({
    required this.title,
    required this.body,
    required this.action,
    required this.reasonRequired,
    required this.destructive,
  });
  final String title;
  final String body;
  final String action;
  final bool reasonRequired;
  final bool destructive;

  @override
  State<_ReasonConfirmDialog> createState() => _ReasonConfirmDialogState();
}

class _ReasonConfirmDialogState extends State<_ReasonConfirmDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.body),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('trends-confirm-reason'),
            controller: _ctrl,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.reason, helperText: widget.reasonRequired ? null : l.trendsOptional),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          style: widget.destructive ? FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error) : null,
          onPressed: widget.reasonRequired && _ctrl.text.trim().isEmpty ? null : () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing, this.color});
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ?trailing,
            ]),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );
}

// Kill switch ----------------------------------------------------------------------------------------

class _KillSwitchCard extends ConsumerWidget {
  const _KillSwitchCard(this.p);
  final PublishingState p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = Theme.of(context).colorScheme;
    return _Section(
      title: l.trendsKillSwitch,
      color: p.paused ? s.errorContainer : null,
      trailing: p.paused
          ? FilledButton.icon(
              key: const ValueKey('trends-resume'),
              onPressed: () => _set(context, ref, false),
              icon: const Icon(Icons.play_arrow),
              label: Text(l.trendsResume),
            )
          : FilledButton.icon(
              key: const ValueKey('trends-pause'),
              style: FilledButton.styleFrom(backgroundColor: s.error, foregroundColor: s.onError),
              onPressed: () => _set(context, ref, true),
              icon: const Icon(Icons.pause),
              label: Text(l.trendsPause),
            ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.paused ? l.trendsPausedNow : l.trendsRunningNow, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (p.paused)
          Text(l.trendsPausedDetail(p.autoPaused ? l.trendsPausedByAuto : (p.pausedBy ?? '-'), p.pausedReason ?? '-',
              fmtDateTime(p.pausedAt)))
        else if (p.resumedBy != null)
          Text(l.trendsResumedDetail(p.resumedBy!, p.resumedReason ?? '-')),
        const SizedBox(height: 4),
        Text(l.trendsKillSwitchHelp, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }

  Future<void> _set(BuildContext context, WidgetRef ref, bool paused) async {
    final l = context.l10n;
    final reason = await confirmWithReason(
      context,
      title: paused ? l.trendsPauseTitle : l.trendsResumeTitle,
      body: paused ? l.trendsPauseBody : l.trendsResumeBody,
      action: paused ? l.trendsPause : l.trendsResume,
      reasonRequired: paused,
      destructive: paused,
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(trendsRepositoryProvider).setKillSwitch(paused: paused, reason: reason);
      _afterChange(ref);
      if (context.mounted) context.toast(paused ? l.trendsPausedToast : l.trendsResumedToast);
    } catch (e) {
      if (context.mounted) showTrendsError(context, e);
    }
  }
}

// Pipeline switch -------------------------------------------------------------------------------------

class _PipelineCard extends ConsumerWidget {
  const _PipelineCard(this.enabled);
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return _Section(
      title: l.trendsPipeline,
      trailing: Switch(
        key: const ValueKey('trends-pipeline-switch'),
        value: enabled,
        onChanged: (v) async {
          final reason = await confirmWithReason(
            context,
            title: v ? l.trendsPipelineOnTitle : l.trendsPipelineOffTitle,
            body: v ? l.trendsPipelineOnBody : l.trendsPipelineOffBody,
            action: v ? l.trendsPipelineOn : l.trendsPipelineOff,
          );
          if (reason == null || !context.mounted) return;
          try {
            await ref.read(trendsRepositoryProvider).setSetting('pipeline', {'enabled': v});
            _afterChange(ref);
          } catch (e) {
            if (context.mounted) showTrendsError(context, e);
          }
        },
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(enabled ? l.trendsPipelineEnabled : l.trendsPipelineDisabled, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l.trendsPipelineHelp, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

// Run now ---------------------------------------------------------------------------------------------

class _RunNowCard extends ConsumerStatefulWidget {
  const _RunNowCard(this.s);
  final TrendSettingsSnapshot s;

  @override
  ConsumerState<_RunNowCard> createState() => _RunNowCardState();
}

class _RunNowCardState extends ConsumerState<_RunNowCard> {
  TrendsFunction? _running;

  String _desc(TrendsFunction f) => switch (f) {
        TrendsFunction.poll => context.l10n.trendsRunPollHelp,
        TrendsFunction.draft => context.l10n.trendsRunDraftHelp,
        TrendsFunction.publish => context.l10n.trendsRunPublishHelp,
      };

  Future<void> _run(TrendsFunction f) async {
    final l = context.l10n;
    final ok = await confirmDialog(context, title: l.trendsRunNowTitle(f.fnName), body: _desc(f), action: l.trendsRunNow);
    if (!ok || !mounted) return;
    setState(() => _running = f);
    try {
      final r = await ref.read(trendsRepositoryProvider).runNow(f);
      _afterChange(ref);
      if (!mounted) return;
      final stats = r.statsSummary.isEmpty ? '-' : r.statsSummary;
      context.toast(r.dryRun ? l.trendsRunDryRun(f.fnName, r.reason ?? '-', stats) : l.trendsRunDone(f.fnName, stats));
    } catch (e) {
      if (mounted) showTrendsError(context, e);
      _afterChange(ref);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return _Section(
      title: l.trendsRunNowSection,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.trendsRunNowHelp, style: t.bodySmall),
        const SizedBox(height: 8),
        for (final f in TrendsFunction.values) ...[
          Builder(builder: (context) {
            final run = widget.s.runs[f.fnName];
            final usage = widget.s.runNowFor(f);
            final exhausted = usage.remaining <= 0;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(f.fnName),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_desc(f), style: t.bodySmall),
                Text(
                  run == null
                      ? l.trendsNoRunYet
                      : l.trendsLastRun(
                          fmtDateTime(run.finishedAt ?? run.startedAt),
                          run.trigger ?? '-',
                          run.ok == null ? l.trendsRunning : (run.ok! ? (run.dryRun ? l.trendsDryRun : 'ok') : (run.error ?? 'error')),
                          RunNowResult(ok: true, stats: run.stats).statsSummary,
                        ),
                  style: t.bodySmall?.copyWith(color: run?.ok == false ? Theme.of(context).colorScheme.error : null),
                ),
                Text(
                  exhausted
                      ? l.trendsRunNowExhausted(usage.limit, retryMinutes(usage.retryAfterSeconds))
                      : l.trendsRunNowLeft(usage.remaining, usage.limit),
                  style: t.bodySmall,
                ),
              ]),
              trailing: FilledButton.tonalIcon(
                key: ValueKey('trends-run-${f.name}'),
                onPressed: _running != null || exhausted ? null : () => _run(f),
                icon: _running == f
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_circle_outline),
                label: Text(l.trendsRunNow),
              ),
            );
          }),
          if (f != TrendsFunction.values.last) const Divider(height: 1),
        ],
      ]),
    );
  }
}

// Ramp ------------------------------------------------------------------------------------------------

class _RampCard extends ConsumerWidget {
  const _RampCard(this.s);
  final TrendSettingsSnapshot s;

  String _blocker(BuildContext context, String code, TrendsCountry c) {
    final l = context.l10n;
    return switch (code) {
      'top_level' => l.trendsRampTop,
      'ramp_step_too_soon' => l.trendsRampTooSoon(s.minDaysBetweenSteps),
      'ramp_unhealthy' => l.trendsRampUnhealthy(healthProblemLabel(context, s.healthProblems[c])),
      _ => code,
    };
  }

  Future<void> _step(BuildContext context, WidgetRef ref, TrendsCountry c, int to) async {
    final l = context.l10n;
    final up = to > s.rampLevel(c);
    final levels = s.rampLevels;
    final reason = await confirmWithReason(
      context,
      title: up ? l.trendsRampUpTitle(countryLabel(context, c)) : l.trendsRampDownTitle(countryLabel(context, c)),
      body: l.trendsRampBody(levels[s.rampLevel(c)], levels[to]),
      action: up ? l.trendsRampUp : l.trendsRampDown,
    );
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(trendsRepositoryProvider).setRamp(c, to, reason: reason);
      _afterChange(ref);
      if (context.mounted) context.toast(l.saved);
    } catch (e) {
      if (context.mounted) showTrendsError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();
    return _Section(
      title: l.trendsRamp,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.trendsRampHelp(s.rampLevels.join(' → '), s.minDaysBetweenSteps), style: t.bodySmall),
        const SizedBox(height: 8),
        for (final c in TrendsCountry.values)
          Builder(builder: (context) {
            final level = s.rampLevel(c);
            final blocker = s.rampStepUpBlocker(c, now);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${countryLabel(context, c)}: ${l.trendsPerDay(s.perDay[c] ?? 1)}'),
              subtitle: Text([
                l.trendsRampLevel(level + 1, s.rampLevels.length),
                l.trendsPublished24h(s.published24h[c] ?? 0),
                l.trendsRampChanged(fmtDate(s.rampChangedAt(c))),
                if (blocker != null) _blocker(context, blocker, c),
              ].join('  ·  ')),
              trailing: Wrap(spacing: 8, children: [
                OutlinedButton(
                  key: ValueKey('trends-ramp-down-${c.name}'),
                  onPressed: level > 0 ? () => _step(context, ref, c, level - 1) : null,
                  child: Text(l.trendsRampDown),
                ),
                Tooltip(
                  message: blocker == null ? '' : _blocker(context, blocker, c),
                  child: FilledButton.tonal(
                    key: ValueKey('trends-ramp-up-${c.name}'),
                    onPressed: blocker == null ? () => _step(context, ref, c, level + 1) : null,
                    child: Text(l.trendsRampUp),
                  ),
                ),
              ]),
            );
          }),
        Text(l.trendsSiteCeiling, style: t.bodySmall),
      ]),
    );
  }
}

String healthProblemLabel(BuildContext context, String? code) {
  final l = context.l10n;
  return switch (code) {
    null => l.trendsHealthy,
    'no_recent_health' => l.trendsProblemNoRecent,
    'manual_action' => l.trendsProblemManualAction,
    'error_reports' => l.trendsProblemErrorReports,
    'search_console_warnings' => l.trendsProblemScWarnings,
    'low_indexed_share' => l.trendsProblemLowIndexed,
    'traffic_drop' => l.trendsProblemTrafficDrop,
    _ => code,
  };
}

// Health ------------------------------------------------------------------------------------------------

class _HealthCard extends ConsumerWidget {
  const _HealthCard(this.s);
  final TrendSettingsSnapshot s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return _Section(
      title: l.trendsHealth,
      trailing: Wrap(spacing: 8, children: [
        OutlinedButton.icon(
          key: const ValueKey('trends-record-traffic'),
          onPressed: () async {
            final r = await showDialog<(String, int)>(context: context, builder: (_) => const TrafficDialog());
            if (r == null || !context.mounted) return;
            try {
              await ref.read(trendsRepositoryProvider).recordTraffic(r.$1, r.$2);
              _afterChange(ref);
              if (context.mounted) context.toast(l.saved);
            } catch (e) {
              if (context.mounted) showTrendsError(context, e);
            }
          },
          icon: const Icon(Icons.bar_chart),
          label: Text(l.trendsRecordTraffic),
        ),
        FilledButton.icon(
          key: const ValueKey('trends-record-health'),
          onPressed: () async {
            final input = await showDialog<HealthInput>(context: context, builder: (_) => const HealthDialog());
            if (input == null || !context.mounted) return;
            try {
              final r = await ref.read(trendsRepositoryProvider).recordHealth(input);
              _afterChange(ref);
              if (!context.mounted) return;
              context.toast(
                r.autoPause != null
                    ? l.trendsHealthAutoPaused(r.autoPause!)
                    : l.trendsHealthRecorded(healthProblemLabel(context, r.healthProblem)),
                error: r.autoPause != null,
              );
            } catch (e) {
              if (context.mounted) showTrendsError(context, e);
            }
          },
          icon: const Icon(Icons.add_chart),
          label: Text(l.trendsRecordHealth),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.trendsHealthHelp, style: t.bodySmall),
        const SizedBox(height: 8),
        for (final c in TrendsCountry.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Builder(builder: (context) {
              final h = s.health[c];
              final problem = s.healthProblems[c];
              return Text.rich(TextSpan(children: [
                TextSpan(text: '${countryLabel(context, c)}: ', style: t.titleSmall),
                TextSpan(
                  text: healthProblemLabel(context, problem),
                  style: TextStyle(color: problem == null ? null : Theme.of(context).colorScheme.error),
                ),
                if (h != null)
                  TextSpan(
                    text: '  ·  ${l.trendsHealthLatest(
                      fmtDateTime(h.recordedAt),
                      h.indexedShare == null ? 'n/a' : fmtPct(h.indexedShare! * 100),
                      fmtInt(h.clicks7d),
                      fmtInt(h.clicksPrev7d),
                      h.scWarnings,
                      h.errorReports24h,
                    )}${h.manualAction ? '  ·  ${l.trendsManualAction}' : ''}',
                    style: t.bodySmall,
                  ),
              ]));
            }),
          ),
      ]),
    );
  }
}

/// Weekly Search Console / analytics snapshot (`admin_trends_record_health`).
class HealthDialog extends StatefulWidget {
  const HealthDialog({super.key});

  @override
  State<HealthDialog> createState() => _HealthDialogState();
}

class _HealthDialogState extends State<HealthDialog> {
  var _country = TrendsCountry.india;
  final _share = TextEditingController();
  final _clicks = TextEditingController();
  final _prev = TextEditingController();
  final _warnings = TextEditingController(text: '0');
  final _errors = TextEditingController(text: '0');
  final _note = TextEditingController();
  bool _manual = false;

  @override
  void dispose() {
    for (final c in [_share, _clicks, _prev, _warnings, _errors, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  HealthInput? get _input {
    final share = double.tryParse(_share.text.trim().replaceAll('%', ''));
    final clicks = int.tryParse(_clicks.text.trim());
    final prev = int.tryParse(_prev.text.trim());
    final warnings = int.tryParse(_warnings.text.trim());
    final errors = int.tryParse(_errors.text.trim());
    if (share == null || clicks == null || prev == null || warnings == null || errors == null) return null;
    return HealthInput(
      country: _country,
      indexedShare: share / 100,
      clicks7d: clicks,
      clicksPrev7d: prev,
      scWarnings: warnings,
      manualAction: _manual,
      errorReports24h: errors,
      note: _note.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final input = _input;
    final err = input == null ? l.trendsHealthIncomplete : input.validate();
    Widget num(TextEditingController c, String label, String key, {String? helper}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            key: ValueKey('trends-health-$key'),
            controller: c,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: label, helperText: helper),
          ),
        );
    return AlertDialog(
      title: Text(l.trendsRecordHealth),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<TrendsCountry>(
              initialValue: _country,
              decoration: InputDecoration(labelText: l.trendsColCountry),
              items: [for (final c in TrendsCountry.values) DropdownMenuItem(value: c, child: Text(countryLabel(context, c)))],
              onChanged: (v) => setState(() => _country = v ?? _country),
            ),
            num(_share, l.trendsIndexedShare, 'share', helper: l.trendsIndexedShareHelp),
            num(_clicks, l.trendsClicks7d, 'clicks'),
            num(_prev, l.trendsClicksPrev7d, 'prev'),
            num(_warnings, l.trendsScWarnings, 'warnings'),
            num(_errors, l.trendsErrorReports, 'errors'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.trendsManualAction),
              subtitle: Text(l.trendsManualActionHelp),
              value: _manual,
              onChanged: (v) => setState(() => _manual = v),
            ),
            TextField(controller: _note, decoration: InputDecoration(labelText: l.note)),
            if (err != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(err, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: err == null ? () => Navigator.pop(context, input) : null, child: Text(l.save)),
      ],
    );
  }
}

/// Visits in the 14 days after the trend ended (`admin_trends_record_traffic`).
class TrafficDialog extends StatefulWidget {
  const TrafficDialog({super.key, this.slug});
  final String? slug;

  @override
  State<TrafficDialog> createState() => _TrafficDialogState();
}

class _TrafficDialogState extends State<TrafficDialog> {
  late final _slug = TextEditingController(text: widget.slug ?? '');
  final _visits = TextEditingController();

  @override
  void dispose() {
    _slug.dispose();
    _visits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final visits = int.tryParse(_visits.text.trim());
    final ok = _slug.text.trim().isNotEmpty && visits != null && visits >= 0;
    return AlertDialog(
      title: Text(l.trendsRecordTraffic),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _slug, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: l.trendsSlug)),
          TextField(
            controller: _visits,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.trendsVisitsHint),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: ok ? () => Navigator.pop(context, (_slug.text.trim(), visits)) : null, child: Text(l.save)),
      ],
    );
  }
}

// Settings editor ---------------------------------------------------------------------------------------

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard(this.s);
  final TrendSettingsSnapshot s;

  static String _summary(Object? v) {
    final text = v is List && v.every((e) => e is String) ? v.join(', ') : jsonEncode(v);
    return text.length > 220 ? '${text.substring(0, 220)}…' : text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return _Section(
      title: l.trendsSettings,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.trendsSettingsHelp, style: Theme.of(context).textTheme.bodySmall),
        for (final k in s.editableKeys)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(k),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((s.descriptions[k] ?? '').isNotEmpty) Text(s.descriptions[k]!),
              Text(_summary(s.settings[k]), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
            ]),
            trailing: IconButton(
              key: ValueKey('trends-edit-$k'),
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await showDialog<bool>(
                  context: context,
                  builder: (_) => TrendSettingDialog(
                    settingKey: k,
                    value: s.settings[k],
                    description: s.descriptions[k],
                    onSave: (v) => ref.read(trendsRepositoryProvider).setSetting(k, v),
                  ),
                );
                if (saved == true) {
                  _afterChange(ref);
                  if (context.mounted) context.toast(l.saved);
                }
              },
            ),
          ),
      ]),
    );
  }
}

// Decision log ------------------------------------------------------------------------------------------

class _LogCard extends ConsumerWidget {
  const _LogCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final log = ref.watch(trendPublishLogProvider);
    return _Section(
      title: l.trendsDecisionLog,
      child: AsyncView(
        value: log,
        onRetry: () => ref.invalidate(trendPublishLogProvider),
        builder: (rows) => rows.isEmpty ? Text(l.trendsNoLog) : TrendLogList(rows),
      ),
    );
  }
}

class TrendLogList extends StatelessWidget {
  const TrendLogList(this.rows, {super.key});
  final List<TrendLogEntry> rows;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '${fmtDateTime(r.createdAt)}  ', style: t.bodySmall),
            TextSpan(text: r.decision, style: t.labelLarge),
            if (r.slug != null) TextSpan(text: '  /${r.slug}', style: t.bodySmall),
            if (r.country != null) TextSpan(text: '  ${countryLabel(context, r.country)}', style: t.bodySmall),
            if (r.reason != null) TextSpan(text: '  ${r.reason}', style: t.bodySmall),
            TextSpan(text: '  · ${r.actorId ?? context.l10n.trendsPipelineActor}', style: t.bodySmall),
          ])),
        ),
    ]);
  }
}
