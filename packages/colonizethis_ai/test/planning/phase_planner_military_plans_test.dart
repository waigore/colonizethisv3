// Unit tests for `phase_planner_military_plans.dart`
// (Refs #2509 S5 orchestrator adapter slice).
//
// Adapter contracts pinned here (from `SPEC/ai/phase-planner-dispatch.md`
// § Adapter helpers — updated by this slice to add the EXPAND and
// COLONIAL military-plan rows):
//
//   expandMilitaryPlanFromPhasePlan(outcome):
//     - EXPAND          -> outcome.expandMilitaryPlan
//     - COLONIAL-lite   -> outcome.expandMilitaryPlan
//     - COLONIAL        -> ExpandMilitaryPlan.defaultPlan
//     - DEVELOP         -> ExpandMilitaryPlan.defaultPlan
//
//   colonialMilitaryPlanFromPhasePlan(outcome):
//     - EXPAND          -> ColonialMilitaryPlan.defaultPlan
//     - COLONIAL-lite   -> ColonialMilitaryPlan.defaultPlan
//     - COLONIAL        -> outcome.colonialMilitaryPlan
//     - DEVELOP         -> ColonialMilitaryPlan.defaultPlan
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already
// covered by `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialMilitaryPlan;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show ExpandMilitaryPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_military_plans.dart';
import 'package:colonizethis_test/test.dart';

const ExpandMilitaryPlan _expandSingleOwner = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['oldWorld|nation_a|p1'],
  priorityTargetOwnerFactionIdsSorted: <String>['nation_a'],
);

const ExpandMilitaryPlan _expandMultiOwner = ExpandMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>[
    'oldWorld|nation_a|p1',
    'oldWorld|nation_b|p2',
    'oldWorld|nation_b|p3',
  ],
  priorityTargetOwnerFactionIdsSorted: <String>['nation_a', 'nation_b'],
);

const ColonialMilitaryPlan _colonialSingleOwner = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe_a|nw1'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
);

const ColonialMilitaryPlan _colonialMultiOwner = ColonialMilitaryPlan(
  priorityDestinationProvinceIdsSorted: <String>[
    'newWorld|tribe_a|nw1',
    'newWorld|tribe_b|nw2',
    'newWorld|tribe_b|nw3',
  ],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe_a', 'tribe_b'],
);

