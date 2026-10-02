import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';

/// Report anything (user, seller, request, quote, message, review).
Future<void> showReportSheet(BuildContext context, WidgetRef ref,
    {required String targetType, required String targetId}) async {
  final l10n = context.l10n;
  final reasons = {
    'spam': l10n.reportReasonSpam,
    'abuse': l10n.reportReasonAbuse,
    'fake': l10n.reportReasonFake,
    'prohibited': l10n.reportReasonProhibited,
    'other': l10n.reportReasonOther,
  };
  String reason = 'spam';
  final details = TextEditingController();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.reportTitle, style: ctx.text.titleLarge),
          RadioGroup<String>(
            groupValue: reason,
            onChanged: (v) => set(() => reason = v ?? reason),
            child: Column(children: [
              for (final e in reasons.entries) RadioListTile<String>(value: e.key, title: Text(e.value)),
            ]),
          ),
          TextField(controller: details, maxLines: 3, decoration: InputDecoration(labelText: l10n.reportDetails)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.report)),
        ]),
      ),
    ),
  );
  if (ok != true) return;
  await ref.read(safetyRepositoryProvider).report(targetType, targetId, reason,
      details: details.text.trim().isEmpty ? null : details.text.trim());
  if (context.mounted) context.toast(l10n.reportSent);
}

Future<bool> confirmBlock(BuildContext context, WidgetRef ref, {required String userId, required String name}) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(l10n.blockConfirm(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.block)),
      ],
    ),
  );
  if (ok != true) return false;
  await ref.read(safetyRepositoryProvider).block(userId);
  if (context.mounted) context.toast(l10n.blocked);
  return true;
}
