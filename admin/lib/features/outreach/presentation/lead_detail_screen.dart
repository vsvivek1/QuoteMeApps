import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../categories/application/category_providers.dart';
import '../application/outreach_providers.dart';
import '../domain/composer.dart';
import '../domain/outreach_models.dart';
import '../domain/outreach_repository.dart';
import '../domain/stage_machine.dart';
import 'send_dialog.dart';
import 'stage_actions.dart';
import 'stage_labels.dart';

class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key, required this.leadId});
  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lead = ref.watch(leadDetailProvider(leadId));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.outreach)),
        title: Text(lead.value?.businessName ?? l.lead),
      ),
      body: AsyncView(
        value: lead,
        onRetry: () => ref.invalidate(leadDetailProvider(leadId)),
        builder: (lead) => LayoutBuilder(
          builder: (context, box) {
            final left = _LeadInfo(lead);
            final right = _History(lead);
            if (box.maxWidth < 1000) {
              return ListView(padding: const EdgeInsets.all(16), children: [left, const SizedBox(height: 16), right]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [left])),
              Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [right])),
            ]);
          },
        ),
      ),
    );
  }
}

class _LeadInfo extends ConsumerStatefulWidget {
  const _LeadInfo(this.lead);
  final OutreachLead lead;

  @override
  ConsumerState<_LeadInfo> createState() => _LeadInfoState();
}

class _LeadInfoState extends ConsumerState<_LeadInfo> {
  late final _notes = TextEditingController(text: widget.lead.notes ?? '');
  late final _next = TextEditingController(text: widget.lead.nextAction ?? '');
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    _due = widget.lead.nextActionDue;
  }

  @override
  void dispose() {
    _notes.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    final l = context.l10n;
    try {
      await ref.read(outreachRepositoryProvider).updateLead(
            widget.lead.id,
            notes: _notes.text,
            nextAction: _next.text.trim().isEmpty ? null : _next.text.trim(),
            nextActionDue: _due,
            clearNextAction: _next.text.trim().isEmpty && _due == null,
          );
      invalidateOutreach(ref, leadId: widget.lead.id);
      if (mounted) context.toast(l.saved);
    } catch (e) {
      if (mounted) context.toast('$e', error: true);
    }
  }

  Future<void> _whatsApp() async {
    final l = context.l10n;
    final config = ref.read(countryConfigProvider);
    final lead = widget.lead;
    final cats = ref.read(categoryIndexProvider).value ?? const {};
    final cat = lead.matchedCategoryIds.isEmpty ? '' : (cats[lead.matchedCategoryIds.first]?.name() ?? '');
    final text = l.whatsAppPitch(lead.businessName, config.appName, cat, lead.city ?? '',
        config.signupUrl(source: 'whatsapp', medium: 'manual', city: lead.city, category: cat, token: lead.signupToken).toString());
    final ok = await confirmDialog(context, title: l.whatsAppManualTitle, body: '${l.whatsAppManualBody}\n\n$text');
    if (!ok) return;
    await launchUrl(OutreachComposer(config).whatsAppLink(lead, text), webOnlyWindowName: '_blank');
    await ref.read(outreachRepositoryProvider).logContact(lead.id, ManualContact.whatsappManual, text);
    invalidateOutreach(ref, leadId: lead.id);
  }

  Future<void> _optIn() async {
    final l = context.l10n;
    final proof = await askReason(context, title: l.recordOptIn, hint: l.optInProofHint);
    if (proof == null) return;
    await ref.read(outreachRepositoryProvider).recordOptIn(widget.lead.id, channel: 'manual', proof: proof);
    invalidateOutreach(ref, leadId: widget.lead.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lead = widget.lead;
    final config = ref.watch(countryConfigProvider);
    final cats = ref.watch(categoryIndexProvider).value ?? const {};
    final t = Theme.of(context).textTheme;
    final next = StageMachine.nextStages(lead.stage);

    Widget row(String k, String? v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 150, child: Text(k, style: t.labelMedium)),
            Expanded(child: SelectableText(v ?? '-')),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.circle, size: 12, color: stageColor(context, lead.stage)),
              const SizedBox(width: 8),
              Text(stageLabel(context, lead.stage), style: t.titleMedium),
              const Spacer(),
              Text(l.touches(lead.touchesSent)),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in next)
                OutlinedButton(
                  onPressed: () => moveLeadStage(context, ref, lead, s),
                  child: Text(l.moveTo(stageLabel(context, s))),
                ),
            ]),
            const Divider(height: 24),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: () => showSendDialog(context, lead),
                icon: const Icon(Icons.send),
                label: Text(l.prepareSend(lead.touchesSent + 1)),
              ),
              if (config.manualWhatsAppFirstContact && lead.phone != null)
                OutlinedButton.icon(onPressed: _whatsApp, icon: const Icon(Icons.chat), label: Text(l.whatsAppManual)),
              OutlinedButton.icon(
                onPressed: () => logManualContact(context, ref, lead),
                icon: const Icon(Icons.edit_note),
                label: Text(l.logContactTitle),
              ),
              if (lead.whatsappOptInAt == null && lead.phone != null)
                OutlinedButton(onPressed: _optIn, child: Text(l.recordOptIn)),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.contact, style: t.titleSmall),
            row(l.email, lead.email == null ? null : '${lead.email} (${lead.emailStatus.name})'),
            row(l.phone, lead.phone),
            row(l.website, lead.website),
            row(l.address, [lead.address, lead.city, lead.state, lead.postalCode].whereType<String>().join(', ')),
            row(l.rating, lead.rating == null ? null : '${lead.rating} (${lead.ratingCount ?? 0})'),
            row(l.categories, lead.matchedCategoryIds.map((id) => cats[id]?.name() ?? '#$id').join(', ')),
            row(l.sourceCategories, lead.categoriesSource.join(', ')),
            const SizedBox(height: 12),
            Text(l.compliance, style: t.titleSmall),
            row(l.source, '${lead.source.name}${lead.sourceRef == null ? '' : ' · ${lead.sourceRef}'}'),
            row(l.lawfulBasis, lead.lawfulBasis.wire),
            row(l.addressSource, lead.addressSource),
            row(l.reasonChosen, lead.chosenReason),
            row(l.optIn, lead.whatsappOptInAt == null
                ? null
                : '${fmtDateTime(lead.whatsappOptInAt)} · ${lead.whatsappOptInChannel} · ${lead.whatsappOptInProof}'),
            row(l.sequence, '${lead.sequenceStatus.name} · ${l.campaign}: ${lead.campaignId ?? '-'}'),
            row(l.sellerAccount, lead.sellerId),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.notesAndNextAction, style: t.titleSmall),
            const SizedBox(height: 8),
            TextField(controller: _notes, maxLines: 4, decoration: InputDecoration(labelText: l.notes)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _next, decoration: InputDecoration(labelText: l.nextAction))),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 365)),
                    initialDate: _due ?? now,
                  );
                  if (d != null) setState(() => _due = d);
                },
                child: Text(_due == null ? l.dueDate : fmtDate(_due)),
              ),
            ]),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _saveNotes, child: Text(l.save))),
          ]),
        ),
      ),
    ]);
  }
}

