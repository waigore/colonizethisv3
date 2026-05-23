// Unit tests for `phase_planner_civilian_work_orders.dart`
// (Refs #2509 S5 orchestrator adapter slice).
//
// Adapter contract pinned here (from
// `SPEC/ai/phase-planner-dispatch.md` § Adapter helpers — updated by
// this slice to add the civilian work-order row):
//
//   civilianWorkOrdersFromPhasePlan(outcome):
//     - EXPAND          -> const <WorkOrder>[]
//     - COLONIAL-lite   -> const <WorkOrder>[]
//     - COLONIAL        -> outcome.colonialCivilianWorkOrders
//     - DEVELOP         -> outcome.developCivilianWorkOrders
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already
// covered by `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_civilian_work_orders.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show WorkOrder;
import 'package:colonizethis_test/test.dart';

const WorkOrder _colonialWork = WorkOrder(
  unitId: 'u_merchant_1',
  target: 'purchase_land',
  targetTileKey: 'newWorld|nw1|0|0',
);

const WorkOrder _colonialBuilderWork = WorkOrder(
  unitId: 'u_builder_2',
  target: 'build_improvement',
  targetTileKey: 'newWorld|nw1|1|0',
);

const WorkOrder _developWork = WorkOrder(
  unitId: 'u_builder_1',
  target: 'build_improvement',
  targetTileKey: 'oldWorld|gp1_home|3|2',
);

const WorkOrder _developSecondWork = WorkOrder(
  unitId: 'u_builder_2',
  target: 'build_improvement',
  targetTileKey: 'oldWorld|gp1_home|4|2',
);

void main() {
  group('civilianWorkOrdersFromPhasePlan — phase routing', () {
    test('COLONIAL surfaces colonialCivilianWorkOrders verbatim', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialCivilianWorkOrders: [_colonialWork, _colonialBuilderWork],
      );
      expect(civilianWorkOrdersFromPhasePlan(outcome), const [
        _colonialWork,
        _colonialBuilderWork,
      ]);
    });

    test('DEVELOP surfaces developCivilianWorkOrders verbatim', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developCivilianWorkOrders: [_developWork, _developSecondWork],
      );
      expect(civilianWorkOrdersFromPhasePlan(outcome), const [
        _developWork,
        _developSecondWork,
      ]);
    });

    test('EXPAND surfaces empty list (no civilian work orders in EXPAND)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(civilianWorkOrdersFromPhasePlan(outcome), isEmpty);
    });

    test(
      'COLONIAL-lite surfaces empty list (safeguard suppresses NW work)',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
        expect(civilianWorkOrdersFromPhasePlan(outcome), isEmpty);
      },
    );
  });

  group('civilianWorkOrdersFromPhasePlan — defensive phase suppression', () {
    test('EXPAND surfaces empty even when COLONIAL slot non-empty', () {
      // Defensive: the dispatcher never populates colonialCivilianWorkOrders
      // in EXPAND, but the adapter must short-circuit on phase to defend the
      // suppression matrix against a future regression that leaks NW work
      // orders into the EXPAND economy pass.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialCivilianWorkOrders: [_colonialWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        isEmpty,
        reason:
            'EXPAND has no civilian work orders by spec; a non-empty '
            'colonialCivilianWorkOrders slot must not leak NW work into '
            'the EXPAND economy pass.',
      );
    });

    test('COLONIAL-lite surfaces empty even when COLONIAL slot non-empty', () {
      // Defensive: COLONIAL-lite is the EXPAND safeguard that suppresses
      // NW declareWar / joinEmpire / purchase_land / NW civilian work.
      // Even if a future regression populated colonialCivilianWorkOrders
      // under the safeguard, the adapter must keep returning an empty
      // list so the OW push is not weakened by NW build activity.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialCivilianWorkOrders: [_colonialWork, _colonialBuilderWork],
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
      // Defensive: the dispatcher never populates developCivilianWorkOrders
      // in COLONIAL, but the adapter must surface only the COLONIAL slot to
      // defend the suppression matrix.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialCivilianWorkOrders: [_colonialWork],
        developCivilianWorkOrders: [_developWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [_colonialWork],
        reason:
            'COLONIAL must route only colonialCivilianWorkOrders; the '
            'DEVELOP slot is owned by a different phase planner.',
      );
    });

    test('DEVELOP ignores COLONIAL slot even when COLONIAL slot non-empty', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialCivilianWorkOrders: [_colonialWork],
        developCivilianWorkOrders: [_developWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [_developWork],
        reason:
            'DEVELOP must route only developCivilianWorkOrders; the '
            'COLONIAL slot is owned by a different phase planner.',
      );
    });
  });

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
        colonialCivilianWorkOrders: [_colonialBuilderWork, _colonialWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [_colonialBuilderWork, _colonialWork],
        reason:
            'Adapter must not reorder — planColonialCivilian establishes '
            'the deterministic emission order (Must-have #7).',
      );
    });

    test('DEVELOP preserves order of developCivilianWorkOrders', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developCivilianWorkOrders: [_developSecondWork, _developWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        const [_developSecondWork, _developWork],
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
        colonialCivilianWorkOrders: [_colonialWork],
      );
      expect(
        civilianWorkOrdersFromPhasePlan(outcome),
        civilianWorkOrdersFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical lists', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developCivilianWorkOrders: [_developWork, _developSecondWork],
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
