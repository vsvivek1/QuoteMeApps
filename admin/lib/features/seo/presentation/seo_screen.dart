import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../../categories/application/category_providers.dart';
import '../../categories/domain/category_models.dart';
import '../../flags/application/settings_providers.dart';
import '../application/seo_providers.dart';
import '../domain/seo_models.dart';

/// SEO content site (Section 21.9): price-page status from the nightly
/// export, quality-gate thresholds, "Run export now" and the review queue
/// for buying guides.
class SeoScreen extends ConsumerWidget {
  const SeoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navSeo),
          bottom: TabBar(tabs: [Tab(text: l.seoTabPages), Tab(text: l.seoTabGuides)]),
          actions: [
            IconButton(
              tooltip: l.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref
                ..invalidate(seoPagesProvider)
                ..invalidate(seoExportRunsProvider)
                ..invalidate(seoGuidesProvider)
                ..invalidate(appSettingsProvider),
            ),
          ],
        ),
        body: const TabBarView(children: [_PagesTab(), _GuidesTab()]),
      ),
    );
  }
}

String seoStatusLabel(BuildContext context, SeoPageStatus s) => switch (s) {
      SeoPageStatus.indexable => context.l10n.seoStatusIndexable,
      SeoPageStatus.noindex => context.l10n.seoStatusNoindex,
      SeoPageStatus.waitingForData => context.l10n.seoStatusWaiting,
    };

// Pages ---------------------------------------------------------------------------------------------

class _PagesTab extends ConsumerStatefulWidget {
  const _PagesTab();

  @override
  ConsumerState<_PagesTab> createState() => _PagesTabState();
}

class _PagesTabState extends ConsumerState<_PagesTab> {
  SeoPageStatus? _filter;
  bool _running = false;

  Future<void> _runExport() async {
    final l = context.l10n;
    final ok = await confirmDialog(context, title: l.seoRunExportTitle, body: l.seoRunExportBody, action: l.seoRunExport);
    if (!ok || !mounted) return;
    setState(() => _running = true);
    try {
      final r = await ref.read(seoRepositoryProvider).runExportNow();
      ref
        ..invalidate(seoPagesProvider)
        ..invalidate(seoExportRunsProvider)
        ..invalidate(auditLogProvider);
      if (mounted) context.toast(l.seoExportDone(r.pages, r.pricedPages, r.guides, r.deployHook));
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pages = ref.watch(seoPagesProvider);
    final runs = ref.watch(seoExportRunsProvider);
    final settings = ref.watch(seoSettingsProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: switch (runs) {
                AsyncData(:final value) when value.isNotEmpty => _RunSummary(value.first),
                AsyncData() => Text(l.seoNoRuns),
                AsyncError(:final error) => Text('$error'),
                _ => const LinearProgressIndicator(),
              },
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _running ? null : _runExport,
              icon: _running
                  ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(l.seoRunExport),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      switch (settings) {
        AsyncData(:final value) => _ThresholdsCard(value.thresholds),
        AsyncError(:final error) => Text('$error'),
        _ => const LinearProgressIndicator(),
      },
      const SizedBox(height: 12),
      AsyncView(
        value: pages,
        onRetry: () => ref.invalidate(seoPagesProvider),
        builder: (rows) {
          if (rows.isEmpty) return Padding(padding: const EdgeInsets.all(24), child: EmptyState(l.seoNoPages));
          final counts = {for (final s in SeoPageStatus.values) s: rows.where((r) => r.status == s).length};
          final shown = _filter == null ? rows : rows.where((r) => r.status == _filter).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: Text('${l.all} (${rows.length})'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final s in SeoPageStatus.values)
                ChoiceChip(
                  label: Text('${seoStatusLabel(context, s)} (${counts[s]})'),
                  selected: _filter == s,
                  onSelected: (_) => setState(() => _filter = s),
                ),
            ]),
            const SizedBox(height: 8),
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(l.seoColPage)),
                    DataColumn(label: Text(l.seoColStatus)),
                    DataColumn(label: Text(l.seoColQuotes), numeric: true),
                    DataColumn(label: Text(l.seoColSellers), numeric: true),
                    DataColumn(label: Text(l.seoColLocal), numeric: true),
                    DataColumn(label: Text(l.seoColLastQuote)),
                    DataColumn(label: Text(l.seoColUpdated)),
                    DataColumn(label: Text(l.seoColReasons)),
                    DataColumn(label: Text(l.seoForceNoindex)),
                  ],
                  rows: [for (final r in shown.take(500)) _row(context, r)],
                ),
              ),
            ),
          ]);
        },
      ),
    ]);
  }

  DataRow _row(BuildContext context, SeoPageRow r) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (r.status) {
      SeoPageStatus.indexable => scheme.primaryContainer,
      SeoPageStatus.noindex => scheme.errorContainer,
      SeoPageStatus.waitingForData => scheme.surfaceContainerHighest,
    };
    return DataRow(cells: [
      DataCell(SelectableText(r.path)),
      DataCell(Chip(label: Text(seoStatusLabel(context, r.status)), backgroundColor: color, visualDensity: VisualDensity.compact)),
      DataCell(Text(fmtInt(r.quotesWindow))),
      DataCell(Text(fmtInt(r.sellersWindow))),
      DataCell(Text(fmtInt(r.localSellers))),
      DataCell(Text(fmtDate(r.lastQuoteAt))),
      DataCell(Text(fmtDateTime(r.refreshedAt))),
      DataCell(ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(r.reasons.join('; '), style: Theme.of(context).textTheme.bodySmall),
      )),
      DataCell(Switch(
        value: r.manualNoindex,
        onChanged: (v) async {
          try {
            await ref.read(seoRepositoryProvider).setPageNoindex(r.cityId, r.categoryId, v);
            ref
              ..invalidate(seoPagesProvider)
              ..invalidate(auditLogProvider);
          } catch (e) {
            if (context.mounted) context.toast('$e', error: true);
          }
        },
      )),
    ]);
  }
}

