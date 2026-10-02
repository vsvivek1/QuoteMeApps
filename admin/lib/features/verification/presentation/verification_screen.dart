import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../../categories/application/category_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/verification_providers.dart';
import '../domain/verification_models.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final queue = ref.watch(verificationQueueProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navVerification),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(verificationQueueProvider),
          ),
        ],
      ),
      body: AsyncView(
        value: queue,
        onRetry: () => ref.invalidate(verificationQueueProvider),
        builder: (items) => items.isEmpty
            ? EmptyState(l.verificationEmpty, icon: Icons.verified_outlined)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ItemCard(items[i]),
              ),
      ),
    );
  }
}

class _ItemCard extends ConsumerStatefulWidget {
  const _ItemCard(this.item);
  final VerificationItem item;

  @override
  ConsumerState<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<_ItemCard> {
  bool _busy = false;

  Future<void> _open() async {
    final l = context.l10n;
    final path = widget.item.filePath;
    if (path == null) return;
    try {
      final url = await ref.read(verificationRepositoryProvider).documentUrl(path);
      if (url == null) {
        if (mounted) context.toast(l.docNotAvailableDemo);
        return;
      }
      await launchUrl(url, webOnlyWindowName: '_blank');
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    }
  }

  Future<void> _review(bool approve) async {
    final l = context.l10n;
    String? reason;
    if (!approve) {
      reason = await askReason(context, title: l.rejectTitle, hint: l.rejectHint);
      if (reason == null) return;
    } else if (!await confirmDialog(context, title: l.approveTitle, body: l.approveBody(widget.item.businessName))) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(verificationRepositoryProvider).review(widget.item, approve: approve, reason: reason);
      ref
        ..invalidate(verificationQueueProvider)
        ..invalidate(dashboardMetricsProvider)
        ..invalidate(auditLogProvider);
      if (mounted) context.toast(approve ? l.approved : l.rejected);
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final it = widget.item;
    final cats = ref.watch(categoryIndexProvider).value ?? const {};
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 420,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(it.kind == VerificationKind.licence ? Icons.badge_outlined : Icons.description_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text(it.businessName, style: t.titleMedium)),
                ]),
                const SizedBox(height: 6),
                Text('${it.kind == VerificationKind.licence ? l.licence : l.document}: ${it.docType}'
                    '${it.docNumber == null ? '' : '  #${it.docNumber}'}'),
                if (it.issuer != null) Text('${l.issuer}: ${it.issuer}'),
                if (it.expiresAt != null) Text('${l.expires}: ${fmtDate(it.expiresAt)}'),
                if (it.categoryIds.isNotEmpty)
                  Text('${l.categories}: ${it.categoryIds.map((id) => cats[id]?.name() ?? '#$id').join(', ')}'),
                Text('${[it.city, it.state].whereType<String>().join(', ')} · ${l.submitted} ${fmtDateTime(it.submittedAt)}',
                    style: t.bodySmall),
                if (it.sellerStatus != null) Text('${l.sellerStatus}: ${it.sellerStatus}', style: t.bodySmall),
              ]),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                onPressed: it.filePath == null ? null : _open,
                icon: const Icon(Icons.open_in_new),
                label: Text(it.filePath == null ? l.noFile : l.viewDocument),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.seller(it.sellerId)),
                icon: const Icon(Icons.storefront_outlined),
                label: Text(l.openSeller),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : () => _review(true),
                icon: const Icon(Icons.check),
                label: Text(l.approve),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _review(false),
                icon: const Icon(Icons.close),
                label: Text(l.reject),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
