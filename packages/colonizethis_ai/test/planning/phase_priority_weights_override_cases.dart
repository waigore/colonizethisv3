// Case bodies for `phase_priority_weights_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for the soft-phase priority weight scaffolding in
// `packages/colonizethis_ai/lib/src/planning/phase_priority_weights.dart`
// (Refs #2847 Phase 1 — weight system core).
//
// Spec contract (issue #2847 § Soft-phase priority weights;
// SPEC/ai/phase-planner-architecture.md § Soft-phase priority weights):
//
//   "Replace the binary EXPAND vs COLONIAL transition at OW=10 with a
//    weight curve where NW priority scales from ~5% at OW=7 to ~80% at
//    OW=13. Resource-need overrides raise weight floors when the
//    snapshot indicates a GP cannot bootstrap OW conquest without an
//    income or regiment lift. `oldWorldConquest` is never weakened by
//    an override."
//
// These tests pin:
//
//   1. Curve plateau: OW = 0..7 always yields the early-sprint default
//      weights (positive — Refs #2847 § curve table; negative — OW = 8
//      moves off the plateau).
//   2. Each named curve row in the SPEC table maps to the exact weight
//      quad documented at OW = 8, 9, 10, 11, 12, 13.
//   3. OW > 13 saturates at the OW = 13+ row.
//   4. Treasury-recovery override raises `newWorldAcquisition` to 0.60
//      when (treasury == 0, NW = 0, boostTreasuryRecoveryCargo) all
//      hold; negative case (any one predicate false) leaves the curve
//      value unchanged.
//   5. Zero-regiment override raises `newWorldAcquisition` to 0.30
//      when (regimentCount == 0, invadableProvinceIdsSorted non-empty)
//      both hold; negative cases (regimentCount > 0; empty invadable
//      list) leave the curve value unchanged.
//   6. Both overrides firing together: the larger floor (0.60) wins.
//   7. `oldWorldConquest`, `oldWorldCivilian`, `newWorldCivilian` are
//      never weakened by any override predicate (only the NW
//      acquisition floor is raised).
//   8. Determinism: identical inputs produce field-equal results.
//
// The dispatcher contract that `PhasePlanOutcome.priorityWeights`
// field-equals `computePhasePriorityWeights` for the same input
// triple is pinned separately in `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_priority_weights_test_support.dart';