class _History extends ConsumerWidget {
  const _History(this.lead);
  final OutreachLead lead;

  IconData _icon(String type) => switch (type) {
        'sent' => Icons.send,
        'replied' => Icons.reply,
        'bounced' || 'soft_bounced' => Icons.error_outline,
        'unsubscribed' || 'complained' || 'negative_reply' => Icons.block,
        'whatsapp_manual' => Icons.chat,
        'call_logged' => Icons.call,
        'visit_logged' => Icons.storefront,
        'stage_change' => Icons.swap_horiz,
        _ => Icons.notes,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.history, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          AsyncView(
            value: ref.watch(leadEventsProvider(lead.id)),
            builder: (events) => events.isEmpty
                ? Padding(padding: const EdgeInsets.all(16), child: Text(l.noHistory))
                : Column(children: [
                    for (final e in events)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_icon(e.eventType), size: 20),
                        title: Text([
                          e.eventType,
                          e.channel,
                          if (e.sequenceStep != null) l.stepN(e.sequenceStep!),
                          if (e.meta['to'] != null) '${e.meta['from']} → ${e.meta['to']}',
                        ].join(' · ')),
                        subtitle: Text([
                          fmtDateTime(e.createdAt),
                          if (e.subject != null) e.subject!,
                          if (e.bodyPreview != null) e.bodyPreview!,
                          if (e.eventType == 'sent') '${l.reasonChosen}: ${e.reasonChosen ?? '-'} · ${e.lawfulBasis ?? '-'}',
                        ].join('\n')),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}
