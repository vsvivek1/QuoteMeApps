import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/utils/save_file.dart';
import '../../../core/widgets/async_view.dart';
import '../../categories/application/category_providers.dart';
import '../../categories/domain/category_models.dart';
import '../application/outreach_providers.dart';
import '../domain/lead_import.dart';
import '../domain/outreach_models.dart';
import 'stage_actions.dart';
import 'stage_labels.dart';

/// Seller acquisition CRM: kanban board, suppression list, campaigns and
/// seller coverage (Section 21.5).
class OutreachScreen extends StatelessWidget {
  const OutreachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navOutreach),
          actions: [
            TextButton.icon(
              onPressed: () => context.go(Routes.outreachImport),
              icon: const Icon(Icons.upload_file),
              label: Text(l.importCsv),
            ),
          ],
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l.tabBoard),
            Tab(text: l.tabSuppression),
            Tab(text: l.tabCampaigns),
            Tab(text: l.tabCoverage),
          ]),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [_BoardTab(), _SuppressionTab(), _CampaignsTab(), _CoverageTab()],
        ),
      ),
    );
  }
}

class _BoardTab extends ConsumerStatefulWidget {
  const _BoardTab();

  @override
  ConsumerState<_BoardTab> createState() => _BoardTabState();
}

class _BoardTabState extends ConsumerState<_BoardTab> {
  final _selected = <String>{};

  Future<void> _export(List<OutreachLead> leads) async {
    final chosen = _selected.isEmpty ? leads : leads.where((l) => _selected.contains(l.id)).toList();
    final csv = LeadImporter.export(chosen);
    await saveBytes('outreach_leads.csv', utf8.encode(csv), 'text/csv');
  }

  Future<void> _enrol() async {
    final l = context.l10n;
    final campaigns = await ref.read(campaignsProvider.future);
    if (!mounted) return;
    final id = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.enrolTitle(_selected.length)),
        children: [
          for (final c in campaigns)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, c.id), child: Text('${c.name} (${c.status})')),
        ],
      ),
    );
    if (id == null) return;
    await ref.read(outreachRepositoryProvider).enrol(_selected.toList(), id);
    invalidateOutreach(ref);
    setState(_selected.clear);
    if (mounted) context.toast(l.enrolled);
  }

  Future<void> _bulkMove(List<OutreachLead> leads) async {
    final l = context.l10n;
    final to = await showDialog<LeadStage>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.moveSelected(_selected.length)),
        children: [
          for (final s in LeadStage.values)
            SimpleDialogOption(onPressed: () => Navigator.pop(ctx, s), child: Text(stageLabel(context, s))),
        ],
      ),
    );
    if (to == null || !mounted) return;
    var moved = 0;
    for (final lead in leads.where((x) => _selected.contains(x.id))) {
      if (!mounted) break;
      if (await moveLeadStage(context, ref, lead, to, quiet: true)) moved++;
    }
    setState(_selected.clear);
    if (mounted) context.toast(l.movedCount(moved));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final leads = ref.watch(outreachLeadsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Filters(),
      if (_selected.isNotEmpty)
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(l.selectedCount(_selected.length)),
              TextButton(onPressed: _enrol, child: Text(l.enrolInCampaign)),
              TextButton(onPressed: () => _bulkMove(leads.value ?? const []), child: Text(l.moveStage)),
              TextButton(onPressed: () => _export(leads.value ?? const []), child: Text(l.exportCsv)),
              TextButton(onPressed: () => setState(_selected.clear), child: Text(l.clearSelection)),
            ]),
          ),
        ),
      Expanded(
        child: AsyncView(
          value: leads,
          onRetry: () => ref.invalidate(outreachLeadsProvider),
          builder: (list) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(children: [
                Text(l.leadCount(list.length), style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: list.isEmpty ? null : () => _export(list),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(_selected.isEmpty ? l.exportAllCsv : l.exportCsv),
                ),
              ]),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final stage in LeadStage.values)
                      _Column(
                        stage: stage,
                        leads: list.where((x) => x.stage == stage).toList(),
                        selected: _selected,
                        onToggle: (id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id)),
                      ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = ref.watch(leadFilterControllerProvider);
    final ctrl = ref.read(leadFilterControllerProvider.notifier);
    final config = ref.watch(countryConfigProvider);
    final cats = ref.watch(adminCategoriesProvider).value ?? const <AdminCategory>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(
          width: 220,
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchLeads),
            onSubmitted: (v) => ctrl.set(f.copyWith(query: v.trim().isEmpty ? null : v.trim())),
          ),
        ),
        _Drop<String>(
          label: l.state,
          value: f.state,
          items: {for (final s in config.states) s: s},
          onChanged: (v) => ctrl.set(f.copyWith(state: v)),
        ),
        _Drop<String>(
          label: l.city,
          value: f.city,
          items: {for (final c in config.priorityCities) c.name: c.name},
          onChanged: (v) => ctrl.set(f.copyWith(city: v)),
        ),
        _Drop<int>(
          label: l.category,
          value: f.categoryId,
          items: {for (final c in cats.where((c) => c.policy != CategoryPolicy.blocked)) c.id: c.name()},
          onChanged: (v) => ctrl.set(f.copyWith(categoryId: v)),
        ),
        _Drop<LeadSource>(
          label: l.source,
          value: f.source,
          items: {for (final s in LeadSource.values) s: s.name},
          onChanged: (v) => ctrl.set(f.copyWith(source: v)),
        ),
        if (f != const LeadFilter()) TextButton(onPressed: ctrl.clear, child: Text(l.clearFilters)),
      ]),
    );
  }
}

