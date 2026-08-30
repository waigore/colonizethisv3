// Determinism pins for `phase_planner_naval_plans_adapter_cases.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialLiteNavalPlan, ColonialNavalPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_plans.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_naval_plans_adapter_cases.dart';

void registerPhasePlannerNavalPlansAdapterDeterminismCases() {
  group('naval adapters — determinism (Must-have #7)', () {
    test('identical COLONIAL outcomes yield identical naval plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: kColonialNavalSingleOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL-lite outcomes yield identical naval plans '
        '(colonial-lite passthrough, colonial default)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: kColonialLiteNavalMultiOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });

    test('identical EXPAND outcomes yield identical defaults for both '
        'adapters', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical defaults for both '
        'adapters', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });
  });
}
