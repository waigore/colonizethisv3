// Non-EXPAND cases for phase_planner_work_order_filter_test.dart (Refs #4602).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_work_order_filter.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_work_order_filter_support.dart';

void registerPhasePlannerWorkOrderFilterNonExpandCases() {
  group('shouldSuppressWorkOrderFromPhasePlan — COLONIAL-lite', () {
    const colonialLite = PhasePlanOutcome(
      phase: ObserverGoalPhase.colonialLite,
    );

    test('drops NW purchase_land (safeguard suppresses NW acquisition)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwPurchaseLand,
          colonialLite,
        ),
        isTrue,
      );
    });

    test('keeps NW build_improvement (region-scoped suppression is NW '
        'purchase_land only)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwBuildImprovement,
          colonialLite,
        ),
        isFalse,
      );
    });

    test('keeps OW purchase_land (suppression is NW-only)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwPurchaseLand,
          colonialLite,
        ),
        isFalse,
      );
    });

    test('keeps OW build_improvement (OW push continues under safeguard)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwBuildImprovement,
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
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwPurchaseLand,
          develop,
        ),
        isTrue,
      );
    });

    test('keeps NW build_improvement (70 % turn-150 gate covers both '
        'OW and NW resource tiles)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwBuildImprovement,
          develop,
        ),
        isFalse,
      );
    });

    test('keeps OW purchase_land (suppression is region-scoped)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwPurchaseLand,
          develop,
        ),
        isFalse,
      );
    });

    test('keeps OW build_improvement (improvement-first imperative)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwBuildImprovement,
          develop,
        ),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — COLONIAL', () {
    const colonial = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);

    test('keeps NW purchase_land (COLONIAL imperative needs it)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwPurchaseLand,
          colonial,
        ),
        isFalse,
      );
    });

    test('keeps NW build_improvement (COLONIAL imperative needs it)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwBuildImprovement,
          colonial,
        ),
        isFalse,
      );
    });

    test('keeps OW purchase_land', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwPurchaseLand,
          colonial,
        ),
        isFalse,
      );
    });

    test('keeps OW build_improvement', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterOwBuildImprovement,
          colonial,
        ),
        isFalse,
      );
    });

    test('keeps non-acquisition targets (e.g. counter_spy)', () {
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterCounterSpyAnyRegion,
          colonial,
        ),
        isFalse,
      );
    });
  });

  group('shouldSuppressWorkOrderFromPhasePlan — determinism', () {
    test('identical (order, phase) pair yields identical result on repeat', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      final first = shouldSuppressWorkOrderFromPhasePlan(
        kWorkOrderFilterNwPurchaseLand,
        outcome,
      );
      final second = shouldSuppressWorkOrderFromPhasePlan(
        kWorkOrderFilterNwPurchaseLand,
        outcome,
      );
      expect(first, isFalse);
      expect(second, isFalse);
      expect(first, equals(second));
    });

    test(
      'phase change with identical order flips suppression deterministically',
      () {
        const expand = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        const colonial = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
        expect(
          shouldSuppressWorkOrderFromPhasePlan(
            kWorkOrderFilterNwBuildImprovement,
            expand,
          ),
          isFalse,
        );
        expect(
          shouldSuppressWorkOrderFromPhasePlan(
            kWorkOrderFilterNwBuildImprovement,
            colonial,
          ),
          isFalse,
        );
      },
    );
  });

  group('shouldSuppressWorkOrderFromPhasePlan — outcome slot independence', () {
    test('only `phase` drives suppression — sibling slots have no effect', () {
      const populatedExpand = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDeclareWarTargetFactionId: 'minor1',
        expandPeaceTargetFactionIdsSorted: ['gp2', 'gp3'],
        colonialCivilianWorkOrders: [kWorkOrderFilterNwPurchaseLand],
        developCivilianWorkOrders: [kWorkOrderFilterOwBuildImprovement],
      );
      const bareExpand = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        shouldSuppressWorkOrderFromPhasePlan(
          kWorkOrderFilterNwPurchaseLand,
          populatedExpand,
        ),
        equals(
          shouldSuppressWorkOrderFromPhasePlan(
            kWorkOrderFilterNwPurchaseLand,
            bareExpand,
          ),
        ),
      );
    });
  });
}
