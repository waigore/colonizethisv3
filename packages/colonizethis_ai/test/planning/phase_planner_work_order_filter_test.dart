// Unit tests for `phase_planner_work_order_filter.dart`
// (Refs #2509 S5 orchestrator adapter slice — replaces
// `shouldFilterObserverPhaseWorkOrder` at the orchestrator call site in
// `_runEconomyDomainPlanners`).
//
// Adapter contract pinned here (mirrors
// `SPEC/ai/phase-planner-dispatch.md` § Adapter helpers — updated by
// this slice to add the work-order suggestion-filter row):
//
//   shouldSuppressWorkOrderFromPhasePlan(order, outcome):
//     - EXPAND          -> true for NW purchase_land OR NW build_improvement
//     - COLONIAL-lite   -> true for NW purchase_land only
//                          (NW build_improvement passes through)
//     - DEVELOP         -> true for NW purchase_land only
//                          (NW build_improvement passes through so the
//                          turn-150 70 % improvement gate stays reachable)
//     - COLONIAL        -> false (every NW civilian path stays open)
//
// Region scoping is deterministic via `ProvinceId.regionIdFrom` — OW
// `purchase_land` and OW `build_improvement` must never be filtered
// under any phase. Pass-through targets (e.g. `steal_tech`) must never
// be filtered under any phase either.
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already
// covered by `phase_planner_dispatch_test.dart`, and the legacy
// `observerGoalPhaseFor` -> `shouldFilterObserverPhaseWorkOrder`
// branches stay pinned by
// `observer_goal_phase_work_order_filter_branches_test.dart`.

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_work_order_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show WorkOrder;
import 'package:colonizethis_test/test.dart';

const WorkOrder _nwPurchaseLand = WorkOrder(
  unitId: 'u_merchant_1',
  target: 'purchase_land',
  targetTileKey: 'newWorld|nw1|0|0',
);

const WorkOrder _nwBuildImprovement = WorkOrder(
  unitId: 'u_builder_1',
  target: 'build_improvement',
  targetTileKey: 'newWorld|nw1|1|0',
);

const WorkOrder _owPurchaseLand = WorkOrder(
  unitId: 'u_merchant_2',
  target: 'purchase_land',
  targetTileKey: 'oldWorld|gp1_home|2|2',
);

const WorkOrder _owBuildImprovement = WorkOrder(
  unitId: 'u_builder_2',
  target: 'build_improvement',
  targetTileKey: 'oldWorld|gp1_home|3|3',
);

const WorkOrder _stealTechAnyRegion = WorkOrder(
  unitId: 'u_spy_1',
  target: 'steal_tech',
  targetTileKey: 'newWorld|nw1|0|0',
);

void main() {
  group('shouldSuppressWorkOrderFromPhasePlan — EXPAND', () {
    const expand = PhasePlanOutcome(phase: ObserverGoalPhase.expand);

    test('drops NW purchase_land (acquisition path)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwPurchaseLand, expand),
        isTrue,
      );
    });

    test('drops NW build_improvement (improvement path)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwBuildImprovement, expand),
        isTrue,
      );
    });

    test('keeps OW purchase_land (OW path is not suppressed in EXPAND)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owPurchaseLand, expand),
        isFalse,
      );
    });

    test('keeps OW build_improvement (OW improvement path stays open)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owBuildImprovement, expand),
        isFalse,
      );
    });

    test('keeps non-acquisition/non-improvement targets (e.g. steal_tech)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_stealTechAnyRegion, expand),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — COLONIAL-lite', () {
    const colonialLite = PhasePlanOutcome(
      phase: ObserverGoalPhase.colonialLite,
    );

    test('drops NW purchase_land (safeguard suppresses NW acquisition)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwPurchaseLand, colonialLite),
        isTrue,
      );
    });

    test('keeps NW build_improvement (region-scoped suppression is NW '
        'purchase_land only)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwBuildImprovement, colonialLite),
        isFalse,
      );
    });

    test('keeps OW purchase_land (suppression is NW-only)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owPurchaseLand, colonialLite),
        isFalse,
      );
    });

    test('keeps OW build_improvement (OW push continues under safeguard)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          _owBuildImprovement,
          colonialLite,
        ),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — DEVELOP', () {
    const develop = PhasePlanOutcome(phase: ObserverGoalPhase.develop);

    test('drops NW purchase_land (DEVELOP suppresses new NW acquisition)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwPurchaseLand, develop),
        isTrue,
      );
    });

    test('keeps NW build_improvement (70 % turn-150 gate covers both '
        'OW and NW resource tiles)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwBuildImprovement, develop),
        isFalse,
      );
    });

    test('keeps OW purchase_land (suppression is region-scoped)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owPurchaseLand, develop),
        isFalse,
      );
    });

    test('keeps OW build_improvement (improvement-first imperative)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owBuildImprovement, develop),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — COLONIAL', () {
    const colonial = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);

    test('keeps NW purchase_land (COLONIAL imperative needs it)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwPurchaseLand, colonial),
        isFalse,
      );
    });

    test('keeps NW build_improvement (COLONIAL imperative needs it)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwBuildImprovement, colonial),
        isFalse,
      );
    });

    test('keeps OW purchase_land', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owPurchaseLand, colonial),
        isFalse,
      );
    });

    test('keeps OW build_improvement', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_owBuildImprovement, colonial),
        isFalse,
      );
    });

    test('keeps non-acquisition targets (e.g. steal_tech)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_stealTechAnyRegion, colonial),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — determinism', () {
    test('identical (order, phase) pair yields identical result on repeat', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      final first = shouldSuppressWorkOrderFromPhasePlan(
        _nwPurchaseLand,
        outcome,
      );
      final second = shouldSuppressWorkOrderFromPhasePlan(
        _nwPurchaseLand,
        outcome,
      );
      expect(first, isTrue);
      expect(second, isTrue);
      expect(first, equals(second));
    });

    test('phase change with identical order flips suppression deterministically',
        () {
      const expand = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      const colonial = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwBuildImprovement, expand),
        isTrue,
      );
      expect(
        shouldSuppressWorkOrderFromPhasePlan(_nwBuildImprovement, colonial),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — outcome slot independence', () {
    test('only `phase` drives suppression — sibling slots have no effect',
        () {
      const populatedExpand = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minor1',
        expandPeaceTargetFactionIdsSorted: ['gp2', 'gp3'],
        colonialCivilianWorkOrders: [_nwPurchaseLand],
        developCivilianWorkOrders: [_owBuildImprovement],
      );
      const bareExpand = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          _nwPurchaseLand,
          populatedExpand,
        ),
        equals(
          shouldSuppressWorkOrderFromPhasePlan(_nwPurchaseLand, bareExpand),
        ),
      );
    });
  });
}