class _Drop<T> extends StatelessWidget {
  const _Drop({required this.label, required this.value, required this.items, required this.onChanged});
  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        child: DropdownButtonFormField<T?>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(context.l10n.any)),
            for (final e in items.entries) DropdownMenuItem<T?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      );
}

class _Column extends ConsumerWidget {
  const _Column({required this.stage, required this.leads, required this.selected, required this.onToggle});
  final LeadStage stage;
  final List<OutreachLead> leads;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<OutreachLead>(
      onWillAcceptWithDetails: (d) => d.data.stage != stage,
      onAcceptWithDetails: (d) => moveLeadStage(context, ref, d.data, stage),
      builder: (context, candidates, _) => Container(
        width: 270,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: stageColor(context, stage)),
              const SizedBox(width: 8),
              Expanded(child: Text(stageLabel(context, stage), style: Theme.of(context).textTheme.titleSmall)),
              Text('${leads.length}'),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              itemCount: leads.length,
              itemBuilder: (_, i) {
                final lead = leads[i];
                final card = _LeadCard(lead: lead, selected: selected.contains(lead.id), onToggle: () => onToggle(lead.id));
                return Draggable<OutreachLead>(
                  data: lead,
                  feedback: Material(elevation: 6, borderRadius: BorderRadius.circular(12), child: SizedBox(width: 250, child: card)),
                  childWhenDragging: Opacity(opacity: 0.4, child: card),
                  child: card,
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _LeadCard extends ConsumerWidget {
  const _LeadCard({required this.lead, required this.selected, required this.onToggle});
  final OutreachLead lead;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cats = ref.watch(categoryIndexProvider).value ?? const {};
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(Routes.lead(lead.id)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Checkbox(value: selected, onChanged: (_) => onToggle()),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 10),
                  Text(lead.businessName, style: t.titleSmall),
                  Text([lead.city, lead.state].whereType<String>().join(', '), style: t.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    lead.matchedCategoryIds.isEmpty
                        ? l.noMatchedCategory
                        : lead.matchedCategoryIds.map((id) => cats[id]?.name() ?? '#$id').join(', '),
                    style: t.bodySmall?.copyWith(
                        color: lead.matchedCategoryIds.isEmpty ? Theme.of(context).colorScheme.error : null),
                  ),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    Text(l.touches(lead.touchesSent), style: t.labelSmall),
                    if (lead.email != null)
                      Icon(
                        lead.emailStatus == EmailStatus.valid ? Icons.mark_email_read_outlined : Icons.email_outlined,
                        size: 14,
                      ),
                    if (lead.whatsappOptInAt != null) const Icon(Icons.chat_outlined, size: 14),
                    if (lead.nextActionDue != null) Text('${l.due} ${fmtDate(lead.nextActionDue)}', style: t.labelSmall),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SuppressionTab extends ConsumerWidget {
  const _SuppressionTab();

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final value = TextEditingController();
    final note = TextEditingController();
    var kind = 'email';
    var reason = 'manual';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.addSuppression),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'email', label: Text(l.email)),
                  ButtonSegment(value: 'domain', label: Text(l.domain)),
                  ButtonSegment(value: 'phone', label: Text(l.phone)),
                ],
                selected: {kind},
                onSelectionChanged: (s) => setState(() => kind = s.first),
              ),
              const SizedBox(height: 12),
              TextField(controller: value, decoration: InputDecoration(labelText: l.value)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: InputDecoration(labelText: l.reason),
                items: [for (final r in suppressionReasons) DropdownMenuItem(value: r, child: Text(r))],
                onChanged: (v) => reason = v ?? reason,
              ),
              const SizedBox(height: 12),
              TextField(controller: note, decoration: InputDecoration(labelText: l.note)),
              const SizedBox(height: 8),
              Text(l.suppressionPermanent, style: Theme.of(ctx).textTheme.bodySmall),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.add)),
          ],
        ),
      ),
    );
    final v = value.text.trim();
    if (ok != true || v.isEmpty) return;
    try {
      await ref.read(outreachRepositoryProvider).suppress(
            email: kind == 'email' ? v : null,
            emailDomain: kind == 'domain' ? v : null,
            phone: kind == 'phone' ? v : null,
            reason: reason,
            note: note.text.trim().isEmpty ? null : note.text.trim(),
          );
      invalidateOutreach(ref);
      if (context.mounted) context.toast(l.saved);
    } catch (e) {
      if (context.mounted) context.toast('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.block),
        label: Text(l.addSuppression),
      ),
      body: AsyncView(
        value: ref.watch(suppressionListProvider),
        onRetry: () => ref.invalidate(suppressionListProvider),
        builder: (list) => ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.suppressionIntro),
          const SizedBox(height: 12),
          if (list.isEmpty) EmptyState(l.suppressionEmpty),
          for (final s in list)
            ListTile(
              leading: const Icon(Icons.block),
              title: Text(s.email ?? (s.emailDomain != null ? '*@${s.emailDomain}' : null) ?? s.phone ?? s.businessKey ?? '-'),
              subtitle: Text('${s.reason}${s.note == null ? '' : ' · ${s.note}'} · ${s.source ?? ''} · ${fmtDate(s.createdAt)}'),
            ),
        ]),
      ),
    );
  }
}

