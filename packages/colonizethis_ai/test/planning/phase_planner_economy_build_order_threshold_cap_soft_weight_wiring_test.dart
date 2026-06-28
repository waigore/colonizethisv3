// Unit tests for the Phase 3 soft-weight wiring of the economy
// build-order threshold cap (Refs #2847).
//
// Mirrors the test pattern in:
//   - `phase_planner_economy_civilian_threshold_cap_soft_weight_wiring_test.dart`
//   - `phase_planner_economy_build_pick_soft_weight_wiring_test.dart`
//
// Pins the contract of `economyColonialPressureBuildOrderThresholdCap`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_economy_filter.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group(
    'Phase 3 economy build-order threshold cap soft-weight wiring '
    '(economyColonialPressureBuildOrderThresholdCap)',
    () {
      test(
        'colonialPressureWeight <= 0.0 returns null (legacy hard-off)',
        () {
          expect(
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: 0.0,
            ),
            isNull,
          );
          expect(
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: -0.5,
            ),
            isNull,
          );
        },
      );

      test(
        'colonialPressureWeight == 1.0 returns full under-pressure cap',
        () {
          expect(
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: 1.0,
            ),
            kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
          );
        },
      );

      test('intermediate weight scales linearly (w = 0.5 -> 8)', () {
        expect(
          economyColonialPressureBuildOrderThresholdCap(
            colonialPressureWeight: 0.5,
          ),
          8,
        );
      });

      test(
        'early-sprint curve weight 0.05 returns token cap 1',
        () {
          expect(
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: 0.05,
            ),
            1,
          );
        },
      );

      test(
        'resource-need override floor 0.60 returns cap 9 (Refs #2924)',
        () {
          expect(
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: 0.60,
            ),
            9,
          );
        },
      );

      test('clamps colonialPressureWeight above 1.0 to full cap', () {
        expect(
          economyColonialPressureBuildOrderThresholdCap(
            colonialPressureWeight: 2.0,
          ),
          kColonialBuildOrderThresholdWhenOwnedNwUnderPressure,
        );
      });

      test('deterministic across repeated calls (Must-have #7)', () {
        const weight = 0.42;
        final a = economyColonialPressureBuildOrderThresholdCap(
          colonialPressureWeight: weight,
        );
        final b = economyColonialPressureBuildOrderThresholdCap(
          colonialPressureWeight: weight,
        );
        expect(a, b);
      });

      test('monotonic non-increasing as weight rises from 0.05 to 1.0', () {
        final caps = <int?>[
          for (var w = 0.05; w <= 1.0; w += 0.05)
            economyColonialPressureBuildOrderThresholdCap(
              colonialPressureWeight: w,
            ),
        ];
        for (var i = 1; i < caps.length; i++) {
          expect(
            caps[i]!,
            greaterThanOrEqualTo(caps[i - 1]!),
            reason: 'cap at step $i must not drop below prior step',
          );
        }
      });
    },
  );

  group(
    'resolvePhaseEconomyColonialBuildOrderThresholdCap NW-ownership tagalong',
    () {
      test('returns null when newWorldProvincesOwned == 0 regardless of weight',
          () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.1,
            newWorldAcquisition: 1.0,
            oldWorldCivilian: 0.1,
            newWorldCivilian: 0.9,
          ),
        );
        expect(
          resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: outcome,
            colonial: ColonialSummary(),
          ),
          isNull,
        );
      });

      test(
        'EXPAND with early-sprint weight and NW owned returns scaled cap',
        () {
          const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
          expect(
            resolvePhaseEconomyColonialBuildOrderThresholdCap(
              phasePlan: outcome,
              colonial: ColonialSummary(newWorldProvincesOwned: 1),
            ),
            1,
          );
        },
      );
    },
  );
}
