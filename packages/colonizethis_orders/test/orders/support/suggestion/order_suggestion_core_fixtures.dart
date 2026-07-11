// Shared fixtures for order_suggestion_core scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Canonical ids for order_suggestion_core expectation bodies.
abstract final class OscIds {
  static const playerId = 'gp1';
  static const ow = 'oldWorld';

  static String prov(String local) => '$ow|$local';
  static String tile(String local, int x, int y) => '$ow|$local|$x|$y';
}

Player oscPlayer({
  String id = OscIds.playerId,
  String displayName = 'GP',
  bool isHuman = false,
  int treasury = 0,
  Stockpile? stockpile,
  WorkerPool? workerPool,
  String? capitalProvinceId,
}) {
  return Player(
    id: id,
    displayName: displayName,
    isHuman: isHuman,
    treasury: treasury,
    stockpile: stockpile ?? const Stockpile(),
    workerPool: workerPool ?? const WorkerPool(),
    capitalProvinceId: capitalProvinceId,
  );
}

Province oscProvince(String local, {String? ownerId}) {
  return Province(
    id: OscIds.prov(local),
    regionId: OscIds.ow,
    ownerId: ownerId,
  );
}

Unit oscExplorer({
  String id = 'u1',
  String provinceLocal = 'p1',
  String? tileKey,
}) {
  return Unit(
    id: id,
    type: kUnitTypeExplorer,
    ownerId: OscIds.playerId,
    locationProvinceId: OscIds.prov(provinceLocal),
    tileKey: tileKey,
  );
}

Unit oscBuilder({
  String id = 'u1',
  String provinceLocal = 'p1',
  String? tileKey,
}) {
  return Unit(
    id: id,
    type: kUnitTypeBuilder,
    ownerId: OscIds.playerId,
    locationProvinceId: OscIds.prov(provinceLocal),
    tileKey: tileKey,
  );
}

Stockpile oscLumberCastIronStockpile({int amount = 10}) {
  return Stockpile(quantities: {'lumber': amount, 'castIron': amount});
}

Player oscBuilderPlayer({int lumberCastIron = 10, int treasury = 500}) {
  return oscPlayer(
    stockpile: oscLumberCastIronStockpile(amount: lumberCastIron),
    treasury: treasury,
  );
}

MapTopology oscProvinceTopology(
  List<String> locals, {
  List<TopologyEdge> edges = const [],
}) {
  return MapTopology(
    nodes: [
      for (final local in locals)
        TopologyNode(
          id: local,
          regionId: OscIds.ow,
          type: TopologyNodeType.province,
        ),
    ],
    edges: edges,
  );
}

MapTopology oscTwoProvincesConnected(String a, String b) {
  return oscProvinceTopology(
    [a, b],
    edges: [TopologyEdge(id1: a, id2: b)],
  );
}

MapTopology oscEmptyTopology() => const MapTopology(nodes: [], edges: []);

WorldState oscWorld({
  RegionData? oldWorld,
  RegionData newWorld = const RegionData(),
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, String>? resourceByTileKey,
  TileMapState? tileState,
  List<Fleet>? fleets,
}) {
  return WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: oldWorld ?? const RegionData(),
    newWorld: newWorld,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince ?? const {},
    playerVisibilityByTile: playerVisibilityByTile ?? const {},
    resourceByTileKey: resourceByTileKey ?? const {},
    tileState: tileState ?? const TileMapState(),
    fleets: fleets ?? const [],
  );
}

Game oscGame({
  required WorldState worldState,
  List<Player>? players,
  List<Tribe>? tribes,
  List<MinorNation>? minorNations,
  List<OvertureState>? overtureStates,
  String id = 'g1',
}) => TestFixtures.minimalGame(
  id: id,
  turnNumber: worldState.turnState.turnNumber,
  players: players ?? [oscPlayer()],
  oldWorld: worldState.oldWorld,
  newWorld: worldState.newWorld,
  tribes: tribes ?? const [],
  minorNations: minorNations ?? const [],
  overtureStates: overtureStates ?? const [],
  playerVisibilityByTile: worldState.playerVisibilityByTile,
  tileKeysByRegionAndProvince: worldState.tileKeysByRegionAndProvince,
  resourceByTileKey: worldState.resourceByTileKey,
  purchasedTilesByTileKey: worldState.purchasedTilesByTileKey,
  portsByProvinceSeaboard: worldState.portsByProvinceSeaboard,
  playerProspectedTiles: worldState.playerProspectedTiles,
  tileState: worldState.tileState,
  fleets: worldState.fleets,
);

