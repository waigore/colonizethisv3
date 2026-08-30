// Routing and defensive-suppression cases for civilian work-order adapter (Refs #2509 / #4669).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_civilian_work_orders.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_civilian_work_orders_support.dart';

void registerPhasePlannerCivilianWorkOrdersRoutingCases() {
  group('civilianWorkOrdersFromPhasePlan — phase routing', () {
    test('COLONIAL surfaces colonialCivilianWorkOrders verbatim', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialCivilianWorkOrders: [
          kCivilianWorkOrdersColonialWork,
          kCivilianWorkOrdersColonialBuilderWork,
        ],
      );
      expect(civilianWorkOrdersFromPhasePlan(outcome), const [
        kCivilianWorkOrdersColonialWork,
        kCivilianWorkOrdersColonialBuilderWork,
      ]);
    });

    test('DEVELOP surfaces developCivilianWorkOrders verbatim', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developCivilianWorkOrders: [
          kCivilianWorkOrdersDevelopWork,
          kCivilianWorkOrdersDevelopSecondWork,
        ],
      );
      expect(civilianWorkOrdersFromPhasePlan(outcome), const [
        kCivilianWorkOrdersDevelopWork,
        kCivilianWorkOrdersDevelopSecondWork,
      ]);
    });

    test(
      'EXPAND with zero NW weight surfaces empty list',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: kCivilianWorkOrdersNwAcquisitionZeroExpand,
        );
        expect(civilianWorkOrdersFromPhasePlan(outcome), isEmpty);
      },
    );

    test(
      'EXPAND with positive NW weight surfaces colonialCivilianWorkOrders',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          colonialCivilianWorkOrders: [kCivilianWorkOrdersColonialWork],
        );
        expect(
          civilianWorkOrdersFromPhasePlan(outcome),
          const [kCivilianWorkOrdersColonialWork],
        );
      },
    );

    test(
      'COLONIAL-lite surfaces empty list (safeguard suppresses NW work)',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
        expect(civilianWorkOrdersFromPhasePlan(outcome), isEmpty);
      },
    );
  });

  group('civilianWorkOrdersFromPhasePlan — defensive phase suppression', () {
    test(
      'EXPAND with zero NW weight suppresses colonial slot',
      () {
        const outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: kCivilianWorkOrdersNwAcquisitionZeroExpand,
          colonialCivilianWorkOrders: [kCivilianWorkOrdersColonialWork],
        );
        expect(
          civilianWorkOrdersFromPhasePlan(outcome),
          isEmpty,
          reason:
              'phasePlanFullColonialOutputsActive is false when '
              'newWorldAcquisition is zero; colonial slot must not leak.',
        );
      },
    );

    test('COLONIAL-lite surfaces empty even when COLONIAL slot non-empty', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialCivilianWorkOrders: [
          kCivilianWorkOrdersColonialWork,
          kCivilianWorkOrdersColonialBuilderWork,
        ],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        isEmpty,
        reason:
            'COLONIAL-lite intentionally publishes no civilian work orders; '
            'the structural NW-acquisition suppression must hold at the '
            'adapter layer even if dispatcher slots are populated.',
      );
    });

    test(
      'COLONIAL surfaces empty when colonialCivilianWorkOrders is empty',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
        expect(civilianWorkOrdersFromPhasePlan(outcome), isEmpty);
      },
    );

    test('DEVELOP surfaces empty when developCivilianWorkOrders is empty', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(civilianWorkOrdersFromPhasePlan(outcome), isEmpty);
    });

    test('COLONIAL ignores DEVELOP slot even when DEVELOP slot non-empty', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialCivilianWorkOrders: [kCivilianWorkOrdersColonialWork],
        developCivilianWorkOrders: [kCivilianWorkOrdersDevelopWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [kCivilianWorkOrdersColonialWork],
        reason:
            'COLONIAL must route only colonialCivilianWorkOrders; the '
            'DEVELOP slot is owned by a different phase planner.',
      );
    });

    test('DEVELOP ignores COLONIAL slot even when COLONIAL slot non-empty', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialCivilianWorkOrders: [kCivilianWorkOrdersColonialWork],
        developCivilianWorkOrders: [kCivilianWorkOrdersDevelopWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [kCivilianWorkOrdersDevelopWork],
        reason:
            'DEVELOP must route only developCivilianWorkOrders; the '
            'COLONIAL slot is owned by a different phase planner.',
      );
    });
  });
}
