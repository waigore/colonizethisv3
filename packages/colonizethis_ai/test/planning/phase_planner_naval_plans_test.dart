// Unit tests for `phase_planner_naval_plans.dart`
// (Refs #2509 S5 orchestrator adapter slice).
//
// Adapter contracts pinned here (from `SPEC/ai/phase-planner-dispatch.md`
// § Adapter helpers — updated by this slice to add the COLONIAL and
// COLONIAL-lite naval-plan rows):
//
//   colonialNavalPlanFromPhasePlan(outcome):
//     - EXPAND          -> ColonialNavalPlan.defaultPlan
//     - COLONIAL-lite   -> ColonialNavalPlan.defaultPlan
//     - COLONIAL        -> outcome.colonialNavalPlan
//     - DEVELOP         -> ColonialNavalPlan.defaultPlan
//
//   colonialLiteNavalPlanFromPhasePlan(outcome):
//     - EXPAND          -> ColonialLiteNavalPlan.defaultPlan
//     - COLONIAL-lite   -> outcome.colonialLiteNavalPlan
//     - COLONIAL        -> ColonialLiteNavalPlan.defaultPlan
//     - DEVELOP         -> ColonialLiteNavalPlan.defaultPlan
//
// Fixtures here construct `PhasePlanOutcome` instances directly so the
// tests do not require a `Game` / `AIWorldSnapshot` pair. Outcome
// composition from real `runPhasePlanners` dispatches is already
// covered by `phase_planner_dispatch_test.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart'
    show ColonialLiteNavalPlan, ColonialNavalPlan;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_priority_weights.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_naval_plans.dart';
import 'package:colonizethis_test/test.dart';

const PhasePriorityWeights _nwAcquisitionZeroExpand = PhasePriorityWeights(
  oldWorldConquest: 0.95,
  newWorldAcquisition: 0.0,
  oldWorldCivilian: 0.90,
  newWorldCivilian: 0.10,
);

const ColonialNavalPlan _colonialNavalSingleOwner = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe_a|nw1'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
);

const ColonialNavalPlan _colonialNavalMultiOwner = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>[
    'newWorld|gp_b|nw2',
    'newWorld|tribe_a|nw1',
    'newWorld|tribe_a|nw3',
  ],
  priorityTargetOwnerFactionIdsSorted: <String>['gp_b', 'tribe_a'],
);

const ColonialLiteNavalPlan _colonialLiteNavalSingleOwner =
    ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>['newWorld|tribe_a|nw1'],
      priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
    );

const ColonialLiteNavalPlan _colonialLiteNavalMultiOwner =
    ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>[
        'newWorld|minor_b|nw2',
        'newWorld|tribe_a|nw1',
        'newWorld|tribe_a|nw3',
      ],
      priorityTargetOwnerFactionIdsSorted: <String>['minor_b', 'tribe_a'],
    );