PlayerView oscView(Game game, MapTopology topology) {
  return buildPlayerView(game, topology, OscIds.playerId);
}

Map<String, Map<String, List<String>>> oscTilesByProvince(
  Map<String, List<String>> byLocal,
) {
  return {
    OscIds.ow: {for (final e in byLocal.entries) OscIds.prov(e.key): e.value},
  };
}

Map<String, Map<String, String>> oscVisibility(Map<String, String> byTile) {
  return {OscIds.playerId: byTile};
}

/// Two builders on p1 with grain tiles A/B — shared by reservation scenarios.
class OscDualBuilderGrainTiles {
  OscDualBuilderGrainTiles()
    : tileA = OscIds.tile('p1', 0, 0),
      tileB = OscIds.tile('p1', 1, 0),
      p1 = oscProvince('p1', ownerId: OscIds.playerId),
      player = oscBuilderPlayer(lumberCastIron: 20);

  final String tileA;
  final String tileB;
  final Province p1;
  final Player player;

  WorldState world() {
    return oscWorld(
      oldWorld: RegionData(
        provinces: [p1],
        units: [
          oscBuilder(id: 'b1', provinceLocal: 'p1', tileKey: tileA),
          oscBuilder(id: 'b2', provinceLocal: 'p1', tileKey: tileA),
        ],
      ),
      playerVisibilityByTile: oscVisibility({
        tileA: 'fullyVisible',
        tileB: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [tileA, tileB],
      }),
      resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
      tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
    );
  }

  Game game() => oscGame(worldState: world(), players: [player]);

  MapTopology topology() => oscProvinceTopology(['p1']);

  Orders ordersReservingTileA() {
    return Orders(
      workOrdersByPlayerId: {
        OscIds.playerId: [
          WorkOrder(
            unitId: 'b1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileA,
          ),
        ],
      },
    );
  }
}

Game oscCapitalProvinceGame(Player player, {String provinceLocal = 'p1'}) {
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince(provinceLocal, ownerId: OscIds.playerId)],
        units: const [],
      ),
    ),
    players: [player],
  );
}

MapTopology oscCapitalTopology({String provinceLocal = 'p1'}) {
  return oscProvinceTopology([provinceLocal]);
}

Fleet oscFleetAtSea(String seaZoneId) {
  return Fleet(
    id: 'fleet_gp1',
    ownerId: OscIds.playerId,
    seaZoneId: seaZoneId,
    regionId: OscIds.ow,
    shipTypeIds: const ['fluyte'],
  );
}

MapTopology oscSeaTopology(List<String> seaZones, {List<TopologyEdge>? edges}) {
  return MapTopology(
    nodes: [
      for (final id in seaZones)
        TopologyNode(
          id: id,
          regionId: OscIds.ow,
          type: TopologyNodeType.seaZone,
        ),
    ],
    edges: edges ?? const [],
  );
}

/// Partial + fully known tribe provinces for explore cache-scope scenarios.
Game oscPartialRevealExploreCacheGame() {
  final partialProvince = OscIds.prov('p_partial');
  final fullyKnownProvince = OscIds.prov('p_known');
  final partialKnownTile = OscIds.tile('p_partial', 0, 0);
  final partialUnknownTile = OscIds.tile('p_partial', 1, 0);
  final knownTile = OscIds.tile('p_known', 0, 0);
  return oscGame(
    id: 'g-cache-scope',
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p_partial', ownerId: 'tribe1'),
          oscProvince('p_known', ownerId: 'tribe1'),
        ],
        units: [
          oscExplorer(provinceLocal: 'p_partial', tileKey: partialKnownTile),
        ],
      ),
      playerVisibilityByTile: oscVisibility({
        partialKnownTile: 'fogged',
        partialUnknownTile: 'unknown',
        knownTile: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: {
        OscIds.ow: {
          partialProvince: [partialKnownTile, partialUnknownTile],
          fullyKnownProvince: [knownTile],
        },
      },
    ),
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    overtureStates: const [
      OvertureState(
        gpId: OscIds.playerId,
        targetId: 'tribe1',
        stage: OvertureStage.tradeConsulate,
      ),
    ],
  );
}
