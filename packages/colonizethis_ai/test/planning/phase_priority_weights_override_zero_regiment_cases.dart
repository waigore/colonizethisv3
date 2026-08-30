// Zero-regiment override pins for phase priority weights (Refs #2847).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_test/test.dart';

import '../support/phase_priority_weights_test_support.dart';

void registerPhasePriorityWeightsOverrideZeroRegimentCases() {
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
}