void main() {
  group('colonialNavalPlanFromPhasePlan — phase routing', () {
    test('COLONIAL surfaces colonialNavalPlan verbatim (single owner)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalSingleOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        _colonialNavalSingleOwner,
      );
    });

    test('COLONIAL surfaces colonialNavalPlan verbatim (multi-owner '
        'at-war fallback incl. GP target)', () {
      // COLONIAL allows invasion transport against any faction class,
      // including GPs blocking the colonial frontier (issue #2509 §
      // planColonialAcquisition acquisition method 3). The adapter
      // must preserve the GP-inclusive owner list verbatim.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalMultiOwner,
      );
      expect(colonialNavalPlanFromPhasePlan(outcome), _colonialNavalMultiOwner);
    });

    test('EXPAND routes to ColonialNavalPlan.defaultPlan (structural '
        'NW suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
      );
    });

    test('COLONIAL-lite routes to ColonialNavalPlan.defaultPlan '
        '(safeguard suppresses NW invasion transport)', () {
      // Issue #2509 § COLONIAL-lite "Never suggest invasion transport
      // or NW army staging here" — the COLONIAL-lite naval pass runs
      // exploration + cargo only via `colonialLiteNavalPlan`. The
      // COLONIAL invasion-transport directive must never leak into the
      // COLONIAL-lite naval pass.
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ColonialNavalPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
      );
    });
  });

  group('colonialNavalPlanFromPhasePlan — defensive phase suppression', () {
    test('EXPAND with newWorldAcquisition=0 surfaces default even when '
        'COLONIAL slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialNavalPlan: _colonialNavalMultiOwner,
        priorityWeights: _nwAcquisitionZeroExpand,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
      );
    });

    test('EXPAND with newWorldAcquisition>0 surfaces colonialNavalPlan '
        '(Refs #2847)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialNavalPlan: _colonialNavalMultiOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        _colonialNavalMultiOwner,
      );
    });

    test('COLONIAL-lite surfaces ColonialNavalPlan.defaultPlan even '
        'when COLONIAL slot non-default', () {
      // The COLONIAL-lite safeguard explicitly suppresses NW invasion
      // transport (issue #2509 § COLONIAL-lite scope summary).
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialNavalPlan: _colonialNavalMultiOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
        reason:
            'COLONIAL-lite explicitly suppresses NW invasion transport; '
            'a populated colonialNavalPlan slot must be filtered at '
            'the adapter layer.',
      );
    });

    test('DEVELOP surfaces ColonialNavalPlan.defaultPlan even when '
        'COLONIAL slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialNavalPlan: _colonialNavalMultiOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no naval override; the '
            'structural phase separation must hold at the adapter '
            'layer even if dispatcher slots are populated.',
      );
    });

    test('COLONIAL surfaces ColonialNavalPlan.defaultPlan when slot is '
        'default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
      );
    });
  });

  group('colonialLiteNavalPlanFromPhasePlan — phase routing', () {
    test('COLONIAL-lite surfaces colonialLiteNavalPlan verbatim '
        '(single owner)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: _colonialLiteNavalSingleOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        _colonialLiteNavalSingleOwner,
      );
    });

    test('COLONIAL-lite surfaces colonialLiteNavalPlan verbatim '
        '(multi-owner tribe + minor union)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        _colonialLiteNavalMultiOwner,
      );
    });

    test('EXPAND routes to ColonialLiteNavalPlan.defaultPlan (structural '
        'NW suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });

    test('COLONIAL routes to ColonialLiteNavalPlan.defaultPlan '
        '(full COLONIAL drives invasion transport via colonialNavalPlan, '
        'not the tribe/minor-only filter)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });

    test('DEVELOP routes to ColonialLiteNavalPlan.defaultPlan (structural '
        'suppression)', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });
  });

  group('colonialLiteNavalPlanFromPhasePlan — defensive phase suppression', () {
    test('EXPAND surfaces ColonialLiteNavalPlan.defaultPlan even when '
        'COLONIAL-lite slot non-default', () {
      // Defensive: the dispatcher never populates colonialLiteNavalPlan
      // in EXPAND, but the adapter must short-circuit on phase to
      // defend the structural NW suppression matrix.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
        reason:
            'EXPAND must never emit NW naval focus; a non-default '
            'colonialLiteNavalPlan slot must not leak the tribe/minor '
            'NW filter into the EXPAND naval pass.',
      );
    });

    test('COLONIAL surfaces ColonialLiteNavalPlan.defaultPlan even when '
        'COLONIAL-lite slot non-default', () {
      // Defensive: full COLONIAL drives invasion transport through
      // colonialNavalPlan (GP-inclusive); the COLONIAL-lite tribe /
      // minor-only filter must not be reused by the full-COLONIAL
      // naval pass.
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
        reason:
            'Full COLONIAL drives invasion transport via '
            'colonialNavalPlan; the COLONIAL-lite tribe/minor-only '
            'filter must be suppressed under the COLONIAL phase.',
      );
    });

    test('DEVELOP surfaces ColonialLiteNavalPlan.defaultPlan even when '
        'COLONIAL-lite slot non-default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
        reason:
            'DEVELOP intentionally has no naval override; the '
            'structural phase separation must hold at the adapter '
            'layer even if dispatcher slots are populated.',
      );
    });

    test('COLONIAL-lite surfaces ColonialLiteNavalPlan.defaultPlan when '
        'slot is default', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonialLite);
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });
  });

  group('naval adapters — default outcome constants', () {
    test('defaultExpand surfaces ColonialNavalPlan.defaultPlan and '
        'ColonialLiteNavalPlan.defaultPlan', () {
      expect(
        colonialNavalPlanFromPhasePlan(PhasePlanOutcome.defaultExpand),
        ColonialNavalPlan.defaultPlan,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(PhasePlanOutcome.defaultExpand),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });

    test('defaultColonialLite surfaces ColonialNavalPlan.defaultPlan and '
        'ColonialLiteNavalPlan.defaultPlan', () {
      expect(
        colonialNavalPlanFromPhasePlan(PhasePlanOutcome.defaultColonialLite),
        ColonialNavalPlan.defaultPlan,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(
          PhasePlanOutcome.defaultColonialLite,
        ),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });

    test('defaultColonial surfaces ColonialNavalPlan.defaultPlan and '
        'ColonialLiteNavalPlan.defaultPlan', () {
      expect(
        colonialNavalPlanFromPhasePlan(PhasePlanOutcome.defaultColonial),
        ColonialNavalPlan.defaultPlan,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(PhasePlanOutcome.defaultColonial),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });

    test('defaultDevelop surfaces ColonialNavalPlan.defaultPlan and '
        'ColonialLiteNavalPlan.defaultPlan', () {
      expect(
        colonialNavalPlanFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        ColonialNavalPlan.defaultPlan,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(PhasePlanOutcome.defaultDevelop),
        ColonialLiteNavalPlan.defaultPlan,
      );
    });
  });

  group('naval adapters — value preservation', () {
    test('COLONIAL preserves both ColonialNavalPlan list contents in '
        'order', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalMultiOwner,
      );
      final result = colonialNavalPlanFromPhasePlan(outcome);
      expect(result.priorityInvasionTransportProvinceIdsSorted, const <String>[
        'newWorld|gp_b|nw2',
        'newWorld|tribe_a|nw1',
        'newWorld|tribe_a|nw3',
      ]);
      expect(result.priorityTargetOwnerFactionIdsSorted, const <String>[
        'gp_b',
        'tribe_a',
      ]);
    });

    test('COLONIAL-lite preserves both ColonialLiteNavalPlan list '
        'contents in order', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      final result = colonialLiteNavalPlanFromPhasePlan(outcome);
      expect(result.priorityNwProvinceIdsSorted, const <String>[
        'newWorld|minor_b|nw2',
        'newWorld|tribe_a|nw1',
        'newWorld|tribe_a|nw3',
      ]);
      expect(result.priorityTargetOwnerFactionIdsSorted, const <String>[
        'minor_b',
        'tribe_a',
      ]);
    });
  });

  group('naval adapters — mutual exclusion', () {
    test('COLONIAL outcome surfaces invasion plan, COLONIAL-lite filter '
        'default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalMultiOwner,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(colonialNavalPlanFromPhasePlan(outcome), _colonialNavalMultiOwner);
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        ColonialLiteNavalPlan.defaultPlan,
        reason:
            'COLONIAL must drive invasion transport only through '
            'colonialNavalPlan; the COLONIAL-lite tribe/minor filter '
            'must not co-fire under the full-COLONIAL phase.',
      );
    });

    test('COLONIAL-lite outcome surfaces tribe/minor filter, invasion '
        'plan default', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialNavalPlan: _colonialNavalMultiOwner,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        ColonialNavalPlan.defaultPlan,
        reason:
            'COLONIAL-lite explicitly suppresses NW invasion transport; '
            'colonialNavalPlan must default even when populated.',
      );
    });
  });

  group('naval adapters — determinism (Must-have #7)', () {
    test('identical COLONIAL outcomes yield identical naval plans', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: _colonialNavalSingleOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });

    test('identical COLONIAL-lite outcomes yield identical naval plans '
        '(colonial-lite passthrough, colonial default)', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        colonialLiteNavalPlan: _colonialLiteNavalMultiOwner,
      );
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });

    test('identical EXPAND outcomes yield identical defaults for both '
        'adapters', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });

    test('identical DEVELOP outcomes yield identical defaults for both '
        'adapters', () {
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
      expect(
        colonialNavalPlanFromPhasePlan(outcome),
        colonialNavalPlanFromPhasePlan(outcome),
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        colonialLiteNavalPlanFromPhasePlan(outcome),
      );
    });
  });
}
