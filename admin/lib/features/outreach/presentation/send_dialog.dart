import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../audit/application/audit_providers.dart';
import '../../brochures/application/brochure_providers.dart';
import '../../categories/application/category_providers.dart';
import '../../flags/application/settings_providers.dart';
import '../application/outreach_providers.dart';
import '../domain/anti_spam.dart';
import '../domain/composer.dart';
import '../domain/outreach_models.dart';
import 'stage_labels.dart';

/// Opens the manual send dialog for the lead's next sequence step.
Future<void> showSendDialog(BuildContext context, OutreachLead lead) =>
    showDialog<void>(context: context, builder: (_) => _SendDialog(lead));

class _SendDialog extends ConsumerStatefulWidget {
  const _SendDialog(this.lead);
  final OutreachLead lead;

  @override
  ConsumerState<_SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends ConsumerState<_SendDialog> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  final _template = TextEditingController();
  String _channel = 'email';
  String? _inboxId;
  int? _categoryId;
  int _variant = 0;
  bool _confirmed = false;
  bool _loaded = false;
  bool _sending = false;
  bool _suppressed = false;
  String? _serverGate;

  OutreachCampaign? _campaign;
  OutreachSequence? _sequence;
  List<OutreachInbox> _inboxes = const [];
  SendStats? _stats;
  String? _foundingUntil;
  String? _brochureLink;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    _template.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(outreachRepositoryProvider);
    final lead = widget.lead;
    final campaigns = await ref.read(campaignsProvider.future);
    final sequences = await ref.read(sequencesProvider.future);
    _inboxes = await ref.read(inboxesProvider.future);
    _stats = await ref.read(sendStatsProvider.future);
    _suppressed = await repo.isSuppressed(lead);
    final settings = await ref.read(appSettingsProvider.future);
    final until = settings.where((s) => s.key == 'early_partner_free_until').firstOrNull?.value;
    _foundingUntil = until is String ? fmtDate(DateTime.tryParse(until)) : null;
    _campaign = campaigns.where((c) => c.id == lead.campaignId).firstOrNull;
    _sequence = _campaign == null ? null : sequences.where((s) => s.id == _campaign!.sequenceId).firstOrNull;
    _inboxId = _inboxes.where((i) => i.active).firstOrNull?.id;
    final relevant = lead.matchedCategoryIds
        .where((id) => _campaign == null || _campaign!.categoryIds.isEmpty || _campaign!.categoryIds.contains(id));
    _categoryId = relevant.firstOrNull ?? lead.matchedCategoryIds.firstOrNull;
    final brochures = await ref.read(brochureListProvider.future);
    _brochureLink = brochures
        .where((b) => b.cityName == lead.city && b.categoryId == _categoryId && b.publicUrl != null)
        .firstOrNull
        ?.publicUrl;
    _render();
    if (mounted) setState(() => _loaded = true);
  }

  void _render() {
    final lead = widget.lead;
    final config = ref.read(countryConfigProvider);
    final composer = OutreachComposer(config);
    final step = lead.touchesSent + 1;
    final cats = ref.read(categoryIndexProvider).value ?? const {};
    final catName = _categoryId == null ? '' : (cats[_categoryId]?.name() ?? '');
    final inbox = _inboxes.where((i) => i.id == _inboxId).firstOrNull;
    final seqStep = (_sequence != null && step <= _sequence!.steps.length) ? _sequence!.steps[step - 1] : null;
    if (seqStep == null || seqStep.variants.isEmpty) {
      _subject.text = '';
      _body.text = '';
      return;
    }
    _variant = composer.variantFor(lead, step, seqStep.variants.length);
    final v = seqStep.variants[_variant];
    String r(String s) => composer.render(s, lead,
        categoryName: catName,
        senderName: inbox?.displayName ?? '',
        brochureLink: _brochureLink,
        foundingUntil: _foundingUntil,
        campaign: _campaign?.name);
    _subject.text = r(v.subject);
    _body.text = r(v.body);
  }

  OutreachMessage _message() {
    final config = ref.read(countryConfigProvider);
    final cats = ref.read(categoryIndexProvider).value ?? const {};
    final inbox = _inboxes.where((i) => i.id == _inboxId).firstOrNull;
    return OutreachMessage(
      channel: _channel,
      step: widget.lead.touchesSent + 1,
      subject: _subject.text,
      body: _body.text,
      footer: OutreachComposer(config).footer(
        senderName: inbox?.displayName ?? '',
        businessAddress: _stats?.businessAddress ?? '',
        unsubscribeToken: widget.lead.unsubscribeToken,
      ),
      variantIndex: _variant,
      categoryId: _categoryId,
      categoryName: _categoryId == null ? null : cats[_categoryId]?.name(),
      inboxId: _channel == 'email' ? _inboxId : null,
      campaignId: _campaign?.id,
      whatsappTemplate: _channel == 'whatsapp' ? _template.text.trim() : null,
      confirmedByAdmin: _confirmed,
    );
  }

  AntiSpamReport? _report() {
    if (!_loaded || _stats == null) return null;
    return AntiSpam.check(
      widget.lead,
      _message(),
      SendContext(
        config: ref.read(countryConfigProvider),
        stats: _stats!,
        now: DateTime.now(),
        isSuppressed: _suppressed,
        campaign: _campaign,
        sequence: _sequence,
        inbox: _channel == 'email' ? _inboxes.where((i) => i.id == _inboxId).firstOrNull : null,
      ),
    );
  }

  Future<void> _send() async {
    final l = context.l10n;
    final repo = ref.read(outreachRepositoryProvider);
    setState(() {
      _sending = true;
      _serverGate = null;
    });
    try {
      // The database gate decides last, right before sending.
      final gate = await repo.serverCanSend(widget.lead.id, _channel, _channel == 'email' ? _inboxId : null);
      if (!gate.allowed) {
        setState(() => _serverGate = gate.reason);
        return;
      }
      final res = await repo.send(widget.lead, _message());
      if (!res.ok) {
        setState(() => _serverGate = res.reason ?? 'refused');
        return;
      }
      invalidateOutreach(ref, leadId: widget.lead.id);
      ref.invalidate(auditLogProvider);
      if (mounted) {
        Navigator.pop(context);
        context.toast(l.sent);
      }
    } catch (e) {
      if (mounted) setState(() => _serverGate = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final report = _report();
    final cats = ref.watch(categoryIndexProvider).value ?? const {};
    return AlertDialog(
      title: Text(l.sendTitle(widget.lead.businessName, widget.lead.touchesSent + 1)),
      content: SizedBox(
        width: 900,
        child: !_loaded
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Wrap(spacing: 24, runSpacing: 16, children: [
                  SizedBox(
                    width: 480,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l.neverAutomatic, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Wrap(spacing: 12, runSpacing: 8, children: [
                        if (config.outreachChannels.length > 1)
                          SegmentedButton<String>(
                            segments: [for (final c in config.outreachChannels) ButtonSegment(value: c, label: Text(c))],
                            selected: {_channel},
                            onSelectionChanged: (s) => setState(() => _channel = s.first),
                          ),
                        if (_channel == 'email')
                          SizedBox(
                            width: 230,
                            child: DropdownButtonFormField<String>(
                              initialValue: _inboxId,
                              isExpanded: true,
                              decoration: InputDecoration(labelText: l.inbox),
                              items: [
                                for (final i in _inboxes)
                                  DropdownMenuItem(value: i.id, child: Text(i.email, overflow: TextOverflow.ellipsis)),
                              ],
                              onChanged: (v) => setState(() {
                                _inboxId = v;
                                _render();
                              }),
                            ),
                          ),
                        SizedBox(
                          width: 200,
                          child: DropdownButtonFormField<int>(
                            initialValue: _categoryId,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: l.category),
                            items: [
                              for (final id in widget.lead.matchedCategoryIds)
                                DropdownMenuItem(value: id, child: Text(cats[id]?.name() ?? '#$id')),
                            ],
                            onChanged: (v) => setState(() {
                              _categoryId = v;
                              _render();
                            }),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      if (_channel == 'whatsapp')
                        TextField(
                          controller: _template,
                          decoration: InputDecoration(labelText: l.approvedTemplate),
                          onChanged: (_) => setState(() {}),
                        )
                      else
                        TextField(
                          controller: _subject,
                          decoration: InputDecoration(labelText: l.subject),
                          onChanged: (_) => setState(() {}),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _body,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: l.body,
                          helperText: l.wordCount(AntiSpam.wordCount(_body.text), AntiSpam.maxWords),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(l.footerPreview, style: Theme.of(context).textTheme.labelMedium),
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Text(_message().footer, style: Theme.of(context).textTheme.bodySmall),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _confirmed,
                        onChanged: (v) => setState(() => _confirmed = v ?? false),
                        title: Text(l.confirmPersonalSend),
                      ),
                    ]),
                  ),
                  SizedBox(width: 340, child: _Checklist(report: report, serverGate: _serverGate)),
                ]),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton.icon(
          onPressed: (report?.allowed ?? false) && !_sending ? _send : null,
          icon: const Icon(Icons.send),
          label: Text(l.sendNow),
        ),
      ],
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.report, required this.serverGate});
  final AntiSpamReport? report;
  final String? serverGate;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = report;
    final scheme = Theme.of(context).colorScheme;
    if (r == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.antiSpamChecks, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      for (var rule = 0; rule <= 11; rule++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(r.rulePassed(rule) ? Icons.check_circle : Icons.cancel,
                size: 18, color: r.rulePassed(rule) ? Colors.green.shade600 : scheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ruleTitle(context, rule)),
                for (final v in r.violations.where((v) => v.rule == rule))
                  Text(
                    '${v.severity == Severity.warn ? '${l.warning}: ' : ''}${v.code}${v.detail == null ? '' : ' (${v.detail})'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: v.severity == Severity.warn ? scheme.tertiary : scheme.error),
                  ),
              ]),
            ),
          ]),
        ),
      if (serverGate != null) ...[
        const SizedBox(height: 8),
        Text(l.serverRefused(serverGate!), style: TextStyle(color: scheme.error)),
      ],
    ]);
  }
}
