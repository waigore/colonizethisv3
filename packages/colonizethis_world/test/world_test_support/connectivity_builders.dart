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

/// Orders-phase [Game] for connectivity / blockade scenario pins (Refs #3968).
Game ordersPhaseGame({
  String id = 'g1',
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Fleet> fleets = const [],
  List<Player> players = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  TileMapState? tileState,
  Map<String, String> portsByProvinceSeaboard = const {},
  int turnNumber = 1,
}) {
  return Game(
    id: id,
    worldState: ordersPhaseWorldState(
      turnNumber: turnNumber,
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      fleets: fleets,
      tileState: tileState,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
    diplomacyRelations: diplomacyRelations,
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
