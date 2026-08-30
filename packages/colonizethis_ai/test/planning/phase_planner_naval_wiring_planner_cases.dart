// Case bodies for `phase_planner_naval_wiring_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_naval_wiring_planner_support.dart';
import 'phase_planner_naval_wiring_planner_cases_tail_cases.dart';

void registerPhasePlannerNavalWiringPlannerCases() {
  group('runNavalPlanner phase naval wiring', () {
    late PhaseNavalWiringPlannerFixture fixture;

    setUp(() {
      fixture = PhaseNavalWiringPlannerFixture.build();
    });

    test(
      'COLONIAL phase plan engages colonial naval boost at full NW weight '
      '(emits naval move) — Refs #2847 Phase 3 identity-equal-to-legacy pin',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialNavalPlan: kPhaseNavalWiringColonialNavalPriority,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.10,
            newWorldAcquisition: 1.0,
            oldWorldCivilian: 0.05,
            newWorldCivilian: 0.95,
          ),
        );
        final orders = runNavalPlanner(
          ctx: fixture.ctx,
          snapshot: fixture.snapshot,
          phasePlan: phasePlan,
        );
        final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(
          moves,
          isNotEmpty,
          reason:
              'COLONIAL phase plan with newWorldAcquisition = 1.0 must keep '
              'the colonial naval boost identity-equal to the legacy '
              'hard-phase magnitude so henry (military 20) clears the '
              '< kNavalRunMinWeight skip floor and the NW naval candidate '
              'is emitted (Phase 3 full-weight identity pin).',
        );
      },
    );

    test(
      'COLONIAL-lite phase plan engages colonial naval boost at full NW '
      'weight (emits naval move) — Refs #2847 Phase 3 identity pin',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonialLite,
          colonialLiteNavalPlan: kPhaseNavalWiringColonialLiteNavalPriority,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.10,
            newWorldAcquisition: 1.0,
            oldWorldCivilian: 0.05,
            newWorldCivilian: 0.95,
          ),
        );
        final orders = runNavalPlanner(
          ctx: fixture.ctx,
          snapshot: fixture.snapshot,
          phasePlan: phasePlan,
        );
        final moves = orders.navalMoveOrdersByPlayerId['gp1'] ?? const [];
        expect(
          moves,
          isNotEmpty,
          reason:
              'COLONIAL-lite phase plan with newWorldAcquisition = 1.0 '
              'must keep the boost identity-equal to legacy so henry '
              'clears the < kNavalRunMinWeight skip floor (Phase 3 '
              'full-weight identity pin).',
        );
      },
    );

    test(
      'COLONIAL phase plan with early-sprint default weights collapses the '
      'boost (no naval move) — Refs #2847 Phase 3 early-sprint collapse pin',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.colonial,
          colonialNavalPlan: kPhaseNavalWiringColonialNavalPriority,
        );
        final orders = runNavalPlanner(
          ctx: fixture.ctx,
          snapshot: fixture.snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.navalMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'COLONIAL phase plan with earlySprintDefault priorityWeights '
              '(newWorldAcquisition = 0.05) must collapse the colonial '
              'naval boost so henry (military 20) stays below the '
              '< kNavalRunMinWeight skip floor — Phase 3 soft-phase '
              'intent under the early-sprint curve.',
        );
      },
    );

    test(
      'EXPAND phase plan suppresses colonial naval boost on the early-sprint '
      'default curve (no naval move)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
        final orders = runNavalPlanner(
          ctx: fixture.ctx,
          snapshot: fixture.snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.navalMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'EXPAND phase plan with earlySprintDefault priorityWeights '
              '(newWorldAcquisition = 0.05) collapses the colonial boost '
              'below the < kNavalRunMinWeight skip floor; henry stays '
              'below the floor.',
        );
      },
    );
  });

  registerPhasePlannerNavalWiringPlannerCasesTail();
}
