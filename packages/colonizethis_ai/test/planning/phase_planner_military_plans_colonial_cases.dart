// Case bodies for `colonialMilitaryPlanFromPhasePlan` pin (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialMilitaryPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_military_plans.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_military_plans_fixtures.dart';

void registerPhasePlannerMilitaryPlansColonialCases() {
  group('colonialMilitaryPlanFromPhasePlan — phase routing', () {
    test('COLONIAL surfaces colonialMilitaryPlan verbatim (single owner)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: colonialSingleOwner,
      );
      expect(colonialMilitaryPlanFromPhasePlan(outcome), colonialSingleOwner);
    });

    test('COLONIAL surfaces colonialMilitaryPlan verbatim (multi-owner '
        'at-war fallback)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: colonialMultiOwner,
      );
      expect(colonialMilitaryPlanFromPhasePlan(outcome), colonialMultiOwner);
    });

    test('EXPAND routes to ColonialMilitaryPlan.defaultPlan (structural '
        'NW suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('COLONIAL-lite routes to ColonialMilitaryPlan.defaultPlan '
        '(safeguard suppresses NW invasion army moves)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ColonialMilitaryPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });
  });

  group('colonialMilitaryPlanFromPhasePlan — defensive phase suppression', () {
    test('EXPAND with newWorldAcquisition=0 surfaces default even when '
        'COLONIAL slot non-default (legacy hard suppress)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialMilitaryPlan: colonialMultiOwner,
        priorityWeights: nwAcquisitionZeroExpand,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('EXPAND with newWorldAcquisition>0 surfaces colonialMilitaryPlan '
        '(Refs #2847)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialMilitaryPlan: colonialMultiOwner,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        colonialMultiOwner,
      );
    });

    test('COLONIAL-lite surfaces ColonialMilitaryPlan.defaultPlan even '
        'when COLONIAL slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialMilitaryPlan: colonialMultiOwner,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
        reason:
            'COLONIAL-lite explicitly suppresses NW invasion army '
            'moves; a populated colonialMilitaryPlan slot must be '
            'filtered at the adapter layer.',
      );
    });

    test('DEVELOP surfaces ColonialMilitaryPlan.defaultPlan even when '
        'COLONIAL slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialMilitaryPlan: colonialMultiOwner,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no military override; the '
            'structural phase separation must hold at the adapter layer '
            'even if dispatcher slots are populated.',
      );
    });

    test('COLONIAL surfaces ColonialMilitaryPlan.defaultPlan when slot '
        'is default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });
  });
}
