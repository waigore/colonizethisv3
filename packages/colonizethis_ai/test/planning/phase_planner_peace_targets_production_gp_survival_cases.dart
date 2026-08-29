// H8 GP-survival production peace cases (Refs #2847 § H8).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_peace_targets.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_peace_targets_production_support.dart';

void registerPhasePlannerPeaceTargetsProductionGpSurvivalCases() {
  group('zeroRegimentGpSurvivalPeaceTargetsForProduction (Refs #2847 § H8)', () {
    test('EXPAND peaces the at-war GP peer when zero regiments', () {
      final game = buildPeaceTargetsGpCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentGpSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsGpCollapseSnapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        ['gp6'],
      );
    });

    test('does not fire when the GP still holds a standing regiment', () {
      final game = buildPeaceTargetsGpCollapseGame(ownedOw: 5, regiments: 1);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentGpSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsGpCollapseSnapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        isEmpty,
      );
    });

    test('fires at terminal attrition collapse (ownOw == 0)', () {
      final game = buildPeaceTargetsGpCollapseGame(ownedOw: 0, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentGpSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsGpCollapseSnapshotFor(ownedOw: 0),
          phasePlan: outcome,
        ),
        ['gp6'],
      );
    });

    test('productionPeaceTargetsFromPhasePlan unions the GP survival slot', () {
      final game = buildPeaceTargetsGpCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        productionPeaceTargetsFromPhasePlan(
          game: game,
          snapshot: peaceTargetsGpCollapseSnapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        contains('gp6'),
        reason:
            'The zero-regiment GP survival peace must survive in the '
            'production union so gp5 can peace gp6 during attrition collapse '
            '(Refs #2847 § H8).',
      );
    });
  });
}
