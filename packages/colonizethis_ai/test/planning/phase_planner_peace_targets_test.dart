// Unit tests for `phase_planner_peace_targets.dart` (Refs #2509 S5 orchestrator slice).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_dispatch.dart';
import 'package:colonizethis_ai/src/planning/phase_planner_peace_targets.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('gpPeaceTargetsFromPhasePlan', () {
    test('EXPAND routes expandPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandPeaceTargetFactionIdsSorted: ['gp2', 'gp3'],
      );
      expect(
        gpPeaceTargetsFromPhasePlan(outcome),
        ['gp2', 'gp3'],
      );
    });

    test('COLONIAL-lite routes expand peace slots', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandPeaceTargetFactionIdsSorted: ['gp4'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp4']);
    });

    test('COLONIAL routes colonialPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialPeaceTargetFactionIdsSorted: ['gp5'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp5']);
    });

    test('DEVELOP routes developPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        developPeaceTargetFactionIdsSorted: ['gp1', 'gp6'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp1', 'gp6']);
    });

    test('default-plan slots yield empty lists', () {
      expect(
        gpPeaceTargetsFromPhasePlan(PhasePlanOutcome.defaultColonial),
        isEmpty,
      );
    });
  });

  group('gpPeaceTargetsFromPhasePlan determinism', () {
    test('identical outcomes yield identical lists', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        colonialPeaceTargetFactionIdsSorted: ['gp2'],
      );
      expect(
        gpPeaceTargetsFromPhasePlan(outcome),
        gpPeaceTargetsFromPhasePlan(outcome),
      );
    });
  });

  group('distractionPeaceTargetsFromPhasePlan (Refs #2847 § H5)', () {
    test('EXPAND routes expandDistractionPeaceTargetFactionIdsSorted', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandDistractionPeaceTargetFactionIdsSorted: ['minor_b', 'tribe_a'],
      );
      expect(
        distractionPeaceTargetsFromPhasePlan(outcome),
        ['minor_b', 'tribe_a'],
      );
    });

    test('COLONIAL-lite routes the expand distraction slot', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonialLite,
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_z'],
      );
      expect(distractionPeaceTargetsFromPhasePlan(outcome), ['tribe_z']);
    });

    test('COLONIAL and DEVELOP carry no distraction peace', () {
      const colonial = PhasePlanOutcome(
        phase: ObserverGoalPhase.colonial,
        // Distraction slot is EXPAND-only; even if populated it is ignored
        // outside EXPAND / COLONIAL-lite.
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_a'],
      );
      const develop = PhasePlanOutcome(
        phase: ObserverGoalPhase.develop,
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_a'],
      );
      expect(distractionPeaceTargetsFromPhasePlan(colonial), isEmpty);
      expect(distractionPeaceTargetsFromPhasePlan(develop), isEmpty);
    });

    test('default EXPAND outcome yields an empty distraction list', () {
      expect(
        distractionPeaceTargetsFromPhasePlan(PhasePlanOutcome.defaultExpand),
        isEmpty,
      );
    });

    test('GP peace and distraction peace are carried on separate slots', () {
      const outcome = PhasePlanOutcome(
        phase: ObserverGoalPhase.expand,
        expandPeaceTargetFactionIdsSorted: ['gp3'],
        expandDistractionPeaceTargetFactionIdsSorted: ['tribe_a'],
      );
      expect(gpPeaceTargetsFromPhasePlan(outcome), ['gp3']);
      expect(distractionPeaceTargetsFromPhasePlan(outcome), ['tribe_a']);
    });
  });

  group('productionPeaceTargetsFromPhasePlan (Refs #2847 § H6)', () {
    test(
      'unions collectStalled ratchet peace absent from the GP-only adapter',
      () {
        final game = Game(
          id: 'g-h6-peer-peace',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
            oldWorld: RegionData(
              provinces: [
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp5_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp5',
                  ),
                for (var i = 0; i < 8; i++)
                  Province(
                    id: 'oldWorld|gp6_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp6',
                  ),
                const Province(
                  id: 'oldWorld|gp6_frontier',
                  regionId: 'oldWorld',
                  ownerId: 'gp6',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp5', displayName: 'P5', isHuman: false),
            Player(id: 'gp6', displayName: 'P6', isHuman: false),
          ],
          diplomacyRelations: [
            const DiplomacyRelation(
              factionId1: 'gp5',
              factionId2: 'gp6',
              state: RelationState.atWar,
              score: 30,
            ),
          ],
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        final phasePlanPeace = planExpandPeace(game: game, snapshot: snapshot);
        final outcome = PhasePlanOutcome(
          phase: ObserverGoalPhase.expand,
          expandPeaceTargetFactionIdsSorted: phasePlanPeace,
        );
        expect(
          productionPeaceTargetsFromPhasePlan(
            game: game,
            snapshot: snapshot,
            phasePlan: outcome,
          ),
          contains('gp6'),
          reason:
              'belowQuotaPeerGpPeaceTargets must survive in production via the '
              'collectStalled union (seed-42 gp5↔gp6 attrition escape; Refs #2847 '
              '§ H6).',
        );
      },
    );

    test('COLONIAL phase carries no below-quota peer supplemental peace', () {
      final game = Game(
        id: 'g-h6-colonial',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: false),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp1',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      const outcome = PhasePlanOutcome(phase: ObserverGoalPhase.colonial);
      expect(
        belowQuotaPeerGpPeaceTargetsForProduction(
          game: game,
          snapshot: snapshot,
          phasePlan: outcome,
        ),
        isEmpty,
      );
    });
  });

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
