import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/moderation_providers.dart';
import '../domain/moderation_models.dart';

/// Reports queue, user search (suspend / ban) and the admin audit log.
class ModerationScreen extends StatelessWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navModeration),
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(text: l.tabReports),
            Tab(text: l.tabUsers),
            Tab(text: l.tabAuditLog),
          ]),
        ),
        body: const TabBarView(children: [_ReportsTab(), _UsersTab(), AuditLogView()]),
      ),
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AsyncView(
      value: ref.watch(openReportsProvider),
      onRetry: () => ref.invalidate(openReportsProvider),
      builder: (reports) => reports.isEmpty
          ? EmptyState(l.reportsEmpty, icon: Icons.flag_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReportCard(reports[i]),
            ),
    );
  }
}

class _ReportCard extends ConsumerStatefulWidget {
  const _ReportCard(this.report);
  final ReportItem report;

  @override
  ConsumerState<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends ConsumerState<_ReportCard> {
  bool _busy = false;

  void _refresh() {
    ref
      ..invalidate(openReportsProvider)
      ..invalidate(dashboardMetricsProvider)
      ..invalidate(auditLogProvider);
  }

  Future<void> _resolve(ReportAction action) async {
    final l = context.l10n;
    final note = await askReason(context, title: l.resolveTitle, hint: l.resolveNoteHint, required: false);
    if (note == null) return;
    setState(() => _busy = true);
    try {
      final n = await ref.read(moderationRepositoryProvider).resolve(widget.report.id, action, note: note.isEmpty ? null : note);
      _refresh();
      if (mounted) context.toast(l.reportsResolved(n));
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ban() async {
    final l = context.l10n;
    final owner = widget.report.targetOwnerId;
    if (owner == null) return;
    final reason = await askReason(context, title: l.banTitle, hint: l.banHint);
    if (reason == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(moderationRepositoryProvider).setUserStatus(owner, 'banned', reason: reason);
      await ref.read(moderationRepositoryProvider).resolve(widget.report.id, ReportAction.hide, note: 'banned: $reason');
      _refresh();
      if (mounted) context.toast(l.userBanned);
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.report;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Chip(label: Text(r.targetType), visualDensity: VisualDensity.compact),
            Chip(label: Text(r.reason), visualDensity: VisualDensity.compact),
            Text(l.reportCount(r.reportCount), style: t.labelMedium),
            Text(fmtDateTime(r.createdAt), style: t.bodySmall),
          ]),
          const SizedBox(height: 8),
          if (r.targetPreview != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.targetPreview!),
            ),
          if (r.details != null) ...[const SizedBox(height: 6), Text('${l.reporterSays}: ${r.details}')],
          const SizedBox(height: 4),
          SelectableText('${r.targetType} ${r.targetId}', style: t.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _resolve(ReportAction.hide),
              icon: const Icon(Icons.visibility_off_outlined),
              label: Text(l.hideContent),
            ),
            OutlinedButton(onPressed: _busy ? null : () => _resolve(ReportAction.dismiss), child: Text(l.dismiss)),
            OutlinedButton(onPressed: _busy ? null : () => _resolve(ReportAction.restore), child: Text(l.restore)),
            if (r.targetOwnerId != null)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                onPressed: _busy ? null : _ban,
                icon: const Icon(Icons.block),
                label: Text(l.banUser),
              ),
          ]),
        ]),
      ),
    );
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  String _query = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _setStatus(UserSummary u, String status) async {
    final l = context.l10n;
    DateTime? until;
    String? reason;
    if (status != 'active') {
      reason = await askReason(context, title: status == 'banned' ? l.banTitle : l.suspendTitle, hint: l.banHint);
      if (reason == null) return;
      if (status == 'suspended') until = DateTime.now().add(const Duration(days: 7));
    }
    try {
      await ref.read(moderationRepositoryProvider).setUserStatus(u.id, status, until: until, reason: reason);
      ref
        ..invalidate(userSearchProvider(_query))
        ..invalidate(auditLogProvider);
      if (mounted) context.toast(l.userStatusSet(status));
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final users = ref.watch(userSearchProvider(_query));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _ctrl,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchUsersHint),
          onSubmitted: (v) => setState(() => _query = v.trim()),
        ),
      ),
      Expanded(
        child: AsyncView(
          value: users,
          builder: (list) => list.isEmpty
              ? EmptyState(l.noResults)
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text((u.name ?? u.email ?? '?').substring(0, 1).toUpperCase())),
                      title: Text(u.name ?? u.email ?? u.id),
                      subtitle: Text([
                        ?u.email,
                        ?u.phone,
                        u.roles.join('/'),
                        if (u.statusReason != null) '${l.reason}: ${u.statusReason}',
                      ].join(' · ')),
                      trailing: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Chip(label: Text(u.status), visualDensity: VisualDensity.compact),
                        PopupMenuButton<String>(
                          onSelected: (s) => _setStatus(u, s),
                          itemBuilder: (_) => [
                            if (u.status != 'active') PopupMenuItem(value: 'active', child: Text(l.reactivate)),
                            if (u.status != 'suspended') PopupMenuItem(value: 'suspended', child: Text(l.suspend7d)),
                            if (u.status != 'banned') PopupMenuItem(value: 'banned', child: Text(l.banUser)),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

/// Read-only list of admin actions (written server side).
class AuditLogView extends ConsumerWidget {
  const AuditLogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return AsyncView(
      value: ref.watch(auditLogProvider),
      onRetry: () => ref.invalidate(auditLogProvider),
      builder: (entries) => entries.isEmpty
          ? EmptyState(l.auditEmpty)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.history),
                  title: Text('${e.action}  ${e.targetType ?? ''} ${e.targetId ?? ''}'),
                  subtitle: Text('${e.actorEmail ?? e.actorId ?? '-'} · ${fmtDateTime(e.createdAt)}'
                      '${e.details.isEmpty ? '' : '\n${jsonEncode(e.details)}'}'),
                );
              },
            ),
    );
  }
}
