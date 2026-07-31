// Fixtures for naval mission dialog widget goldens (Refs #4213).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'naval_units_panel_test_scenarios.dart';
import 'panel_test_fixtures.dart';

const navalMissionGoldenHumanId = 'gp_mission_golden';
const navalMissionGoldenEnemyId = 'gp_enemy';
const navalMissionGoldenSeaZone = 'sea1';

const Size kNavalMissionGoldenViewport = Size(360, 520);

Game buildNavalMissionMenuPeacetimeGame() =>
    buildNavalPanelNamedSeaZoneGame(humanId: navalMissionGoldenHumanId);

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
      Player(id: navalMissionGoldenEnemyId, displayName: 'Spain', isHuman: false),
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

Game buildNavalMissionFleetPickerGame() {
  const capProvince = 'oldWorld|cap1';
  return buildNavalPanelOwFleetsGame(
    gameId: 'naval-mission-picker-golden',
    humanId: navalMissionGoldenHumanId,
    displayName: 'Fleet Picker Tester',
    capitalProvinceId: capProvince,
    oldWorldProvinces: [
      Province(
        id: capProvince,
        regionId: 'oldWorld',
        ownerId: navalMissionGoldenHumanId,
        displayName: 'Capital',
      ),
    ],
    fleets: [
      Fleet(
        id: 'fleet_alpha',
        ownerId: navalMissionGoldenHumanId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        ships: const [ShipInstance(id: 'a1', typeId: 'carrack')],
      ),
      Fleet(
        id: 'fleet_beta',
        ownerId: navalMissionGoldenHumanId,
        regionId: 'oldWorld',
        seaZoneId: navalMissionGoldenSeaZone,
        ships: const [ShipInstance(id: 'b1', typeId: 'galleon')],
      ),
    ],
  );
}