class _CampaignsTab extends ConsumerWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final stats = ref.watch(sendStatsProvider).value;
    return AsyncView(
      value: ref.watch(campaignsProvider),
      onRetry: () => ref.invalidate(campaignsProvider),
      builder: (list) => ListView(padding: const EdgeInsets.all(16), children: [
        if (stats != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.speed),
              title: Text(l.sendCapacity(stats.sentTodayGlobal, stats.globalDailyCap)),
              subtitle: Text(l.sendCapacityHelp(stats.perDomainDailyCap, stats.bounceBrakePct.toString(),
                  stats.complaintBrakePct.toString(), stats.negativeBrakePct.toString())),
            ),
          ),
        const SizedBox(height: 12),
        for (final c in list)
          Card(
            child: ListTile(
              title: Text(c.name),
              subtitle: Text([
                '${l.status}: ${c.status}',
                '${l.dailyCap}: ${c.dailyCap}',
                if (c.pausedReason != null) '${l.pausedReason}: ${c.pausedReason}',
                if (stats?.campaignHealth[c.id] case final h?)
                  l.campaignHealth(h.sent, fmtPct(h.bouncePct), fmtPct(h.complaintPct), fmtPct(h.negativePct)),
              ].join(' · ')),
              trailing: c.status == 'active'
                  ? OutlinedButton(
                      onPressed: () async {
                        await ref.read(outreachRepositoryProvider).setCampaignStatus(c.id, 'paused');
                        ref.invalidate(campaignsProvider);
                      },
                      child: Text(l.pause),
                    )
                  : c.status == 'paused'
                      ? FilledButton(
                          onPressed: () async {
                            final ok = await confirmDialog(context,
                                title: l.resumeTitle,
                                body: (c.pausedReason ?? '').startsWith('auto_brake') ? l.resumeBrakeBody : l.resumeBody);
                            if (!ok) return;
                            await ref.read(outreachRepositoryProvider).setCampaignStatus(c.id, 'active');
                            ref.invalidate(campaignsProvider);
                          },
                          child: Text(l.resume),
                        )
                      : null,
            ),
          ),
      ]),
    );
  }
}

class _CoverageTab extends ConsumerWidget {
  const _CoverageTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cats = ref.watch(categoryIndexProvider).value ?? const {};
    return AsyncView(
      value: ref.watch(coverageProvider),
      onRetry: () => ref.invalidate(coverageProvider),
      builder: (cells) => ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.coverageIntro),
        const SizedBox(height: 12),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: [
              DataColumn(label: Text(l.city)),
              DataColumn(label: Text(l.state)),
              DataColumn(label: Text(l.category)),
              DataColumn(label: Text(l.sellers), numeric: true),
              DataColumn(label: Text(l.liquidity)),
            ], rows: [
              for (final c in cells)
                DataRow(cells: [
                  DataCell(Text(c.city)),
                  DataCell(Text(c.state ?? '')),
                  DataCell(Text(cats[c.categoryId]?.name() ?? '#${c.categoryId}')),
                  DataCell(Text('${c.sellers}')),
                  DataCell(c.needsSellers
                      ? Text(l.needsSellers, style: TextStyle(color: Theme.of(context).colorScheme.error))
                      : Text(l.ok)),
                ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
