// Topic-split pins from `phase_planner_expand_economy_test.dart` (Refs #4669 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_expand_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_expand_economy_test_support.dart';

void registerPhasePlannerExpandEconomyDeterminismCases() {
  group('expandEconomyPlanFromPhasePlan — determinism (Must-have #7)', () {
    test('identical EXPAND outcomes yield identical plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: kExpandEconomyRebuildOnly,
      );
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL-lite outcomes yield identical plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandEconomyPlan: kExpandEconomyBoostOnly,
      );
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL outcomes yield identical ExpandEconomyPlan'
        '.defaultPlan', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical ExpandEconomyPlan'
        '.defaultPlan', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });
  });
}
