// Case bodies for `phase_planner_naval_plans_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

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

const ColonialNavalPlan kColonialNavalSingleOwner = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>['newWorld|tribe_a|nw1'],
  priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
);

const ColonialNavalPlan kColonialNavalMultiOwner = ColonialNavalPlan(
  priorityInvasionTransportProvinceIdsSorted: <String>[
    'newWorld|gp_b|nw2',
    'newWorld|tribe_a|nw1',
    'newWorld|tribe_a|nw3',
  ],
  priorityTargetOwnerFactionIdsSorted: <String>['gp_b', 'tribe_a'],
);

const ColonialLiteNavalPlan kColonialLiteNavalSingleOwner =
    ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>['newWorld|tribe_a|nw1'],
      priorityTargetOwnerFactionIdsSorted: <String>['tribe_a'],
    );

const ColonialLiteNavalPlan kColonialLiteNavalMultiOwner =
    ColonialLiteNavalPlan(
      priorityNwProvinceIdsSorted: <String>[
        'newWorld|minor_b|nw2',
        'newWorld|tribe_a|nw1',
        'newWorld|tribe_a|nw3',
      ],
      priorityTargetOwnerFactionIdsSorted: <String>['minor_b', 'tribe_a'],
    );


void registerPhasePlannerNavalPlansAdapterCases() {
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
        colonialNavalPlan: kColonialNavalMultiOwner,
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
        colonialLiteNavalPlan: kColonialLiteNavalMultiOwner,
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
        colonialNavalPlan: kColonialNavalMultiOwner,
        colonialLiteNavalPlan: kColonialLiteNavalMultiOwner,
      );
      expect(colonialNavalPlanFromPhasePlan(outcome), kColonialNavalMultiOwner);
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
        colonialNavalPlan: kColonialNavalMultiOwner,
        colonialLiteNavalPlan: kColonialLiteNavalMultiOwner,
      );
      expect(
        colonialLiteNavalPlanFromPhasePlan(outcome),
        kColonialLiteNavalMultiOwner,
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
}
