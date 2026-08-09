// Case bodies for `phase_planner_peace_targets_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Unit tests for `phase_planner_peace_targets.dart` (Refs #2509 S5 orchestrator slice).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_peace_targets.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';


void registerPhasePlannerPeaceTargetsProductionCases() {
  group('zeroRegimentSurvivalPeaceTargetsForProduction (Refs #2847 § H7)', () {
    // A below-quota Great Power (gp5) overrun by `tribe1`, which now holds an
    // Old World province stripped from gp5 — so the zero-OW-only distraction
    // slot does NOT peace it; only the zero-regiment survival slot can.
    Game buildCollapseGame({required int ownedOw, required int regiments}) {
      return Game(
        id: 'g-h7-survival-${ownedOw}_$regiments',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < ownedOw; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|tribe1_0',
                regionId: 'oldWorld',
                ownerId: 'tribe1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            if (regiments > 0)
              Army(
                id: 'gp5_army',
                ownerId: 'gp5',
                regionId: 'oldWorld',
                stationedProvinceId: 'oldWorld|gp5_0',
                regimentUnitIds: List<String>.unmodifiable(
                  List<String>.generate(regiments, (i) => 'u_gp5_${i + 1}'),
                ),
                isHomeArmy: true,
              ),
          ],
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
        ],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'tribe1',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
    }

    AIWorldSnapshot snapshotFor({required int ownedOw}) => AIWorldSnapshot(
      playerId: 'gp5',
      threats: const ThreatSummary(atWarWith: ['tribe1']),
      opportunities: const OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: ownedOw),
      colonial: const ColonialSummary(),
      economy: const EconomySummary(),
      relations: const {},
    );

    test('EXPAND peaces the OW-owning tribe overrunning a zero-regiment GP', () {
      final game = buildCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        ['tribe1'],
      );
    });

    test('does not fire when the GP still holds a standing regiment', () {
      final game = buildCollapseGame(ownedOw: 5, regiments: 1);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        isEmpty,
        reason:
            'Regiment-holding / winning Great Powers (gp1/gp2/gp4/gp6) must be '
            'excluded by the zero-regiment survival gate (Refs #2847 § H7).',
      );
    });

    test('does not fire at or above the conquest quota', () {
      final game = buildCollapseGame(ownedOw: 10, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 10),
          phasePlan: outcome,
        ),
        isEmpty,
      );
    });

    test('COLONIAL and DEVELOP carry no survival peace', () {
      final game = buildCollapseGame(ownedOw: 5, regiments: 0);
      for (final phase in [
        ObserverGoalPhase.colonial,
        ObserverGoalPhase.develop,
      ]) {
        expect(
          zeroRegimentSurvivalPeaceTargetsForProduction(
            game: game,
            snapshot: snapshotFor(ownedOw: 5),
            phasePlan: PhasePlanOutcome(phase: phase),
          ),
          isEmpty,
        );
      }
    });

    test('productionPeaceTargetsFromPhasePlan unions the survival slot', () {
      final game = buildCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        productionPeaceTargetsFromPhasePlan(
          game: game,
          snapshot: snapshotFor(ownedOw: 5),
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
      final game = buildCollapseGame(ownedOw: 0, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 0),
          phasePlan: outcome,
        ),
        ['tribe1'],
        reason:
            'Terminal attrition collapse must still peace overrunners when '
            'isStalledOldWorldExpansion is false at ownOw == 0 (Refs #2847 § H8).',
      );
    });
  });

  group('zeroRegimentGpSurvivalPeaceTargetsForProduction (Refs #2847 § H8)', () {
    Game buildGpCollapseGame({required int ownedOw, required int regiments}) {
      return Game(
        id: 'g-h8-gp-survival-${ownedOw}_$regiments',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 60),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < ownedOw; i++)
                Province(
                  id: 'oldWorld|gp5_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp5',
                ),
              const Province(
                id: 'oldWorld|gp6_0',
                regionId: 'oldWorld',
                ownerId: 'gp6',
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            if (regiments > 0)
              Army(
                id: 'gp5_army',
                ownerId: 'gp5',
                regionId: 'oldWorld',
                stationedProvinceId: ownedOw > 0 ? 'oldWorld|gp5_0' : 'oldWorld|gp6_0',
                regimentUnitIds: List<String>.unmodifiable(
                  List<String>.generate(regiments, (i) => 'u_gp5_${i + 1}'),
                ),
                isHomeArmy: true,
              ),
          ],
        ),
        players: const [
          Player(id: 'gp5', displayName: 'P5', isHuman: false),
          Player(id: 'gp6', displayName: 'P6', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp5',
            factionId2: 'gp6',
            state: RelationState.atWar,
            score: 30,
          ),
        ],
      );
    }

    AIWorldSnapshot snapshotFor({required int ownedOw}) => AIWorldSnapshot(
      playerId: 'gp5',
      threats: const ThreatSummary(atWarWith: ['gp6']),
      opportunities: const OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: ownedOw),
      colonial: const ColonialSummary(),
      economy: const EconomySummary(),
      relations: const {},
    );

    test('EXPAND peaces the at-war GP peer when zero regiments', () {
      final game = buildGpCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentGpSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        ['gp6'],
      );
    });

    test('does not fire when the GP still holds a standing regiment', () {
      final game = buildGpCollapseGame(ownedOw: 5, regiments: 1);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentGpSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 5),
          phasePlan: outcome,
        ),
        isEmpty,
      );
    });

    test('fires at terminal attrition collapse (ownOw == 0)', () {
      final game = buildGpCollapseGame(ownedOw: 0, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        zeroRegimentGpSurvivalPeaceTargetsForProduction(
          game: game,
          snapshot: snapshotFor(ownedOw: 0),
          phasePlan: outcome,
        ),
        ['gp6'],
      );
    });

    test('productionPeaceTargetsFromPhasePlan unions the GP survival slot', () {
      final game = buildGpCollapseGame(ownedOw: 5, regiments: 0);
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.expand);
      expect(
        productionPeaceTargetsFromPhasePlan(
          game: game,
          snapshot: snapshotFor(ownedOw: 5),
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
