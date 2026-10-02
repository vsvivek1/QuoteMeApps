import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/widgets/async_view.dart';
import '../../audit/application/audit_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/outreach_providers.dart';
import '../domain/outreach_models.dart';
import '../domain/outreach_repository.dart';
import '../domain/stage_machine.dart';
import 'stage_labels.dart';

/// Moves a lead through the pipeline after [StageMachine.check] allows it.
/// Returns true when the stage changed.
Future<bool> moveLeadStage(
  BuildContext context,
  WidgetRef ref,
  OutreachLead lead,
  LeadStage to, {
  bool quiet = false,
}) async {
  final l = context.l10n;
  final repo = ref.read(outreachRepositoryProvider);
  var result = StageMachine.check(lead, to);

  if (result.error == TransitionError.needsLoggedContact) {
    if (quiet) return false;
    final logged = await logManualContact(context, ref, lead, intro: l.logContactFirst);
    if (!logged || !context.mounted) return false;
    result = StageMachine.check(lead, to, hasLoggedManualContact: true);
  }
  if (!result.allowed) {
    if (!quiet && context.mounted) context.toast(transitionErrorLabel(context, result.error!), error: true);
    return false;
  }

  String? note;
  if (!quiet) {
    if (to == LeadStage.doNotContact) {
      final ok = await confirmDialog(context,
          title: l.dncTitle(lead.businessName), body: l.dncBody, action: stageLabel(context, to));
      if (!ok) return false;
    } else {
      if (!context.mounted) return false;
      note = await askReason(context, title: l.moveTo(stageLabel(context, to)), hint: l.optionalNote, required: false);
      if (note == null) return false;
    }
  }
  try {
    await repo.moveStage(lead, to, result, note: (note == null || note.isEmpty) ? null : note);
    invalidateOutreach(ref, leadId: lead.id);
    ref
      ..invalidate(dashboardMetricsProvider)
      ..invalidate(auditLogProvider);
    if (!quiet && context.mounted) context.toast(l.movedTo(stageLabel(context, to)));
    return true;
  } catch (e) {
    if (context.mounted) context.toast('$e', error: true);
    return false;
  }
}

/// Logs a call, visit, manual WhatsApp message or note. Returns true if logged.
Future<bool> logManualContact(BuildContext context, WidgetRef ref, OutreachLead lead,
    {String? intro, ManualContact initial = ManualContact.callLogged}) async {
  final l = context.l10n;
  final text = TextEditingController();
  var kind = initial;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.logContactTitle),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (intro != null) ...[Text(intro), const SizedBox(height: 12)],
            SegmentedButton<ManualContact>(
              segments: [
                ButtonSegment(value: ManualContact.callLogged, label: Text(l.contactCall)),
                ButtonSegment(value: ManualContact.visitLogged, label: Text(l.contactVisit)),
                ButtonSegment(value: ManualContact.whatsappManual, label: Text(l.contactWhatsApp)),
                ButtonSegment(value: ManualContact.note, label: Text(l.contactNote)),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() => kind = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: text,
              maxLines: 4,
              decoration: InputDecoration(labelText: l.whatHappened),
              onChanged: (_) => setState(() {}),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            onPressed: text.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    ),
  );
  if (ok != true) return false;
  try {
    await ref.read(outreachRepositoryProvider).logContact(lead.id, kind, text.text.trim());
    invalidateOutreach(ref, leadId: lead.id);
    // A logged contact is a real contact only for calls, visits and 1:1 messages.
    return kind != ManualContact.note;
  } catch (e) {
    if (context.mounted) context.toast('$e', error: true);
    return false;
  }
}
