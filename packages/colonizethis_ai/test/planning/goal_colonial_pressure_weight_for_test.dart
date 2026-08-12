// Unit tests for `goalColonialPressureWeightFor` — the production goal-score
// colonial-pressure weight derivation used by the pre-prep `strategic_ai.dart`
// goal-eval site (Refs #2847 Phase 3 goal-score wiring).
//
// Spec contract (SPEC/ai/phase-planner-architecture.md § Phase 3 consumer
// wiring — goal-score colonial-pressure floors):
//
//   "The production `strategic_ai.dart` goal-eval site derives
//    `computePhasePriorityWeights`' `expandEconomyPlan` input from
//    `planExpandEconomy(game, snapshot)` ... Sourcing the real EXPAND
//    economy plan — rather than `ExpandEconomyPlan.defaultPlan` — lets the
//    § Resource-need overrides treasury-recovery floor
//    (`newWorldAcquisition = 0.60` ...) lift the goal-score colonial-pressure
//    weight for a below-quota peer-war-locked GP at the goal-scoring layer.
//    ... healthy GPs (treasury never `0`) are unaffected and the gp1/gp2 +6
//    OW baseline holds by construction."
//
// These tests pin:
//
//   1. Below-quota GP with treasury == 0, NW == 0, invadable OW frontier
//      (so `planExpandEconomy` returns `boostTreasuryRecoveryCargo == true`)
//      => weight lifts to the treasury-recovery floor (0.60). This is the
//      NEW behaviour the goal-eval EXPAND-plan sourcing enables; under the
//      old `ExpandEconomyPlan.defaultPlan` path the weight stayed at the
//      0.05 early-sprint curve value.
//   2. Healthy below-quota GP (treasury well above the cheapest regiment
//      cost) => the override does not fire and the curve value (0.05 at
//      OW <= 7) stands (regression guard for the +6 OW baseline).
//   3. At-quota GP (OW >= 10) with treasury == 0 => `planExpandEconomy`
//      short-circuits to `ExpandEconomyPlan.defaultPlan`, so the
//      treasury-recovery override cannot fire and the curve value (0.40 at
//      OW = 10) stands.
//   4. Determinism: identical `(snapshot, game)` inputs yield the same
//      `double` (Refs #2509 Must-have #7).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_priority_weights_test_support.dart';

void main() {
  group('goalColonialPressureWeightFor', () {
    test(
      'below-quota GP at treasury==0, NW==0 lifts to treasury-recovery floor '
      '(0.60) via the real EXPAND plan',
      () {
        // OW = 7 (below quota); curve value here is 0.05. The real
        // `planExpandEconomy` yields `boostTreasuryRecoveryCargo == true`
        // because effective treasury (0) is below the cheapest regiment
        // cost, so the treasury-recovery override fires.
        final weight = goalColonialPressureWeightFor(
          snapshot: phasePriorityWeightsSnapshot(
            oldWorldProvincesOwned: 7,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: phasePriorityWeightsGameWithRegimentsAndTreasury(
            regimentCount: 2,
            treasury: 0,
          ),
        );
        expect(weight, kPhasePriorityNwTreasuryRecoveryFloor);
        expect(
          weight,
          isNot(0.05),
          reason:
              'Old ExpandEconomyPlan.defaultPlan path would have left the '
              'weight at the 0.05 early-sprint curve value.',
        );
      },
    );

    test(
      'healthy below-quota GP (treasury above cheapest regiment cost) keeps '
      'the curve value 0.05 (no override; +6 baseline regression guard)',
      () {
        // Well above the cheapest regiment build cost (catalog min = 2000),
        // so `planExpandEconomy` leaves `boostTreasuryRecoveryCargo == false`
        // and the treasury-recovery override cannot fire.
        const treasury = 100000;
        final weight = goalColonialPressureWeightFor(
          snapshot: phasePriorityWeightsSnapshot(
            oldWorldProvincesOwned: 7,
            treasury: treasury,
            newWorldProvincesOwned: 0,
          ),
          game: phasePriorityWeightsGameWithRegimentsAndTreasury(
            regimentCount: 2,
            treasury: treasury,
          ),
        );
        expect(weight, 0.05);
      },
    );

    test(
      'at-quota GP (OW >= 10) with treasury==0 short-circuits to defaultPlan, '
      'so the override cannot fire and the curve value (0.40) stands',
      () {
        final weight = goalColonialPressureWeightFor(
          snapshot: phasePriorityWeightsSnapshot(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: phasePriorityWeightsGameWithRegimentsAndTreasury(
            regimentCount: 2,
            treasury: 0,
          ),
        );
        expect(weight, 0.40);
      },
    );

    test('identical inputs yield the same weight (Refs #2509 Must-have #7)', () {
      final snapshot = phasePriorityWeightsSnapshot(
        oldWorldProvincesOwned: 7,
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      final game = phasePriorityWeightsGameWithRegimentsAndTreasury(
        regimentCount: 2,
        treasury: 0,
      );
      final first = goalColonialPressureWeightFor(
        snapshot: snapshot,
        game: game,
      );
      final second = goalColonialPressureWeightFor(
        snapshot: snapshot,
        game: game,
      );
      expect(first, second);
    });
  });
}
