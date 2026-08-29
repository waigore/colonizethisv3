// Shared fixtures for phase_planner_peace_targets production pins (Refs #2847).

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

Game buildPeaceTargetsTribeCollapseGame({
  required int ownedOw,
  required int regiments,
}) {
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

AIWorldSnapshot peaceTargetsTribeCollapseSnapshotFor({required int ownedOw}) =>
    AIWorldSnapshot(
      playerId: 'gp5',
      threats: const ThreatSummary(atWarWith: ['tribe1']),
      opportunities: const OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: ownedOw),
      colonial: const ColonialSummary(),
      economy: const EconomySummary(),
      relations: const {},
    );

Game buildPeaceTargetsGpCollapseGame({
  required int ownedOw,
  required int regiments,
}) {
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
            stationedProvinceId:
                ownedOw > 0 ? 'oldWorld|gp5_0' : 'oldWorld|gp6_0',
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

AIWorldSnapshot peaceTargetsGpCollapseSnapshotFor({required int ownedOw}) =>
    AIWorldSnapshot(
      playerId: 'gp5',
      threats: const ThreatSummary(atWarWith: ['gp6']),
      opportunities: const OpportunitySummary(),
      conquest: ConquestSummary(oldWorldProvincesOwned: ownedOw),
      colonial: const ColonialSummary(),
      economy: const EconomySummary(),
      relations: const {},
    );