class _RunSummary extends StatelessWidget {
  const _RunSummary(this.run);
  final SeoExportRun run;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final when = fmtDateTime(run.finishedAt ?? run.startedAt);
    if (run.error != null) {
      return Text(l.seoLastRunFailed(when, run.error!), style: TextStyle(color: Theme.of(context).colorScheme.error));
    }
    return Text(l.seoLastRun(when, run.triggeredBy.startsWith('admin:') ? 'admin' : run.triggeredBy, run.indexable ?? 0,
        run.noindex ?? 0, run.waitingForData ?? 0, run.deployHook ?? '-'));
  }
}

class _ThresholdsCard extends ConsumerWidget {
  const _ThresholdsCard(this.t);
  final SeoThresholds t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.seoThresholds, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l.seoThresholdsHelp(t.minQuotes, t.minSellers, t.windowDays, t.staleDays)),
            ]),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final next = await showDialog<SeoThresholds>(context: context, builder: (_) => ThresholdsDialog(initial: t));
              if (next == null || next == t || !context.mounted) return;
              try {
                await ref.read(settingsRepositoryProvider).set(SeoThresholds.settingKey, next.toJson());
                ref
                  ..invalidate(appSettingsProvider)
                  ..invalidate(auditLogProvider);
                if (context.mounted) context.toast('${l.saved}. ${l.seoThresholdsTakeEffect}');
              } catch (e) {
                if (context.mounted) context.toast('$e', error: true);
              }
            },
            icon: const Icon(Icons.tune),
            label: Text(l.edit),
          ),
        ]),
      ),
    );
  }
}

/// Edits the four gates; Save stays disabled while a value is out of range.
class ThresholdsDialog extends StatefulWidget {
  const ThresholdsDialog({super.key, required this.initial});
  final SeoThresholds initial;

  @override
  State<ThresholdsDialog> createState() => _ThresholdsDialogState();
}

class _ThresholdsDialogState extends State<ThresholdsDialog> {
  late final _ctrls = {
    for (final e in widget.initial.toJson().entries) e.key: TextEditingController(text: '${e.value}'),
  };

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  SeoThresholds? get _value {
    final v = {for (final e in _ctrls.entries) e.key: int.tryParse(e.value.text.trim())};
    if (v.values.any((x) => x == null)) return null;
    final t = SeoThresholds(
      minQuotes: v['min_quotes']!,
      minSellers: v['min_sellers']!,
      windowDays: v['window_days']!,
      staleDays: v['stale_days']!,
    );
    return t.isValid ? t : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = {
      'min_quotes': l.seoMinQuotes,
      'min_sellers': l.seoMinSellers,
      'window_days': l.seoWindowDays,
      'stale_days': l.seoStaleDays,
    };
    final value = _value;
    return AlertDialog(
      title: Text(l.seoThresholds),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in _ctrls.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                key: ValueKey('seo-threshold-${e.key}'),
                controller: e.value,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: labels[e.key],
                  helperText: l.seoRange(SeoThresholds.ranges[e.key]!.$1, SeoThresholds.ranges[e.key]!.$2),
                ),
              ),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: value == null ? null : () => Navigator.pop(context, value), child: Text(l.save)),
      ],
    );
  }
}

