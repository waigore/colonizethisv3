// H7 tribe-survival production peace cases (Refs #2847 § H7).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_peace_targets.dart';
import 'package:colonizethis_test/test.dart';

import 'phase_planner_peace_targets_production_support.dart';

void registerPhasePlannerPeaceTargetsProductionTribeSurvivalCases() {
  group('zeroRegimentSurvivalPeaceTargetsForProduction (Refs #2847 § H7)', () {
    test('EXPAND peaces the OW-owning tribe overrunning a zero-regiment GP', () {
      final game = buildPeaceTargetsTribeCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsTribeCollapseSnapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        ['tribe1'],
      );
    });

    test('does not fire when the GP still holds a standing regiment', () {
      final game = buildPeaceTargetsTribeCollapseGame(ownedOw: 5, regiments: 1);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsTribeCollapseSnapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        isEmpty,
        reason:
            'Regiment-holding / winning Great Powers (gp1/gp2/gp4/gp6) must be '
            'excluded by the zero-regiment survival gate (Refs #2847 § H7).',
      );
    });

    test('does not fire at or above the conquest quota', () {
      final game = buildPeaceTargetsTribeCollapseGame(ownedOw: 10, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsTribeCollapseSnapshotFor(ownedOw: 10),
          phasePlan: outcome,
        ),
        isEmpty,
      );
    });

    test('COLONIAL and DEVELOP carry no survival peace', () {
      final game = buildPeaceTargetsTribeCollapseGame(ownedOw: 5, regiments: 0);
      for (final phase in [
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          zeroRegimentSurvivalPeaceTargetsForProduction(
            game: game,
            snapshot: peaceTargetsTribeCollapseSnapshotFor(ownedOw: 5),
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isEmpty,
        );
      }
    });

    test('productionPeaceTargetsFromPhasePlan unions the survival slot', () {
      final game = buildPeaceTargetsTribeCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        productionPeaceTargetsFromPhasePlan(
          game: game,
          snapshot: peaceTargetsTribeCollapseSnapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        contains('tribe1'),
        reason:
            'The zero-regiment all-faction survival peace must survive in the '
            'production union so a collapsing below-quota GP can peace the '
            'OW-owning tribes overrunning it (Refs #2847 § H7).',
      );
    });

    test('fires at terminal attrition collapse (ownOw == 0)', () {
      final game = buildPeaceTargetsTribeCollapseGame(ownedOw: 0, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: peaceTargetsTribeCollapseSnapshotFor(ownedOw: 0),
          phasePlan: outcome,
        ),
        ['tribe1'],
        reason:
            'Terminal attrition collapse must still peace overrunners when '
            'isStalledOldWorldExpansion is false at ownOw == 0 (Refs #2847 § H8).',
      );
    });
  });
}
