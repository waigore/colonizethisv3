// Default-outcome, preservation, and determinism cases for civilian work-order adapter (Refs #2509 / #4669).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_civilian_work_orders.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_civilian_work_orders_support.dart';

void registerPhasePlannerCivilianWorkOrdersAdapterCases() {
  group('civilianWorkOrdersFromPhasePlan — default outcome constants', () {
    test('defaultExpand surfaces empty', () {
      expect(
        civilianWorkOrdersFromPhasePlan(PhasePlanOutcome.defaultExpand),
        isEmpty,
      );
    });

    test('defaultColonialLite surfaces empty', () {
      expect(
        civilianWorkOrdersFromPhasePlan(PhasePlanOutcome.defaultColonialLite),
        isEmpty,
      );
    });

    test('defaultColonial surfaces empty', () {
      expect(
        civilianWorkOrdersFromPhasePlan(PhasePlanOutcome.defaultColonial),
        isEmpty,
      );
    });

    test('defaultDevelop surfaces empty', () {
      expect(
        civilianWorkOrdersFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        isEmpty,
      );
    });
  });

  group('civilianWorkOrdersFromPhasePlan — order preservation', () {
    test('COLONIAL preserves order of colonialCivilianWorkOrders', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialCivilianWorkOrders: [
          kCivilianWorkOrdersColonialBuilderWork,
          kCivilianWorkOrdersColonialWork,
        ],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [
          kCivilianWorkOrdersColonialBuilderWork,
          kCivilianWorkOrdersColonialWork,
        ],
        reason:
            'Adapter must not reorder — planColonialCivilian establishes '
            'the deterministic emission order (Must-have #7).',
      );
    });

    test('DEVELOP preserves order of developCivilianWorkOrders', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developCivilianWorkOrders: [
          kCivilianWorkOrdersDevelopSecondWork,
          kCivilianWorkOrdersDevelopWork,
        ],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [
          kCivilianWorkOrdersDevelopSecondWork,
          kCivilianWorkOrdersDevelopWork,
        ],
        reason:
            'Adapter must not reorder — planDevelopCivilian establishes the '
            'descending-yield emission order (issue #2509 § DEVELOP phase '
            'planner § planDevelopCivilian step 3).',
      );
    });
  });

  group('civilianWorkOrdersFromPhasePlan — determinism (Must-have #7)', () {
    test('identical COLONIAL outcomes yield identical lists', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialCivilianWorkOrders: [kCivilianWorkOrdersColonialWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        civilianWorkOrdersFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical lists', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developCivilianWorkOrders: [
          kCivilianWorkOrdersDevelopWork,
          kCivilianWorkOrdersDevelopSecondWork,
        ],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        civilianWorkOrdersFromPhasePlan(outcome),
      );
    });

    test('identical EXPAND outcomes yield identical empty lists', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        civilianWorkOrdersFromPhasePlan(outcome),
      );
    });
  });
}
