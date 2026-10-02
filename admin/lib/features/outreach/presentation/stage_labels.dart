import 'package:flutter/material.dart';

import '../../../core/utils/context_x.dart';
import '../domain/outreach_models.dart';
import '../domain/stage_machine.dart';

String stageLabel(BuildContext context, LeadStage s) {
  final l = context.l10n;
  return switch (s) {
    LeadStage.sourced => l.stageSourced,
    LeadStage.contacted => l.stageContacted,
    LeadStage.replied => l.stageReplied,
    LeadStage.onboarding => l.stageOnboarding,
    LeadStage.liveSeller => l.stageLiveSeller,
    LeadStage.active => l.stageActive,
    LeadStage.notInterested => l.stageNotInterested,
    LeadStage.doNotContact => l.stageDoNotContact,
  };
}

Color stageColor(BuildContext context, LeadStage s) {
  final c = Theme.of(context).colorScheme;
  return switch (s) {
    LeadStage.liveSeller || LeadStage.active => Colors.green.shade600,
    LeadStage.replied || LeadStage.onboarding => c.primary,
    LeadStage.notInterested => c.outline,
    LeadStage.doNotContact => c.error,
    _ => c.secondary,
  };
}

String transitionErrorLabel(BuildContext context, TransitionError e) {
  final l = context.l10n;
  return switch (e) {
    TransitionError.noChange => l.trNoChange,
    TransitionError.notAllowed => l.trNotAllowed,
    TransitionError.terminal => l.trTerminal,
    TransitionError.needsSellerLink => l.trNeedsSellerLink,
    TransitionError.needsLoggedContact => l.trNeedsLoggedContact,
  };
}

/// Rule titles of the Section 21.8 rulebook (0 = "never automatic").
String ruleTitle(BuildContext context, int rule) {
  final l = context.l10n;
  return switch (rule) {
    0 => l.rule0,
    1 => l.rule1,
    2 => l.rule2,
    3 => l.rule3,
    4 => l.rule4,
    5 => l.rule5,
    6 => l.rule6,
    7 => l.rule7,
    8 => l.rule8,
    9 => l.rule9,
    10 => l.rule10,
    _ => l.rule11,
  };
}
