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

const ExpandEconomyPlan _rebuildOnly = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: false,
);

const ExpandEconomyPlan _boostOnly = ExpandEconomyPlan(
  forceCheapestRegimentBuild: false,
  boostTreasuryRecoveryCargo: true,
);

const ExpandEconomyPlan _rebuildAndBoost = ExpandEconomyPlan(
  forceCheapestRegimentBuild: true,
  boostTreasuryRecoveryCargo: true,
);

void main() {
  group('expandEconomyPlanFromPhasePlan — phase routing', () {
    test('EXPAND surfaces expandEconomyPlan verbatim (rebuild + boost)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: _rebuildAndBoost,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), _rebuildAndBoost);
    });

    test('EXPAND surfaces expandEconomyPlan verbatim (rebuild only)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: _rebuildOnly,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), _rebuildOnly);
    });

    test('EXPAND surfaces expandEconomyPlan verbatim (boost only)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: _boostOnly,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), _boostOnly);
    });

    test('COLONIAL-lite surfaces expandEconomyPlan verbatim '
        '(OW push continues during safeguard)', () {
      // Issue #2509 § COLONIAL-lite: "Begin NW overture/naval penetration
      // without weakening OW push". The EXPAND economy directive must
      // survive the safeguard so a below-quota GP can still force a
      // regiment rebuild while running COLONIAL-lite overtures.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandEconomyPlan: _rebuildAndBoost,
      );
      expect(expandEconomyPlanFromPhasePlan(outcome), _rebuildAndBoost);
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
      // Defensive: the dispatcher never populates expandEconomyPlan in
      // COLONIAL, but the adapter must short-circuit on phase to defend
      // the suppression matrix against a future regression that leaks
      // an EXPAND directive into the COLONIAL economy pass (which is
      // driven by colonialCivilianWorkOrders + the COLONIAL build cap,
      // not the EXPAND regiment-rebuild crisis arm).
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandEconomyPlan: _rebuildAndBoost,
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
      // Defensive: the DEVELOP phase has its own civilian-build cadence
      // (developCivilianWorkOrders) and no EXPAND regiment-rebuild
      // crisis path. Even if a future regression populated
      // expandEconomyPlan under DEVELOP, the adapter must keep
      // returning ExpandEconomyPlan.defaultPlan.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandEconomyPlan: _rebuildAndBoost,
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
        expandEconomyPlan: _rebuildAndBoost,
      );
      final result = expandEconomyPlanFromPhasePlan(outcome);
      expect(result.forceCheapestRegimentBuild, isTrue);
      expect(result.boostTreasuryRecoveryCargo, isTrue);
    });

    test('COLONIAL-lite preserves both ExpandEconomyPlan field values', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandEconomyPlan: _boostOnly,
      );
      final result = expandEconomyPlanFromPhasePlan(outcome);
      expect(result.forceCheapestRegimentBuild, isFalse);
      expect(result.boostTreasuryRecoveryCargo, isTrue);
    });
  });

  group('expandEconomyPlanFromPhasePlan — determinism (Must-have #7)', () {
    test('identical EXPAND outcomes yield identical plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandEconomyPlan: _rebuildOnly,
      );
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL-lite outcomes yield identical plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandEconomyPlan: _boostOnly,
      );
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL outcomes yield identical ExpandEconomyPlan'
        '.defaultPlan', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical ExpandEconomyPlan'
        '.defaultPlan', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        expandEconomyPlanFromPhasePlan(outcome),
        expandEconomyPlanFromPhasePlan(outcome),
      );
    });
  });
}