// Guides ---------------------------------------------------------------------------------------------

String guideStatusLabel(BuildContext context, GuideStatus s) => switch (s) {
      GuideStatus.draft => context.l10n.seoGuideStatusDraft,
      GuideStatus.approved => context.l10n.seoGuideStatusApproved,
      GuideStatus.published => context.l10n.seoGuideStatusPublished,
    };

String guideActionLabel(BuildContext context, GuideAction a) => switch (a) {
      GuideAction.approve => context.l10n.seoGuideApprove,
      GuideAction.publish => context.l10n.seoGuidePublish,
      GuideAction.unpublish => context.l10n.seoGuideUnpublish,
      GuideAction.reject => context.l10n.seoGuideReject,
    };

class _GuidesTab extends ConsumerWidget {
  const _GuidesTab();

  Future<void> _edit(BuildContext context, WidgetRef ref, {SeoGuide? guide, required int cap}) async {
    final cats = await ref.read(adminCategoriesProvider.future);
    final pages = await ref.read(seoPagesProvider.future);
    if (!context.mounted) return;
    final cities = <int, String>{for (final p in pages) p.cityId: p.citySlug};
    final draft = await showDialog<SeoGuideDraft>(
      context: context,
      builder: (_) => GuideEditorDialog(
        guide: guide,
        categories: [for (final c in cats) if (c.policy != CategoryPolicy.blocked) c],
        cities: cities,
        aiCap: cap,
      ),
    );
    if (draft == null || !context.mounted) return;
    try {
      await ref.read(seoRepositoryProvider).upsertGuide(draft);
      ref
        ..invalidate(seoGuidesProvider)
        ..invalidate(auditLogProvider);
      if (context.mounted) context.toast(context.l10n.saved);
    } catch (e) {
      if (context.mounted) context.toast('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cap = ref.watch(seoSettingsProvider).value?.aiGuideCap ?? 10;
    final cats = ref.watch(categoryIndexProvider).value ?? const {};
    final now = DateTime.now();
    return AsyncView(
      value: ref.watch(seoGuidesProvider),
      onRetry: () => ref.invalidate(seoGuidesProvider),
      builder: (guides) {
        final used = aiGuidesThisWeek(guides, now);
        return ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: Text(l.seoGuidesAiQuota(used, cap))),
            TextButton(
              onPressed: () async {
                final text = await askReason(context, title: l.seoGuideCap, hint: '$cap');
                final v = int.tryParse(text ?? '');
                if (v == null || !context.mounted) return;
                try {
                  await ref.read(settingsRepositoryProvider).set(SeoThresholds.guideCapKey, v);
                  ref
                    ..invalidate(appSettingsProvider)
                    ..invalidate(auditLogProvider);
                } catch (e) {
                  if (context.mounted) context.toast('$e', error: true);
                }
              },
              child: Text(l.seoGuideCap),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _edit(context, ref, cap: cap),
              icon: const Icon(Icons.add),
              label: Text(l.seoGuideNew),
            ),
          ]),
          const SizedBox(height: 12),
          if (guides.isEmpty) Padding(padding: const EdgeInsets.all(24), child: EmptyState(l.seoGuidesEmpty)),
          for (final g in guides)
            Card(
              child: ListTile(
                title: Text(g.title),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('/guides/${g.slug} · ${cats[g.categoryId]?.name() ?? '#${g.categoryId}'}'),
                  Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Chip(label: Text(guideStatusLabel(context, g.status)), visualDensity: VisualDensity.compact),
                    if (g.aiAssisted) Chip(label: Text(l.seoGuideAiBadge), visualDensity: VisualDensity.compact),
                    if (g.reviewedAt != null) Text(l.seoGuideReviewed(fmtDate(g.reviewedAt))),
                    Text(l.seoGuideSite(g.siteVisibility(now))),
                  ]),
                  if (g.reviewOverdue(now))
                    Text(l.seoGuideReviewOverdue, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ]),
                isThreeLine: true,
                trailing: Wrap(spacing: 4, children: [
                  IconButton(
                    tooltip: l.seoGuideEdit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(context, ref, guide: g, cap: cap),
                  ),
                  for (final a in guideActions(g.status))
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          await ref.read(seoRepositoryProvider).reviewGuide(g.id, a);
                          ref
                            ..invalidate(seoGuidesProvider)
                            ..invalidate(auditLogProvider);
                        } catch (e) {
                          if (context.mounted) context.toast('$e', error: true);
                        }
                      },
                      child: Text(guideActionLabel(context, a)),
                    ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}

/// Create / edit a guide. Returns the draft to save, or null.
class GuideEditorDialog extends StatefulWidget {
  const GuideEditorDialog({
    super.key,
    this.guide,
    required this.categories,
    required this.cities,
    required this.aiCap,
  });

  final SeoGuide? guide;
  final List<AdminCategory> categories;

  /// city id -> slug (cities that have price pages).
  final Map<int, String> cities;
  final int aiCap;

  @override
  State<GuideEditorDialog> createState() => _GuideEditorDialogState();
}

class _GuideEditorDialogState extends State<GuideEditorDialog> {
  late final _title = TextEditingController(text: widget.guide?.title ?? '');
  late final _slug = TextEditingController(text: widget.guide?.slug ?? '');
  late final _desc = TextEditingController(text: widget.guide?.description ?? '');
  late final _body = TextEditingController(text: widget.guide?.bodyMd ?? '');
  late int? _category = widget.guide?.categoryId ?? widget.categories.firstOrNull?.id;
  late int? _city = widget.guide?.cityId;
  late bool _ai = widget.guide?.aiAssisted ?? false;
  bool _slugTouched = false;

  @override
  void dispose() {
    for (final c in [_title, _slug, _desc, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  SeoGuideDraft? get _draft => _category == null
      ? null
      : SeoGuideDraft(
          id: widget.guide?.id,
          slug: _slug.text.trim(),
          title: _title.text,
          description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          cityId: _city,
          categoryId: _category!,
          bodyMd: _body.text,
          aiAssisted: _ai,
        );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final draft = _draft;
    final error = draft?.validate();
    final editing = widget.guide != null;
    return AlertDialog(
      title: Text(editing ? l.seoGuideEdit : l.seoGuideNew),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              key: const ValueKey('guide-title'),
              controller: _title,
              decoration: InputDecoration(labelText: l.seoGuideTitle),
              onChanged: (v) => setState(() {
                if (!editing && !_slugTouched) _slug.text = slugify(v);
              }),
            ),
            TextField(
              key: const ValueKey('guide-slug'),
              controller: _slug,
              decoration: InputDecoration(labelText: l.seoGuideSlug, prefixText: '/guides/'),
              onChanged: (_) => setState(() => _slugTouched = true),
            ),
            TextField(controller: _desc, decoration: InputDecoration(labelText: l.seoGuideDescription), maxLength: 300),
            DropdownButtonFormField<int>(
              initialValue: _category,
              decoration: InputDecoration(labelText: l.seoGuideCategory),
              items: [for (final c in widget.categories) DropdownMenuItem(value: c.id, child: Text(c.name()))],
              onChanged: (v) => setState(() => _category = v),
            ),
            DropdownButtonFormField<int?>(
              initialValue: widget.cities.containsKey(_city) ? _city : null,
              decoration: InputDecoration(labelText: l.seoGuideCity),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(l.seoGuideNoCity)),
                for (final e in widget.cities.entries) DropdownMenuItem<int?>(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _city = v),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('guide-body'),
              controller: _body,
              minLines: 8,
              maxLines: 20,
              decoration: InputDecoration(labelText: l.seoGuideBody, alignLabelWithHint: true, border: const OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _ai,
              // The AI flag can be set on new guides only (server rule).
              onChanged: editing && !(widget.guide?.aiAssisted ?? false) ? null : (v) => setState(() => _ai = v ?? false),
              title: Text(l.seoGuideAi),
              subtitle: Text(l.seoGuideAiHelp(widget.aiCap)),
            ),
            if (editing && widget.guide!.status != GuideStatus.draft)
              Text(l.seoGuideEditResets, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (error != null && _title.text.isNotEmpty)
              Text(l.seoGuideInvalid(error), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: draft == null || error != null ? null : () => Navigator.pop(context, draft),
          child: Text(l.save),
        ),
      ],
    );
  }
}
