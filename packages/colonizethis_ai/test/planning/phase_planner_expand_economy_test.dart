// Unit tests for `phase_planner_expand_economy.dart`
// (Refs #2509 S5 orchestrator adapter slice).
//
// Adapter contract pinned here (from
// `SPEC/ai/phase-planner-dispatch.md` § Adapter helpers — updated by
// this slice to add the EXPAND economy row):
//
//   expandEconomyPlanFromPhasePlan(outcome):
//     - EXPAND          -> outcome.expandEconomyPlan
//     - COLONIAL-lite   -> outcome.expandEconomyPlan
//     - COLONIAL        -> ExpandEconomyPlan.defaultPlan
//     - DEVELOP         -> ExpandEconomyPlan.defaultPlan
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already
// covered by `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandEconomyPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_expand_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_expand_economy_determinism_cases.dart';
import 'phase_planner_expand_economy_test_support.dart';

void main() {
  group('expandEconomyPlanFromPhasePlan — phase routing', () {
    test('EXPAND surfaces expandEconomyPlan verbatim (rebuild + boost)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: kExpandEconomyRebuildAndBoost,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), kExpandEconomyRebuildAndBoost);
    });

    test('EXPAND surfaces expandEconomyPlan verbatim (rebuild only)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: kExpandEconomyRebuildOnly,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), kExpandEconomyRebuildOnly);
    });

    test('EXPAND surfaces expandEconomyPlan verbatim (boost only)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: kExpandEconomyBoostOnly,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), kExpandEconomyBoostOnly);
    });

    test('COLONIAL-lite surfaces expandEconomyPlan verbatim '
        '(OW push continues during safeguard)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandEconomyPlan: kExpandEconomyRebuildAndBoost,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), kExpandEconomyRebuildAndBoost);
    });

    test('COLONIAL routes to ExpandEconomyPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        ExpandEconomyPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ExpandEconomyPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        ExpandEconomyPlan.defaultPlan,
      );
    });
  });

  group('expandEconomyPlanFromPhasePlan — defensive phase suppression', () {
    test('COLONIAL surfaces ExpandEconomyPlan.defaultPlan even when EXPAND '
        'slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandEconomyPlan: kExpandEconomyRebuildAndBoost,
      );
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        ExpandEconomyPlan.defaultPlan,
        reason:
            'COLONIAL has no EXPAND economy override by spec; a '
            'non-default expandEconomyPlan slot must not leak the EXPAND '
            'regiment-rebuild crisis arm into the COLONIAL economy pass.',
      );
    });

    test('DEVELOP surfaces ExpandEconomyPlan.defaultPlan even when EXPAND '
        'slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandEconomyPlan: kExpandEconomyRebuildAndBoost,
      );
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        ExpandEconomyPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no EXPAND economy override; the '
            'structural phase separation must hold at the adapter layer '
            'even if dispatcher slots are populated.',
      );
    });

    test(
      'EXPAND surfaces ExpandEconomyPlan.defaultPlan when slot is default',
      () {
        const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        expect(
          expandEconomyPlanFromPhasePlan(outcome),
          ExpandEconomyPlan.defaultPlan,
        );
      },
    );

    test('COLONIAL-lite surfaces ExpandEconomyPlan.defaultPlan when slot is '
        'default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        ExpandEconomyPlan.defaultPlan,
      );
    });
  });

  group('expandEconomyPlanFromPhasePlan — default outcome constants', () {
    test('defaultExpand surfaces ExpandEconomyPlan.defaultPlan', () {
      expect(
        expandEconomyPlanFromPhasePlan(PhasePlanOutcome.defaultExpand),
        ExpandEconomyPlan.defaultPlan,
      );
    });

    test('defaultColonialLite surfaces ExpandEconomyPlan.defaultPlan', () {
      expect(
        expandEconomyPlanFromPhasePlan(PhasePlanOutcome.defaultColonialLite),
        ExpandEconomyPlan.defaultPlan,
      );
    });

    test('defaultColonial surfaces ExpandEconomyPlan.defaultPlan', () {
      expect(
        expandEconomyPlanFromPhasePlan(PhasePlanOutcome.defaultColonial),
        ExpandEconomyPlan.defaultPlan,
      );
    });

    test('defaultDevelop surfaces ExpandEconomyPlan.defaultPlan', () {
      expect(
        expandEconomyPlanFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        ExpandEconomyPlan.defaultPlan,
      );
    });
  });

  group('expandEconomyPlanFromPhasePlan — value preservation', () {
    test('EXPAND preserves both ExpandEconomyPlan field values', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: kExpandEconomyRebuildAndBoost,
      );
      final result = expandEconomyPlanFromPhasePlan(outcome);
      expect(result.forceCheapestRegimentBuild, isTrue);
      expect(result.boostTreasuryRecoveryCargo, isTrue);
    });

    test('COLONIAL-lite preserves both ExpandEconomyPlan field values', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandEconomyPlan: kExpandEconomyBoostOnly,
      );
      final result = expandEconomyPlanFromPhasePlan(outcome);
      expect(result.forceCheapestRegimentBuild, isFalse);
      expect(result.boostTreasuryRecoveryCargo, isTrue);
    });
  });

  registerPhasePlannerExpandEconomyDeterminismCases();
}
