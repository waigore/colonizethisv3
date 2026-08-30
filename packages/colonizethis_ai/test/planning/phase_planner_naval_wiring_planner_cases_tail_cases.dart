// Tail case bodies for `phase_planner_naval_wiring_planner_cases.dart`.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/naval_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_naval_wiring_planner_support.dart';

void registerPhasePlannerNavalWiringPlannerCasesTail() {
  group('runNavalPlanner phase naval wiring', () {
    late PhaseNavalWiringPlannerFixture fixture;

    setUp(() {
      fixture = PhaseNavalWiringPlannerFixture.build();
    });

    test(
      'EXPAND phase plan with NW treasury-recovery override (0.60) engages '
      'the boost (emits naval move) — Refs #2847 Phase 3 resource-need pin',
      () {
        const phasePlan = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          priorityWeights: PhasePriorityWeights(
            oldWorldConquest: 0.95,
            newWorldAcquisition: 0.60,
            oldWorldCivilian: 0.90,
            newWorldCivilian: 0.10,
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
              'EXPAND phase plan with newWorldAcquisition = 0.60 '
              '(resource-need override) must lift the naval-pass weight '
              'above kNavalRunMinWeight via the colonial-pressure floor '
              'so the naval planner engages under EXPAND-lock recovery '
              'without the GP needing to reach COLONIAL first '
              '(Phase 3 resource-need pin).',
        );
      },
    );

    test(
      'DEVELOP phase plan suppresses colonial naval boost on the '
      'early-sprint default curve (no naval move)',
      () {
        const phasePlan = PhasePlanOutcome(phase: ObserverGoalPhase.develop);
        final orders = runNavalPlanner(
          ctx: fixture.ctx,
          snapshot: fixture.snapshot,
          phasePlan: phasePlan,
        );
        expect(
          orders.navalMoveOrdersByPlayerId['gp1'],
          isNull,
          reason:
              'DEVELOP phase plan with earlySprintDefault priorityWeights '
              '(newWorldAcquisition = 0.05) collapses the colonial boost '
              'below the < kNavalRunMinWeight skip floor; henry stays '
              'below the floor.',
        );
      },
    );

    test('null phase plan preserves legacy colonial-pressure gate', () {
      final orders = runNavalPlanner(
        ctx: fixture.ctx,
        snapshot: fixture.snapshot,
      );
      expect(
        orders.navalMoveOrdersByPlayerId['gp1'],
        isNull,
        reason:
            'Without a phase plan the planner must keep the legacy '
            '`hasColonialAcquisitionTargets` + `shouldSuppressNewWorldColonialOrders` '
            'gate; with the GP at OW=1 it stays in EXPAND and the boost '
            'remains suppressed -- behavior unchanged vs origin/dev.',
      );
    });

    test('deterministic naval orders for identical phase-plan inputs', () {
      const phasePlan = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialNavalPlan: kPhaseNavalWiringColonialNavalPriority,
      );
      final first = runNavalPlanner(
        ctx: fixture.ctx,
        snapshot: fixture.snapshot,
        phasePlan: phasePlan,
      );
      final second = runNavalPlanner(
        ctx: fixture.ctx,
        snapshot: fixture.snapshot,
        phasePlan: phasePlan,
      );
      List<String> fingerprint(Orders orders) => <String>[
        for (final m in orders.navalMoveOrdersByPlayerId['gp1'] ?? const [])
          '${m.fleetId}|${m.destinationSeaZoneId ?? ''}|'
              '${m.destinationPortProvinceId ?? ''}',
      ];
      expect(fingerprint(second), fingerprint(first));
    });
  });
}
