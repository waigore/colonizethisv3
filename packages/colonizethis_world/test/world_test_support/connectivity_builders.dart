import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'topology_builders.dart';

/// Orders-phase [WorldState] with optional region payloads.
WorldState ordersPhaseWorldState({
  int turnNumber = 1,
  RegionData? oldWorld,
  RegionData? newWorld,
  TileMapState? tileState,
  Map<String, String>? portsByProvinceSeaboard,
  List<Fleet>? fleets,
}) {
  return WorldState(
    turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
    oldWorld: oldWorld ?? const RegionData(),
    newWorld: newWorld ?? const RegionData(),
    tileState: tileState ?? const TileMapState(),
    portsByProvinceSeaboard: portsByProvinceSeaboard ?? const {},
    fleets: fleets ?? const [],
  );
}

/// Dual-region GP game with linked sea ports (blockade/connectivity scenarios).
({
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
}) dualRegionPortConnectivityScenario({
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
  final game = Game(
    id: 'g1',
    worldState: ordersPhaseWorldState(
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|$owProvinceId', regionId: ow, ownerId: playerId),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: '$nw|$nwProvinceId', regionId: nw, ownerId: playerId),
        ],
      ),
      tileState: tileState,
      portsByProvinceSeaboard: ports,
    ),
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
