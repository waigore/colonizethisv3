// War/blockade fixtures for naval mission dialog widget goldens (Refs #4213).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_mission_goldens_constants.dart';
import 'panel_test_fixtures.dart';

Game buildNavalMissionWarTargetsGame() {
  const capProvince = 'oldWorld|cap1';
  const enemyProvince = 'oldWorld|enemy1';
  const enemyProvince2 = 'oldWorld|enemy2';
  return buildPanelTestGame(
    id: 'naval-mission-war-golden',
    players: const [
      Player(
        id: navalMissionGoldenHumanId,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: capProvince,
        capitalTile: CapitalTile(
          regionId: 'oldWorld',
          provinceId: capProvince,
          x: 0,
          y: 0,
        ),
      ),
      Player(
        id: navalMissionGoldenEnemyId,
        displayName: 'Spain',
        isHuman: false,
      ),
    ],
    oldWorldProvinces: const [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenHumanId,
        displayName: 'Capital',
      ),
      Province(
        id: enemyProvince,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenEnemyId,
        displayName: 'Enemy Port',
      ),
      Province(
        id: enemyProvince2,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenEnemyId,
        displayName: 'Hostile Coast',
      ),
    ],
    fleets: [
      Fleet(
        id: 'fleet_at_sea',
        ownerId: navalMissionGoldenHumanId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: navalMissionGoldenHumanId,
        factionId2: navalMissionGoldenEnemyId,
        state: RelationState.atWar,
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|cap1|$navalMissionGoldenSeaZone': 'oldWorld|cap1|0|0',
      'oldWorld|enemy1|$navalMissionGoldenSeaZone': 'oldWorld|enemy1|0|0',
      'oldWorld|enemy2|$navalMissionGoldenSeaZone': 'oldWorld|enemy2|0|0',
    },
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        capProvince: ['oldWorld|cap1|0|0'],
        enemyProvince: ['oldWorld|enemy1|0|0'],
        enemyProvince2: ['oldWorld|enemy2|0|0'],
      },
    },
  );
}

MapTopology navalMissionWarTopology() {
  const regionId = 'oldWorld';
  return MapTopology(
    nodes: [
      TopologyNode(
        id: navalMissionGoldenSeaZone,
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'cap1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'enemy1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'enemy2',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [
      TopologyEdge(id1: navalMissionGoldenSeaZone, id2: 'cap1'),
      TopologyEdge(id1: navalMissionGoldenSeaZone, id2: 'enemy1'),
      TopologyEdge(id1: navalMissionGoldenSeaZone, id2: 'enemy2'),
    ],
  );
}

/// Human-owned coastal province under enemy Blockade (Refs #4516).
Game buildNavalMissionHumanOwnedBlockadedPortGame({bool capitalPort = false}) {
  const target = 'oldWorld|enemy1';
  return buildPanelTestGame(
    id: capitalPort ? 'blockade-status-owned-capital' : 'blockade-status-owned',
    players: [
      Player(
        id: navalMissionGoldenHumanId,
        displayName: 'England',
        isHuman: true,
        capitalProvinceId: capitalPort ? target : 'oldWorld|cap1',
      ),
      const Player(
        id: navalMissionGoldenEnemyId,
        displayName: 'Spain',
        isHuman: false,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: target,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenHumanId,
        displayName: capitalPort ? 'My Capital Port' : 'My Port',
      ),
    ],
    fleets: [
      Fleet(
        id: 'blockader',
        ownerId: navalMissionGoldenEnemyId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        mission: FleetMission.blockade,
        targetProvinceId: target,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: navalMissionGoldenHumanId,
        factionId2: navalMissionGoldenEnemyId,
        state: RelationState.atWar,
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|enemy1|$navalMissionGoldenSeaZone': 'oldWorld|enemy1|0|0',
    },
  );
}

/// Blockade target picker where the listed enemy port is that owner's capital.
Game buildNavalMissionCapitalPortTargetGame() {
  const enemyCap = 'oldWorld|enemy1';
  return buildPanelTestGame(
    id: 'blockade-capital-extra-golden',
    players: const [
      Player(
        id: navalMissionGoldenHumanId,
        displayName: 'England',
        isHuman: true,
      ),
      Player(
        id: navalMissionGoldenEnemyId,
        displayName: 'Spain',
        isHuman: false,
        capitalProvinceId: enemyCap,
      ),
    ],
    oldWorldProvinces: const [
      Province(
        id: enemyCap,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenEnemyId,
        displayName: 'Enemy Capital Port',
      ),
    ],
    fleets: [
      Fleet(
        id: 'fleet_at_sea',
        ownerId: navalMissionGoldenHumanId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: navalMissionGoldenHumanId,
        factionId2: navalMissionGoldenEnemyId,
        state: RelationState.atWar,
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|enemy1|$navalMissionGoldenSeaZone': 'oldWorld|enemy1|0|0',
    },
  );
}
