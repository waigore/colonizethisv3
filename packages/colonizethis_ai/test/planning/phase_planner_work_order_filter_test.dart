// Adapter: SPEC/ai/phase-planner-dispatch.md work-order filter row (Refs #2509, #4602).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_work_order_filter.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_work_order_filter_non_expand_cases.dart';
import 'phase_planner_work_order_filter_support.dart';

void main() {
  group('shouldSuppressWorkOrderFromPhasePlan — EXPAND', () {
    const expand = PhasePlanOutcome(phase: ObserverGoalPhase.expand);

    test('keeps NW purchase_land when soft-phase NW weight > 0', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwPurchaseLand,
          expand,
        ),
        isFalse,
      );
    });

    test('keeps NW build_improvement when soft-phase NW weight > 0', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwBuildImprovement,
          expand,
        ),
        isFalse,
      );
    });

    test('drops NW purchase_land when NW weight is zero (legacy guard)', () {
      const zeroWeightExpand = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        priorityWeights: kWorkOrderFilterNwAcquisitionZeroExpand,
      );
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwPurchaseLand,
          zeroWeightExpand,
        ),
        isTrue,
      );
    });

    test(
      'drops NW build_improvement when NW weight is zero (legacy guard)',
      () {
        const zeroWeightExpand = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: kWorkOrderFilterNwAcquisitionZeroExpand,
        );
        expect(
          shouldSuppressWorkOrderFromPhasePlan(
            kWorkOrderFilterNwBuildImprovement,
            zeroWeightExpand,
          ),
          isTrue,
        );
      },
    );

    test('keeps OW purchase_land (OW path is not suppressed in EXPAND)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwPurchaseLand,
          expand,
        ),
        isFalse,
      );
    });

    test('keeps OW build_improvement (OW improvement path stays open)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwBuildImprovement,
          expand,
        ),
        isFalse,
      );
    });

    test(
      'keeps non-acquisition/non-improvement targets (e.g. counter_spy)',
      () {
        expect(
          shouldSuppressWorkOrderFromPhasePlan(
            kWorkOrderFilterCounterSpyAnyRegion,
            expand,
          ),
          isFalse,
        );
      },
    );
  });

  registerPhasePlannerWorkOrderFilterNonExpandCases();
}
