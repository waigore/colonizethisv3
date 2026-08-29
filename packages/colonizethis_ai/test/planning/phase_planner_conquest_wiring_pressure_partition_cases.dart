// Partition-matrix pins for `phase_planner_conquest_wiring_pressure_extra_cases.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_conquest_filter.dart';
import 'package:colonizethis_test/test.dart';

void registerPhasePlannerConquestWiringPressurePartitionCases() {
  group('resolvePhaseConquestExtraPassesActive', () {
    test(
      'partition matrix with resolvePhaseConquestColonialPressureActive '
      '— exactly one of the two conquest-routing resolvers returns true for '
      'any non-DEVELOP phase, and both return false under DEVELOP',
      () {
        const expectedExtraPasses = <ObserverGoalPhase, bool>{
          ObserverGoalPhase.expand: true,
          ObserverGoalPhase.colonialLite: true,
          ObserverGoalPhase.colonial: false,
          ObserverGoalPhase.develop: false,
        };
        const expectedColonialPressure = <ObserverGoalPhase, bool>{
          ObserverGoalPhase.expand: false,
          ObserverGoalPhase.colonialLite: false,
          ObserverGoalPhase.colonial: true,
          ObserverGoalPhase.develop: false,
        };
        for (final phase in ObserverGoalPhase.values) {
          final outcome = PhasePlanOutcome(phase: phase);
          final extra = resolvePhaseConquestExtraPassesActive(
            phasePlan: outcome,
          );
          final pressure = resolvePhaseConquestColonialPressureActive(
            phasePlan: outcome,
          );
          expect(
            extra,
            expectedExtraPasses[phase],
            reason: '$phase: extra-passes value',
          );
          expect(
            pressure,
            expectedColonialPressure[phase],
            reason: '$phase: colonial-pressure value',
          );
          expect(
            extra && pressure,
            isFalse,
            reason:
                '$phase: extra-passes and colonial-pressure resolvers '
                'must never both return true (phases are mutually '
                'exclusive per outcome.phase).',
          );
        }
      },
    );
  });
}
