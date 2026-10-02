import 'outreach_models.dart';

/// Why a stage move was refused.
enum TransitionError {
  /// Same stage.
  noChange,

  /// Not an edge of the pipeline (e.g. moving back to `sourced`, which would
  /// restart a finished conversation; rule 21.8-2).
  notAllowed,

  /// `do_not_contact` is permanent; only the backend may change it.
  terminal,

  /// `live_seller` / `active` need the lead linked to a seller account.
  needsSellerLink,

  /// Moving to `contacted` by hand needs a logged manual contact (call,
  /// visit, WhatsApp 1:1); automated sends move it on their own.
  needsLoggedContact,
}

/// What the repository must do alongside the stage change.
enum TransitionEffect {
  /// Insert a `stage_change` event (audit trail).
  logEvent,

  /// Stop any running sequence (`sequence_status = stopped`).
  stopSequence,

  /// Add the business to the shared suppression list.
  suppress,
}

class TransitionResult {
  const TransitionResult.ok(this.effects) : error = null;
  const TransitionResult.refused(this.error) : effects = const {};

  final TransitionError? error;
  final Set<TransitionEffect> effects;
  bool get allowed => error == null;
}

/// CRM pipeline (Section 21.5):
/// `sourced -> contacted -> replied -> onboarding -> live seller -> active`,
/// plus `not interested` and `do not contact` from anywhere before the end.
///
/// The pipeline only moves forward: a lead never goes back to `sourced` or
/// `contacted`, so a conversation that ended is never restarted (21.8-2).
abstract final class StageMachine {
  static const Map<LeadStage, Set<LeadStage>> edges = {
    LeadStage.sourced: {
      LeadStage.contacted,
      LeadStage.replied, // inbound reply / walk-in before any send
      LeadStage.notInterested,
      LeadStage.doNotContact,
    },
    LeadStage.contacted: {
      LeadStage.replied,
      LeadStage.onboarding,
      LeadStage.notInterested,
      LeadStage.doNotContact,
    },
    LeadStage.replied: {
      LeadStage.onboarding,
      LeadStage.notInterested,
      LeadStage.doNotContact,
    },
    LeadStage.onboarding: {
      LeadStage.liveSeller,
      LeadStage.notInterested,
      LeadStage.doNotContact,
    },
    LeadStage.liveSeller: {
      LeadStage.active,
      LeadStage.doNotContact,
    },
    LeadStage.active: {
      LeadStage.doNotContact,
    },
    LeadStage.notInterested: {
      // They came back on their own (inbound reply).
      LeadStage.replied,
      LeadStage.doNotContact,
    },
    LeadStage.doNotContact: {},
  };

  /// Stages the kanban shows, in order.
  static const board = LeadStage.values;

  static Set<LeadStage> nextStages(LeadStage from) => edges[from] ?? const {};

  static TransitionResult check(
    OutreachLead lead,
    LeadStage to, {
    bool hasLoggedManualContact = false,
  }) {
    final from = lead.stage;
    if (from == to) return const TransitionResult.refused(TransitionError.noChange);
    if (from == LeadStage.doNotContact) return const TransitionResult.refused(TransitionError.terminal);
    if (!nextStages(from).contains(to)) return const TransitionResult.refused(TransitionError.notAllowed);
    if ((to == LeadStage.liveSeller || to == LeadStage.active) && lead.sellerId == null) {
      return const TransitionResult.refused(TransitionError.needsSellerLink);
    }
    if (to == LeadStage.contacted && !hasLoggedManualContact) {
      return const TransitionResult.refused(TransitionError.needsLoggedContact);
    }
    final effects = <TransitionEffect>{TransitionEffect.logEvent};
    switch (to) {
      case LeadStage.replied:
      case LeadStage.onboarding:
      case LeadStage.liveSeller:
      case LeadStage.active:
      case LeadStage.notInterested:
        // Any human conversation ends the automated sequence for good.
        if (lead.sequenceStatus == SequenceStatus.active || lead.sequenceStatus == SequenceStatus.none) {
          effects.add(TransitionEffect.stopSequence);
        }
      case LeadStage.doNotContact:
        effects
          ..add(TransitionEffect.stopSequence)
          ..add(TransitionEffect.suppress);
      case LeadStage.sourced:
      case LeadStage.contacted:
        break;
    }
    return TransitionResult.ok(effects);
  }

  /// Applies a transition to an in-memory lead (demo backend and tests).
  static OutreachLead apply(OutreachLead lead, LeadStage to, TransitionResult result) {
    if (!result.allowed) {
      throw StateError('Transition ${lead.stage.wire} -> ${to.wire} refused: ${result.error}');
    }
    var next = lead.copyWith(stage: to);
    if (result.effects.contains(TransitionEffect.stopSequence)) {
      next = next.copyWith(sequenceStatus: SequenceStatus.stopped);
    }
    return next;
  }
}
