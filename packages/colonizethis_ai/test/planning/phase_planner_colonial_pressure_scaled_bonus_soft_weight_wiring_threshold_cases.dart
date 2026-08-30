// Domain threshold relationship pins for Phase 3 colonial-pressure soft-weight
// wiring (Refs #2847; extracted from the consolidated contract host Refs #4669).

import 'package:colonizethis_ai/src/planning/naval_planner.dart'
    show kNavalRunMinWeight;
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_filter.dart';
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart'
    show kPhasePriorityNwTreasuryRecoveryFloor;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

/// Early-sprint default soft curve plateau shared by threshold pins.
const double colonialPressureSoftWeightEarlySprintWeight = 0.05;

void registerPhasePlannerColonialPressureScaledBonusSoftWeightWiringThresholdCases() {
  group(
    'Phase 3 colonial-pressure domain threshold relationships (Refs #2847)',
    () {
      test(
        'conquest early-sprint floor is strictly below the stalled-expansion '
        'floor',
        () {
          expect(
            conquestColonialPressureMinWeightFloor(
              colonialPressureWeight: colonialPressureSoftWeightEarlySprintWeight,
            ),
            lessThan(kConquestArmyMoveMinWeightWhenStalled),
            reason:
                'Early-sprint conquest colonial-pressure floor must be '
                'strictly less than kConquestArmyMoveMinWeightWhenStalled '
                '($kConquestArmyMoveMinWeightWhenStalled).',
          );
        },
      );

      test(
        'naval early-sprint bonus and floor stay below kNavalRunMinWeight '
        '(no naval engagement on the early OW sprint)',
        () {
          expect(
            navalColonialPressureWeightBonus(
              colonialPressureWeight: colonialPressureSoftWeightEarlySprintWeight,
            ),
            lessThan(kNavalRunMinWeight),
            reason:
                'Early-sprint naval colonial-pressure bonus must be strictly '
                'less than kNavalRunMinWeight ($kNavalRunMinWeight) so the '
                'early OW conquest sprint cannot engage the naval pass on the '
                'colonial-pressure bonus alone.',
          );
          expect(
            navalColonialPressureMinWeightFloor(
              colonialPressureWeight: colonialPressureSoftWeightEarlySprintWeight,
            ),
            lessThan(kNavalRunMinWeight),
            reason:
                'Early-sprint naval colonial-pressure floor must be strictly '
                'less than kNavalRunMinWeight ($kNavalRunMinWeight) so the OW '
                'conquest sprint is not diverted into naval planning.',
          );
        },
      );

      test(
        'naval resource-need override floor (0.60) lifts the floor above '
        'kNavalRunMinWeight (EXPAND-lock recovery engagement)',
        () {
          expect(
            navalColonialPressureMinWeightFloor(
              colonialPressureWeight: kPhasePriorityNwTreasuryRecoveryFloor,
            ),
            greaterThan(kNavalRunMinWeight),
            reason:
                'Resource-need override floor '
                '($kPhasePriorityNwTreasuryRecoveryFloor) must lift the naval '
                'floor strictly above kNavalRunMinWeight ($kNavalRunMinWeight) '
                'so naval planning engages under EXPAND-lock recovery.',
          );
        },
      );
    },
  );
}
