import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'connectivity_builders.dart';
import 'topology_builders.dart';

/// Dual-region GP game with linked sea ports (blockade/connectivity scenarios).
({Game game, MapTopology topology, Map<String, TileMapResult> tileMapByRegion})
dualRegionPortConnectivityScenario({
  String playerId = 'pl1',
  String owProvinceId = 'p1',
  String nwProvinceId = 'p2',
  String owSeaId = 'sea1',
  String nwSeaId = 'sea2',
  int gridSize = 2,
}) {
  const ow = kWorldTestOw;
  const nw = kWorldTestNw;
  final topology = dualRegionLinkedSeaTopology(
    owProvinceId: owProvinceId,
    nwProvinceId: nwProvinceId,
    owSeaId: owSeaId,
    nwSeaId: nwSeaId,
  );
  final tileMapByRegion = dualRegionUniformTileMaps(
    owProvinceId: owProvinceId,
    nwProvinceId: nwProvinceId,
    size: gridSize,
  );
  final cap = CapitalTile(
    regionId: ow,
    provinceId: '$ow|$owProvinceId',
    x: 0,
    y: 0,
  );
  final tileState = TileMapState()
      .setRoadLevel('$ow|$owProvinceId|0|0', 4)
      .setRoadLevel('$nw|$nwProvinceId|0|0', 4);
  final ports = {
    '$ow|$owProvinceId|$owSeaId': '$ow|$owProvinceId|0|0',
    '$nw|$nwProvinceId|$nwSeaId': '$nw|$nwProvinceId|0|0',
  };
  final game = ordersPhaseGame(
    oldWorldProvinces: [
      Province(id: '$ow|$owProvinceId', regionId: ow, ownerId: playerId),
    ],
    newWorldProvinces: [
      Province(id: '$nw|$nwProvinceId', regionId: nw, ownerId: playerId),
    ],
    tileState: tileState,
    portsByProvinceSeaboard: ports,
    players: [
      Player(
        id: playerId,
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|$owProvinceId',
        capitalTile: cap,
      ),
    ],
  );
  return (game: game, topology: topology, tileMapByRegion: tileMapByRegion);
}

/// Spain vs France at-war diplomacy row for blockade scenario pins.
const List<DiplomacyRelation> spainFranceAtWarDiplomacy = [
  DiplomacyRelation(
    factionId1: 'pl1',
    factionId2: 'p2',
    state: RelationState.atWar,
  ),
];

/// [dualRegionPortConnectivityScenario] plus enemy blockade fleet and at-war diplomacy.
({Game game, MapTopology topology, Map<String, TileMapResult> tileMapByRegion})
dualRegionPortBlockadeAutoApplyScenario({
  String attackerId = 'p2',
  String attackerSeaZoneId = 'sea2',
  String blockadedNwProvinceId = 'p2',
}) {
  final base = dualRegionPortConnectivityScenario();
  const nw = kWorldTestNw;
  final game = base.game.copyWith(
    worldState: base.game.worldState.copyWith(
      fleets: [
        blockadeFleet(
          fleetId: 'fleet_$attackerId',
          ownerId: attackerId,
          regionId: nw,
          seaZoneId: attackerSeaZoneId,
          targetProvinceId: '$nw|$blockadedNwProvinceId',
        ),
      ],
    ),
    players: [
      ...base.game.players,
      Player(id: attackerId, displayName: 'France', isHuman: true),
    ],
    diplomacyRelations: spainFranceAtWarDiplomacy,
  );
  return (
    game: game,
    topology: base.topology,
    tileMapByRegion: base.tileMapByRegion,
  );
}

/// Two OW ports linked by seas; capital on [owCapitalProvinceId].
({Game game, MapTopology topology, Map<String, TileMapResult> tileMapByRegion})
twoPortOldWorldBlockadeConnectivityScenario({
  String playerId = 'pl1',
  String owCapitalProvinceId = 'p1',
  String owBlockadedProvinceId = 'p2',
  String owSea1Id = 'sea1',
  String owSea2Id = 'sea2',
}) {
  const ow = kWorldTestOw;
  final topology = topologyFromGraph(
    nodes: [
      TopologyNode(
        id: owCapitalProvinceId,
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: owBlockadedProvinceId,
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(id: owSea1Id, regionId: ow, type: TopologyNodeType.seaZone),
      TopologyNode(id: owSea2Id, regionId: ow, type: TopologyNodeType.seaZone),
    ],
    edges: [
      TopologyEdge(id1: owCapitalProvinceId, id2: owSea1Id),
      TopologyEdge(id1: owBlockadedProvinceId, id2: owSea2Id),
      TopologyEdge(id1: owSea1Id, id2: owSea2Id),
    ],
  );
  final grid = [
    [
      owCapitalProvinceId,
      owCapitalProvinceId,
      owBlockadedProvinceId,
      owBlockadedProvinceId,
    ],
    [
      owCapitalProvinceId,
      owCapitalProvinceId,
      owBlockadedProvinceId,
      owBlockadedProvinceId,
    ],
  ];
  final cap = CapitalTile(
    regionId: ow,
    provinceId: '$ow|$owCapitalProvinceId',
    x: 0,
    y: 0,
  );
  final tileState = TileMapState()
      .setRoadLevel('$ow|$owCapitalProvinceId|0|0', 4)
      .setRoadLevel('$ow|$owCapitalProvinceId|1|0', 4)
      .setRoadLevel('$ow|$owBlockadedProvinceId|2|0', 4)
      .setRoadLevel('$ow|$owBlockadedProvinceId|3|0', 4);
  final game = ordersPhaseGame(
    oldWorldProvinces: [
      Province(id: '$ow|$owCapitalProvinceId', regionId: ow, ownerId: playerId),
      Province(
        id: '$ow|$owBlockadedProvinceId',
        regionId: ow,
        ownerId: playerId,
      ),
    ],
    tileState: tileState,
    portsByProvinceSeaboard: {
      '$ow|$owCapitalProvinceId|$owSea1Id': '$ow|$owCapitalProvinceId|0|0',
      '$ow|$owBlockadedProvinceId|$owSea2Id': '$ow|$owBlockadedProvinceId|2|0',
    },
    players: [
      Player(
        id: playerId,
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|$owCapitalProvinceId',
        capitalTile: cap,
      ),
    ],
  );
  return (
    game: game,
    topology: topology,
    tileMapByRegion: {ow: tileMapFromGrid(grid)},
  );
}

/// Blockade fleet targeting a province in [regionId].
Fleet blockadeFleet({
  required String fleetId,
  required String ownerId,
  required String regionId,
  required String seaZoneId,
  required String targetProvinceId,
}) {
  return Fleet(
    id: fleetId,
    ownerId: ownerId,
    seaZoneId: seaZoneId,
    inPortAtProvinceId: null,
    regionId: regionId,
    mission: FleetMission.blockade,
    targetProvinceId: targetProvinceId,
  );
}
