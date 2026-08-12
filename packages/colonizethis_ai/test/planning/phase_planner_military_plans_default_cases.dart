// Default-outcome and determinism cases for military-plan adapters
// (Refs #4310 Slice D).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialMilitaryPlan;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandMilitaryPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_military_plans.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_military_plans_fixtures.dart';

void registerPhasePlannerMilitaryPlansDefaultAndDeterminismCases() {
  group('military adapters — default outcome constants', () {
    test('defaultExpand surfaces ExpandMilitaryPlan.defaultPlan and '
        'ColonialMilitaryPlan.defaultPlan', () {
      expect(
        expandMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultExpand),
        ExpandMilitaryPlan.defaultPlan,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultExpand),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('defaultColonialLite surfaces ExpandMilitaryPlan.defaultPlan '
        'and ColonialMilitaryPlan.defaultPlan', () {
      expect(
        expandMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultColonialLite),
        ExpandMilitaryPlan.defaultPlan,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultColonialLite),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('defaultColonial surfaces ExpandMilitaryPlan.defaultPlan and '
        'ColonialMilitaryPlan.defaultPlan', () {
      expect(
        expandMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultColonial),
        ExpandMilitaryPlan.defaultPlan,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultColonial),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('defaultDevelop surfaces ExpandMilitaryPlan.defaultPlan and '
        'ColonialMilitaryPlan.defaultPlan', () {
      expect(
        expandMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        ExpandMilitaryPlan.defaultPlan,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        ColonialMilitaryPlan.defaultPlan,
      );
    });
  });

  group('military adapters — value preservation', () {
    test('EXPAND preserves both ExpandMilitaryPlan list contents in '
        'order', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: expandMultiOwner,
      );
      final result = expandMilitaryPlanFromPhasePlan(outcome);
      expect(result.priorityDestinationProvinceIdsSorted, const <String>[
        'oldWorld|nation_a|p1',
        'oldWorld|nation_b|p2',
        'oldWorld|nation_b|p3',
      ]);
      expect(result.priorityTargetOwnerFactionIdsSorted, const <String>[
        'nation_a',
        'nation_b',
      ]);
    });

    test('COLONIAL preserves both ColonialMilitaryPlan list contents in '
        'order', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: colonialMultiOwner,
      );
      final result = colonialMilitaryPlanFromPhasePlan(outcome);
      expect(result.priorityDestinationProvinceIdsSorted, const <String>[
        'newWorld|tribe_a|nw1',
        'newWorld|tribe_b|nw2',
        'newWorld|tribe_b|nw3',
      ]);
      expect(result.priorityTargetOwnerFactionIdsSorted, const <String>[
        'tribe_a',
        'tribe_b',
      ]);
    });
  });

  group('military adapters — determinism (Must-have #7)', () {
    test('identical EXPAND outcomes yield identical military plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: expandSingleOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        expandMilitaryPlanFromPhasePlan(outcome),
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        colonialMilitaryPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL-lite outcomes yield identical military '
        'plans (expand passthrough, colonial default)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandMilitaryPlan: expandMultiOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        expandMilitaryPlanFromPhasePlan(outcome),
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        colonialMilitaryPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL outcomes yield identical military plans '
        '(expand default, colonial passthrough)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: colonialMultiOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        expandMilitaryPlanFromPhasePlan(outcome),
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        colonialMilitaryPlanFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical defaults for both '
        'adapters', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        expandMilitaryPlanFromPhasePlan(outcome),
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        colonialMilitaryPlanFromPhasePlan(outcome),
      );
    });
  });
}
