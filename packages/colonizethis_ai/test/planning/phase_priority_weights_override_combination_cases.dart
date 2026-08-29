// Override combination + determinism pins for phase priority weights (Refs #2847).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_priority_weights_test_support.dart';

void registerPhasePriorityWeightsOverrideCombinationCases() {
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
        expect(w.newWorldAcquisition, isNot(kPhasePriorityNwZeroRegimentFloor));
        expect(w.oldWorldConquest, 0.95);
      },
    );

    test(
      'override does not weaken NW acquisition that is already above the floor',
      () {
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