void registerPhasePriorityWeightsOverrideCases() {
  group('zero-regiment override (NW acquisition floor 0.30)', () {
    test('fires when regimentCount == 0 and invadable non-empty', () {
      final w = computePhasePriorityWeights(
        snapshot: phasePriorityWeightsSnapshot(
          oldWorldProvincesOwned: 7,
          treasury: 100,
          newWorldProvincesOwned: 1,
        ),
        game: phasePriorityWeightsGameWithRegiments(0),
        expandEconomyPlan: kPhasePriorityWeightsDefaultExpandPlan,
      );
      expect(w.newWorldAcquisition, kPhasePriorityNwZeroRegimentFloor);
      expect(w.oldWorldConquest, 0.95, reason: 'OW never weakened by override');
    });

    test('does NOT fire when regimentCount > 0 (negative)', () {
      final w = computePhasePriorityWeights(
        snapshot: phasePriorityWeightsSnapshot(
          oldWorldProvincesOwned: 7,
          treasury: 100,
          newWorldProvincesOwned: 1,
        ),
        game: phasePriorityWeightsGameWithRegiments(1),
        expandEconomyPlan: kPhasePriorityWeightsDefaultExpandPlan,
      );
      expect(w.newWorldAcquisition, 0.05);
    });

    test('does NOT fire when invadable list is empty (negative)', () {
      final w = computePhasePriorityWeights(
        snapshot: phasePriorityWeightsSnapshot(
          oldWorldProvincesOwned: 7,
          treasury: 100,
          newWorldProvincesOwned: 1,
          invadable: const [],
        ),
        game: phasePriorityWeightsGameWithRegiments(0),
        expandEconomyPlan: kPhasePriorityWeightsDefaultExpandPlan,
      );
      expect(w.newWorldAcquisition, 0.05);
    });
  });

  group('override floor combination semantics', () {
    test(
      'both overrides firing -> larger floor (0.60 treasury-recovery) wins',
      () {
        final w = computePhasePriorityWeights(
          snapshot: phasePriorityWeightsSnapshot(
            oldWorldProvincesOwned: 7,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: phasePriorityWeightsGameWithRegiments(0),
          expandEconomyPlan: kPhasePriorityWeightsBoostCargoPlan,
        );
        expect(w.newWorldAcquisition, kPhasePriorityNwTreasuryRecoveryFloor);
        // Pin that the smaller floor did not win.
        expect(w.newWorldAcquisition, isNot(kPhasePriorityNwZeroRegimentFloor));
        expect(w.oldWorldConquest, 0.95);
      },
    );

    test(
      'override does not weaken NW acquisition that is already above the floor',
      () {
        // At OW = 12 the curve sits at NW = 0.80 — already above
        // both floors. The override must not pull NW down to 0.60.
        final w = computePhasePriorityWeights(
          snapshot: phasePriorityWeightsSnapshot(
            oldWorldProvincesOwned: 12,
            treasury: 0,
            newWorldProvincesOwned: 0,
          ),
          game: phasePriorityWeightsGameWithRegiments(0),
          expandEconomyPlan: kPhasePriorityWeightsBoostCargoPlan,
        );
        expect(w.newWorldAcquisition, 0.80);
        expect(w.oldWorldConquest, 0.20);
      },
    );

    test('OW conquest weight is never lowered by any override', () {
      // Sweep every override permutation at OW = 0..13; the OW
      // conquest weight must always equal the curve value (i.e. not
      // be touched by any override).
      for (final ow in const [0, 7, 8, 9, 10, 11, 12, 13]) {
        for (final treasuryPlan in const [
          kPhasePriorityWeightsDefaultExpandPlan,
          kPhasePriorityWeightsBoostCargoPlan,
        ]) {
          for (final regiments in const [0, 1, 5]) {
            for (final nwOwned in const [0, 1]) {
              for (final treasury in const [0, 100]) {
                final w = computePhasePriorityWeights(
                  snapshot: phasePriorityWeightsSnapshot(
                    oldWorldProvincesOwned: ow,
                    treasury: treasury,
                    newWorldProvincesOwned: nwOwned,
                  ),
                  game: phasePriorityWeightsGameWithRegiments(regiments),
                  expandEconomyPlan: treasuryPlan,
                );
                final curve = computePhasePriorityWeights(
                  snapshot: phasePriorityWeightsSnapshot(
                    oldWorldProvincesOwned: ow,
                    treasury: 100,
                    newWorldProvincesOwned: 1,
                  ),
                  game: phasePriorityWeightsGameWithRegiments(5),
                  expandEconomyPlan: kPhasePriorityWeightsDefaultExpandPlan,
                );
                expect(
                  w.oldWorldConquest,
                  curve.oldWorldConquest,
                  reason:
                      'ow=$ow treasury=$treasury nw=$nwOwned '
                      'regiments=$regiments boost='
                      '${treasuryPlan.boostTreasuryRecoveryCargo}',
                );
                expect(w.oldWorldCivilian, curve.oldWorldCivilian);
                expect(w.newWorldCivilian, curve.newWorldCivilian);
              }
            }
          }
        }
      }
    });
  });

  group('determinism (Refs #2509 Must-have #7)', () {
    test('identical inputs produce field-equal results across two calls', () {
      final snapshot = phasePriorityWeightsSnapshot(
        oldWorldProvincesOwned: 10,
        treasury: 0,
        newWorldProvincesOwned: 0,
      );
      final game = phasePriorityWeightsGameWithRegiments(0);
      final first = computePhasePriorityWeights(
        snapshot: snapshot,
        game: game,
        expandEconomyPlan: kPhasePriorityWeightsBoostCargoPlan,
      );
      final second = computePhasePriorityWeights(
        snapshot: snapshot,
        game: game,
        expandEconomyPlan: kPhasePriorityWeightsBoostCargoPlan,
      );
      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test(
      'structurally different inputs produce structurally different results',
      () {
        final low = computePhasePriorityWeights(
          snapshot: phasePriorityWeightsSnapshot(oldWorldProvincesOwned: 5),
          game: phasePriorityWeightsGameWithRegiments(5),
          expandEconomyPlan: kPhasePriorityWeightsDefaultExpandPlan,
        );
        final high = computePhasePriorityWeights(
          snapshot: phasePriorityWeightsSnapshot(oldWorldProvincesOwned: 13),
          game: phasePriorityWeightsGameWithRegiments(5),
          expandEconomyPlan: kPhasePriorityWeightsDefaultExpandPlan,
        );
        expect(low, isNot(high));
      },
    );
  });

  group('PhasePriorityWeights value class equality', () {
    test('identical fields => equal + same hashCode', () {
      const a = PhasePriorityWeights(
        oldWorldConquest: 0.5,
        newWorldAcquisition: 0.5,
        oldWorldCivilian: 0.5,
        newWorldCivilian: 0.5,
      );
      const b = PhasePriorityWeights(
        oldWorldConquest: 0.5,
        newWorldAcquisition: 0.5,
        oldWorldCivilian: 0.5,
        newWorldCivilian: 0.5,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('any field differing => not equal', () {
      const base = PhasePriorityWeights(
        oldWorldConquest: 0.5,
        newWorldAcquisition: 0.5,
        oldWorldCivilian: 0.5,
        newWorldCivilian: 0.5,
      );
      expect(
        base,
        isNot(
          const PhasePriorityWeights(
            oldWorldConquest: 0.6,
            newWorldAcquisition: 0.5,
            oldWorldCivilian: 0.5,
            newWorldCivilian: 0.5,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const PhasePriorityWeights(
            oldWorldConquest: 0.5,
            newWorldAcquisition: 0.6,
            oldWorldCivilian: 0.5,
            newWorldCivilian: 0.5,
          ),
        ),
      );
    });

    test('toString includes every field name', () {
      const w = PhasePriorityWeights(
        oldWorldConquest: 0.95,
        newWorldAcquisition: 0.05,
        oldWorldCivilian: 0.90,
        newWorldCivilian: 0.10,
      );
      final s = w.toString();
      expect(s, contains('oldWorldConquest'));
      expect(s, contains('newWorldAcquisition'));
      expect(s, contains('oldWorldCivilian'));
      expect(s, contains('newWorldCivilian'));
    });
  });
}
