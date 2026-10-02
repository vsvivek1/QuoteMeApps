import 'composer.dart';
import 'outreach_models.dart';
import 'stage_machine.dart';

/// Server answer from `outreach_can_send` (the database gate).
class ServerGate {
  const ServerGate(this.allowed, this.reason);
  final bool allowed;
  final String reason;
}

class SendResult {
  const SendResult({required this.ok, this.eventId, this.reason});
  final bool ok;
  final String? eventId;
  final String? reason;
}

/// Manual contact types an admin can log (21.3: calls and WhatsApp 1:1 are
/// made by a person and logged).
enum ManualContact { whatsappManual, callLogged, visitLogged, note }

extension ManualContactWire on ManualContact {
  String get eventType => switch (this) {
        ManualContact.whatsappManual => 'whatsapp_manual',
        ManualContact.callLogged => 'call_logged',
        ManualContact.visitLogged => 'visit_logged',
        ManualContact.note => 'note',
      };

  String get channel => switch (this) {
        ManualContact.whatsappManual => 'whatsapp',
        ManualContact.callLogged => 'call',
        ManualContact.visitLogged => 'visit',
        ManualContact.note => 'system',
      };
}

/// Seller acquisition CRM (Section 21). Tables: outreach_leads,
/// outreach_events, outreach_campaigns, outreach_sequences,
/// outreach_inboxes, suppression_list.
abstract interface class OutreachRepository {
  Future<List<OutreachLead>> leads(LeadFilter filter);
  Future<OutreachLead> lead(String id);
  Future<List<OutreachEvent>> events(String leadId);

  /// Applies a stage move that [StageMachine.check] allowed, with its effects.
  Future<OutreachLead> moveStage(OutreachLead lead, LeadStage to, TransitionResult result, {String? note});

  Future<OutreachLead> updateLead(
    String id, {
    String? notes,
    String? nextAction,
    DateTime? nextActionDue,
    bool clearNextAction = false,
  });

  Future<void> logContact(String leadId, ManualContact kind, String text);

  /// Records a WhatsApp opt-in with its proof (21.3).
  Future<OutreachLead> recordOptIn(String leadId, {required String channel, required String proof});

  /// Bulk action: enrol in a campaign (sending still needs a person).
  Future<void> enrol(List<String> leadIds, String campaignId);

  /// `outreach_upsert_lead` per draft (dedupe server side).
  Future<ImportResult> importLeads(List<LeadDraft> drafts);

  Future<List<SuppressionEntry>> suppression();
  Future<void> suppress({String? email, String? emailDomain, String? phone, String? businessKey, required String reason, String? note});
  Future<bool> isSuppressed(OutreachLead lead);

  Future<List<OutreachCampaign>> campaigns();
  Future<void> setCampaignStatus(String campaignId, String status);
  Future<List<OutreachSequence>> sequences();
  Future<List<OutreachInbox>> inboxes();
  Future<SendStats> sendStats();
  Future<List<CoverageCell>> coverage({int minSellers = 5});

  /// The database gate (`outreach_can_send`), re-checked right before sending.
  Future<ServerGate> serverCanSend(String leadId, String channel, String? inboxId);

  /// One manual send through the `outreach-send` Edge Function. The function
  /// re-runs every check, sends via the provider and records the event.
  Future<SendResult> send(OutreachLead lead, OutreachMessage message);
}
