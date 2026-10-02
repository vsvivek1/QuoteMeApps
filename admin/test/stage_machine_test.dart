import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/features/outreach/domain/outreach_models.dart';
import 'package:iwant_admin/features/outreach/domain/stage_machine.dart';

import 'helpers.dart';

void main() {
  OutreachLead at(LeadStage s, {String? sellerId, SequenceStatus seq = SequenceStatus.active}) =>
      goodLead().copyWith(stage: s, sellerId: sellerId, sequenceStatus: seq);

  group('StageMachine (Section 21.5)', () {
    test('happy path moves forward through the pipeline', () {
      var lead = at(LeadStage.contacted);
      for (final to in [LeadStage.replied, LeadStage.onboarding]) {
        final r = StageMachine.check(lead, to);
        expect(r.allowed, isTrue, reason: '${lead.stage} -> $to');
        lead = StageMachine.apply(lead, to, r);
      }
      lead = lead.copyWith(sellerId: 'seller-1');
      for (final to in [LeadStage.liveSeller, LeadStage.active]) {
        final r = StageMachine.check(lead, to);
        expect(r.allowed, isTrue, reason: '${lead.stage} -> $to');
        lead = StageMachine.apply(lead, to, r);
      }
      expect(lead.stage, LeadStage.active);
    });

    test('never moves backwards (no restarting a finished conversation)', () {
      for (final from in [LeadStage.contacted, LeadStage.replied, LeadStage.onboarding, LeadStage.notInterested]) {
        expect(StageMachine.check(at(from), LeadStage.sourced).error, TransitionError.notAllowed);
      }
      expect(StageMachine.check(at(LeadStage.replied), LeadStage.contacted).error, TransitionError.notAllowed);
      expect(StageMachine.check(at(LeadStage.notInterested), LeadStage.contacted).error, TransitionError.notAllowed);
    });

    test('do not contact is terminal', () {
      for (final to in LeadStage.values.where((s) => s != LeadStage.doNotContact)) {
        expect(StageMachine.check(at(LeadStage.doNotContact), to).error, TransitionError.terminal);
      }
    });

    test('do not contact is reachable from every other stage and suppresses', () {
      for (final from in LeadStage.values.where((s) => s != LeadStage.doNotContact)) {
        final r = StageMachine.check(at(from), LeadStage.doNotContact);
        expect(r.allowed, isTrue, reason: '$from');
        expect(r.effects, containsAll([TransitionEffect.suppress, TransitionEffect.stopSequence, TransitionEffect.logEvent]));
      }
    });

    test('live seller and active need a linked seller account', () {
      expect(StageMachine.check(at(LeadStage.onboarding), LeadStage.liveSeller).error, TransitionError.needsSellerLink);
      expect(StageMachine.check(at(LeadStage.onboarding, sellerId: 's'), LeadStage.liveSeller).allowed, isTrue);
      expect(StageMachine.check(at(LeadStage.onboarding, sellerId: 's'), LeadStage.active).error, TransitionError.notAllowed);
    });

    test('manual move to contacted needs a logged contact', () {
      final lead = at(LeadStage.sourced, seq: SequenceStatus.none);
      expect(StageMachine.check(lead, LeadStage.contacted).error, TransitionError.needsLoggedContact);
      expect(StageMachine.check(lead, LeadStage.contacted, hasLoggedManualContact: true).allowed, isTrue);
    });

    test('a human reply or not-interested stops the automated sequence', () {
      final r = StageMachine.check(at(LeadStage.contacted), LeadStage.replied);
      expect(r.effects, contains(TransitionEffect.stopSequence));
      final next = StageMachine.apply(at(LeadStage.contacted), LeadStage.replied, r);
      expect(next.sequenceStatus, SequenceStatus.stopped);
      final ni = StageMachine.check(at(LeadStage.contacted), LeadStage.notInterested);
      expect(ni.effects, contains(TransitionEffect.stopSequence));
      expect(ni.effects, isNot(contains(TransitionEffect.suppress)));
    });

    test('same stage is refused and apply() refuses a refused transition', () {
      final r = StageMachine.check(at(LeadStage.replied), LeadStage.replied);
      expect(r.error, TransitionError.noChange);
      expect(() => StageMachine.apply(at(LeadStage.replied), LeadStage.replied, r), throwsStateError);
    });

    test('wire values match the database check constraint', () {
      expect(LeadStage.values.map((s) => s.wire), [
        'sourced', 'contacted', 'replied', 'onboarding', 'live_seller', 'active', 'not_interested', 'do_not_contact',
      ]);
      for (final s in LeadStage.values) {
        expect(LeadStage.fromWire(s.wire), s);
      }
    });
  });
}