void main() {
  group('expandMilitaryPlanFromPhasePlan — phase routing', () {
    test('EXPAND surfaces expandMilitaryPlan verbatim (single owner)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: _expandSingleOwner,
      );
      expect(expandMilitaryPlanFromPhasePlan(outcome), _expandSingleOwner);
    });

    test('EXPAND surfaces expandMilitaryPlan verbatim (multi-owner '
        'at-war fallback)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandMilitaryPlan: _expandMultiOwner,
      );
      expect(expandMilitaryPlanFromPhasePlan(outcome), _expandMultiOwner);
    });

    test('COLONIAL-lite surfaces expandMilitaryPlan verbatim '
        '(OW push continues during safeguard)', () {
      // Issue #2509 § COLONIAL-lite: "Begin NW overture/naval penetration
      // without weakening OW push". The EXPAND OW conquest filter must
      // survive the safeguard so a below-quota GP can still drive OW
      // army moves while running COLONIAL-lite overtures.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandMilitaryPlan: _expandMultiOwner,
      );
      expect(expandMilitaryPlanFromPhasePlan(outcome), _expandMultiOwner);
    });

    test('COLONIAL routes to ExpandMilitaryPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ExpandMilitaryPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });
  });

  group('expandMilitaryPlanFromPhasePlan — defensive phase suppression', () {
    test('COLONIAL surfaces ExpandMilitaryPlan.defaultPlan even when '
        'EXPAND slot non-default', () {
      // Defensive: the dispatcher never populates expandMilitaryPlan in
      // COLONIAL, but the adapter must short-circuit on phase to defend
      // the suppression matrix against a future regression that leaks
      // an EXPAND OW filter into the COLONIAL military pass (which is
      // driven by planColonialMilitary, not planExpandMilitary).
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        expandMilitaryPlan: _expandMultiOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
        reason:
            'COLONIAL has no EXPAND military override by spec; a '
            'non-default expandMilitaryPlan slot must not leak the EXPAND '
            'OW conquest filter into the COLONIAL military pass.',
      );
    });

    test('DEVELOP surfaces ExpandMilitaryPlan.defaultPlan even when '
        'EXPAND slot non-default', () {
      // Defensive: the DEVELOP phase has no conquest army moves at all
      // (peace ALL at-war GPs per spec). Even if a future regression
      // populated expandMilitaryPlan under DEVELOP, the adapter must
      // keep returning ExpandMilitaryPlan.defaultPlan.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandMilitaryPlan: _expandMultiOwner,
      );
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no military override; the '
            'structural phase separation must hold at the adapter layer '
            'even if dispatcher slots are populated.',
      );
    });

    test('EXPAND surfaces ExpandMilitaryPlan.defaultPlan when slot is '
        'default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });

    test('COLONIAL-lite surfaces ExpandMilitaryPlan.defaultPlan when '
        'slot is default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        expandMilitaryPlanFromPhasePlan(outcome),
        ExpandMilitaryPlan.defaultPlan,
      );
    });
  });

  group('colonialMilitaryPlanFromPhasePlan — phase routing', () {
    test('COLONIAL surfaces colonialMilitaryPlan verbatim (single owner)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: _colonialSingleOwner,
      );
      expect(colonialMilitaryPlanFromPhasePlan(outcome), _colonialSingleOwner);
    });

    test('COLONIAL surfaces colonialMilitaryPlan verbatim (multi-owner '
        'at-war fallback)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialMilitaryPlan: _colonialMultiOwner,
      );
      expect(colonialMilitaryPlanFromPhasePlan(outcome), _colonialMultiOwner);
    });

    test('EXPAND routes to ColonialMilitaryPlan.defaultPlan (structural '
        'NW suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('COLONIAL-lite routes to ColonialMilitaryPlan.defaultPlan '
        '(safeguard suppresses NW invasion army moves)', () {
      // Issue #2509 § COLONIAL-lite scope summary explicitly lists
      // "NW invasion army moves" under Suppressed. The adapter must
      // surface ColonialMilitaryPlan.defaultPlan under COLONIAL-lite
      // even when the dispatcher slot is populated.
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ColonialMilitaryPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });
  });

  group('colonialMilitaryPlanFromPhasePlan — defensive phase suppression', () {
    test('EXPAND surfaces ColonialMilitaryPlan.defaultPlan even when '
        'COLONIAL slot non-default', () {
      // Defensive: the dispatcher never populates colonialMilitaryPlan
      // in EXPAND, but the adapter must short-circuit on phase to
      // defend the structural NW suppression matrix.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialMilitaryPlan: _colonialMultiOwner,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
        reason:
            'EXPAND must never emit NW conquest destinations; a '
            'non-default colonialMilitaryPlan slot must not leak the '
            'NW invasion filter into the EXPAND military pass.',
      );
    });

    test('COLONIAL-lite surfaces ColonialMilitaryPlan.defaultPlan even '
        'when COLONIAL slot non-default', () {
      // The COLONIAL-lite safeguard explicitly suppresses NW invasion
      // army moves (issue #2509 § COLONIAL-lite scope summary).
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialMilitaryPlan: _colonialMultiOwner,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
        reason:
            'COLONIAL-lite explicitly suppresses NW invasion army '
            'moves; a populated colonialMilitaryPlan slot must be '
            'filtered at the adapter layer.',
      );
    });

    test('DEVELOP surfaces ColonialMilitaryPlan.defaultPlan even when '
        'COLONIAL slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialMilitaryPlan: _colonialMultiOwner,
      );
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no military override; the '
            'structural phase separation must hold at the adapter layer '
            'even if dispatcher slots are populated.',
      );
    });

    test('COLONIAL surfaces ColonialMilitaryPlan.defaultPlan when slot '
        'is default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        colonialMilitaryPlanFromPhasePlan(outcome),
        ColonialMilitaryPlan.defaultPlan,
      );
    });
  });

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
        expandMilitaryPlan: _expandMultiOwner,
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
        colonialMilitaryPlan: _colonialMultiOwner,
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
        expandMilitaryPlan: _expandSingleOwner,
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
        expandMilitaryPlan: _expandMultiOwner,
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
        colonialMilitaryPlan: _colonialMultiOwner,
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
