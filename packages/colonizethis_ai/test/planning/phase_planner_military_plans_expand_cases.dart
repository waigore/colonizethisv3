// Case bodies for `expandMilitaryPlanFromPhasePlan` pin (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandMilitaryPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_military_plans.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_military_plans_fixtures.dart';

void registerPhasePlannerMilitaryPlansExpandCases() {
  group('expandMilitaryPlanFromPhasePlan — phase routing', () {
    test('EXPAND surfaces expandMilitaryPlan verbatim (single owner)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: expandSingleOwner,
      );
      expect(expandMilitaryPlanFromPhasePlan(outcome), expandSingleOwner);
    });

    test('EXPAND surfaces expandMilitaryPlan verbatim (multi-owner '
        'at-war fallback)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: expandMultiOwner,
      );
      expect(expandMilitaryPlanFromPhasePlan(outcome), expandMultiOwner);
    });

    test('COLONIAL-lite surfaces expandMilitaryPlan verbatim '
        '(OW push continues during safeguard)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandMilitaryPlan: expandMultiOwner,
      );
      expect(expandMilitaryPlanFromPhasePlan(outcome), expandMultiOwner);
    });

    test('COLONIAL routes to ExpandMilitaryPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ExpandMilitaryPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });
  });

  group('expandMilitaryPlanFromPhasePlan — defensive phase suppression', () {
    test('COLONIAL surfaces ExpandMilitaryPlan.defaultPlan even when '
        'EXPAND slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandMilitaryPlan: expandMultiOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
        reason:
            'COLONIAL has no EXPAND military override by spec; a '
            'non-default expandMilitaryPlan slot must not leak the EXPAND '
            'OW conquest filter into the COLONIAL military pass.',
      );
    });

    test('DEVELOP surfaces ExpandMilitaryPlan.defaultPlan even when '
        'EXPAND slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandMilitaryPlan: expandMultiOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no military override; the '
            'structural phase separation must hold at the adapter layer '
            'even if dispatcher slots are populated.',
      );
    });

    test('EXPAND surfaces ExpandMilitaryPlan.defaultPlan when slot is '
        'default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });

    test('COLONIAL-lite surfaces ExpandMilitaryPlan.defaultPlan when '
        'slot is default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });
  });
}
