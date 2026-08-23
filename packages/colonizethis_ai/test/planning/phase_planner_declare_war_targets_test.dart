// Adapter helpers: `SPEC/ai/phase-planner-dispatch.md` (Refs #2509 S5, #4602).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_declare_war_targets.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_declare_war_targets_colonial_cases.dart';
import 'phase_planner_declare_war_targets_exclusion_cases.dart';

void main() {
  group('gpExpandDeclareWarTargetFromPhasePlan', () {
    test('EXPAND surfaces expandDeclareWarTargetFactionId', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minor1',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), 'minor1');
    });

    test('EXPAND null target surfaces null', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('COLONIAL-lite surfaces expandDeclareWarTargetFactionId', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandDeclareWarTargetFactionId: 'minor2',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), 'minor2');
    });

    test('COLONIAL-lite null target surfaces null', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('COLONIAL returns null even when expand slot non-null', () {
      // Defensive: the dispatcher never populates expand slots in COLONIAL,
      // but the adapter must short-circuit on phase regardless so a
      // future regression in the dispatcher does not leak an EXPAND
      // declare-war target into the COLONIAL diplomacy pass.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandDeclareWarTargetFactionId: 'minor3',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('DEVELOP returns null even when expand slot non-null', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandDeclareWarTargetFactionId: 'minor4',
      );
      expect(gpExpandDeclareWarTargetFromPhasePlan(outcome), isNull);
    });

    test('defaultExpand outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultExpand),
        isNull,
      );
    });

    test('defaultColonialLite outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(
          PhasePlanOutcome.defaultColonialLite,
        ),
        isNull,
      );
    });

    test('defaultColonial outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultColonial),
        isNull,
      );
    });

    test('defaultDevelop outcome surfaces null', () {
      expect(
        gpExpandDeclareWarTargetFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        isNull,
      );
    });
  });

  registerPhasePlannerDeclareWarTargetsColonialCases();
  registerPhasePlannerDeclareWarTargetsExclusionCases();
}
