// Topic-split pins from `phase_planner_goal_filter_colonial_pressure_test.dart`
// (Refs #4669 Slice D).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_goal_filter_colonial_pressure_support.dart';

void registerPhasePlannerGoalFilterColonialPressureWeightPrecedenceCases() {
  test('colonialPressureWeight takes precedence over observerGoalPhase '
      'when both are supplied', () {
    final colonialWithZeroWeight = evaluateStrategicGoalScores(
      kColonialPressureSoftWeightSnapshot,
      kColonialPressureSoftWeightConfig,
      observerGoalPhase: ObserverGoalPhase.colonial,
      colonialPressureWeight: 0.0,
    );
    final expandWithFullWeight = evaluateStrategicGoalScores(
      kColonialPressureSoftWeightSnapshot,
      kColonialPressureSoftWeightConfig,
      observerGoalPhase: ObserverGoalPhase.expand,
      colonialPressureWeight: 1.0,
    );
    expect(
      colonialWithZeroWeight[StrategicGoal.conquer]!,
      lessThan(kMinimumColonialConquerScoreWhenPressure),
      reason:
          'weight = 0.0 overrides COLONIAL phase boolean and skips '
          'the conquer floor.',
    );
    expect(
      expandWithFullWeight[StrategicGoal.conquer]!,
      greaterThanOrEqualTo(kMinimumColonialConquerScoreWhenPressure),
      reason:
          'weight = 1.0 overrides EXPAND phase boolean suppress and '
          'activates the conquer floor.',
    );
  });
}
