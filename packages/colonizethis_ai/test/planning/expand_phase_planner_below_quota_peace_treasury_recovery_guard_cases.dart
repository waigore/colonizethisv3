// Precondition fall-through + determinism pins for `isBelowQuotaPeaceTreasuryRecovery` (Refs #2509 S1; #4669 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void registerExpandPhasePlannerBelowQuotaPeaceTreasuryRecoveryGuardCases() {
  group('isBelowQuotaPeaceTreasuryRecovery (canonical) — guards', () {
    test(
      'Arm B precondition fall-through: at-war drops composite to false',
      () {
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
            regimentCount: 3,
            atWarWithAnyGreatPower: true,
            hasInvadableProvinces: true,
            treasury: 0,
            stockpile: const Stockpile(),
          ),
          isFalse,
          reason:
              'An at-war GP exits the EXPAND-trap recovery composite via the '
              'Arm B precondition; treasury short-circuiting must not fire '
              'in this branch.',
        );
      },
    );

    test(
      'Arm B precondition fall-through: regimentCount at floor drops to false',
      () {
        expect(
          isBelowQuotaPeaceTreasuryRecovery(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
            regimentCount: kBelowQuotaPeaceMinRegimentsBeforeDeclareWar,
            atWarWithAnyGreatPower: false,
            hasInvadableProvinces: true,
            treasury: 0,
            stockpile: const Stockpile(),
          ),
          isFalse,
          reason:
              'At the at-peace declare-war floor the GP exits the trap; '
              'composite must report false so the planner resumes '
              'declare-war planning instead of cargo-recovery cargo.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      final first = isBelowQuotaPeaceTreasuryRecovery(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        regimentCount: 3,
        atWarWithAnyGreatPower: false,
        hasInvadableProvinces: true,
        treasury: 0,
        stockpile: const Stockpile(),
      );
      final second = isBelowQuotaPeaceTreasuryRecovery(
        oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 2,
        regimentCount: 3,
        atWarWithAnyGreatPower: false,
        hasInvadableProvinces: true,
        treasury: 0,
        stockpile: const Stockpile(),
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical results on repeated calls — '
            'required by issue #2509 Must-have #7 (phase planners are pure '
            'functions with deterministic inputs).',
      );
    });
  });
}
