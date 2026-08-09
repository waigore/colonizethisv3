// Connectivity dev snapshot, parity, and determinism fixtures (Refs #4246 Slice E+).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_snapshot.dart';
import 'package:colonizethis_orders/src/orders/connectivity_dev_targets.dart';
import 'package:colonizethis_orders/src/orders/development_panel_assign.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_work.dart';
import 'package:colonizethis_orders/src/orders/order_work_constants.dart';
import 'package:colonizethis_orders/src/orders/work_suggestion_pipeline.dart';
import 'package:colonizethis_test/test.dart';

import '../common/game_graphs.dart';
import 'connectivity_dev_targets_fixtures.dart';
import 'order_suggestion_work_feedstock_priority_fixtures.dart';

TileMapResult tileMapFromProvinceTileKeys(Map<String, List<String>> provinces) {
  var maxX = 0;
  var maxY = 0;
  for (final tiles in provinces.values) {
    for (final tileKey in tiles) {
      final coords = parseTileKeyCoordinates(tileKey);
      if (coords == null) continue;
      if (coords.x > maxX) maxX = coords.x;
      if (coords.y > maxY) maxY = coords.y;
    }
  }
  final w = maxX + 1;
  final h = maxY + 1;
  final grid = List.generate(h, (_) => List.filled(w, provinces.keys.first));
  for (final provinceEntry in provinces.entries) {
    for (final tileKey in provinceEntry.value) {
      final coords = parseTileKeyCoordinates(tileKey);
      if (coords == null) continue;
      grid[coords.y][coords.x] = provinceEntry.key;
    }
  }
  return TileMapResult(width: w, height: h, grid: grid);
}

Map<String, TileMapResult> tileMapByRegionFromGame(Game game) => {
  for (final e in game.worldState.tileKeysByRegionAndProvince.entries)
    e.key: tileMapFromProvinceTileKeys(e.value),
};

/// AC-A5: foreign-province barrier blocks owned-land extension toward resource.
({
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
  String capTile,
})
connectivityDevForeignBarrierCase() {
  const ow = connectivityDevOw;
  const pCapital = '$ow|pCap';
  const pForeign = '$ow|pFor';
  const pResource = '$ow|pRes';
  const capTile = '$pCapital|2|0';
  const resourceTile = '$pResource|0|2';
  final grid = [
    ['pCap', 'pCap', 'pCap'],
    ['pFor', 'pFor', 'pFor'],
    ['pRes', 'pRes', 'pRes'],
  ];
  final tileMap = TileMapResult(
    width: grid.first.length,
    height: grid.length,
    grid: grid,
  );
  final topology = MapTopology(
    nodes: [
      TopologyNode(id: pCapital, regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: pForeign, regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: pResource, regionId: ow, type: TopologyNodeType.province),
    ],
    edges: [
      TopologyEdge(id1: pCapital, id2: pForeign),
      TopologyEdge(id1: pForeign, id2: pResource),
    ],
  );
  final capTiles = [for (var x = 0; x < 3; x++) '$pCapital|$x|0'];
  final resTiles = [for (var x = 0; x < 3; x++) '$pResource|$x|2'];
  final game = ordersOwRegionGame(
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP',
        isHuman: false,
        capitalProvinceId: pCapital,
        capitalTile: CapitalTile(regionId: ow, provinceId: pCapital, x: 2, y: 0),
      ),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(id: pCapital, regionId: ow, ownerId: 'gp1'),
        Province(id: pForeign, regionId: ow, ownerId: 'minor1'),
        Province(id: pResource, regionId: ow, ownerId: 'gp1'),
      ],
    ),
    tileKeysByRegionAndProvince: {ow: {'pCap': capTiles, 'pRes': resTiles}},
    resourceByTileKey: {resourceTile: 'iron'},
    tileState: const TileMapState(improvementByTile: {resourceTile: 1}),
  );
  return (
    game: game,
    topology: topology,
    tileMapByRegion: {ow: tileMap},
    capTile: capTile,
  );
}

/// AC-A7: frontier tile wins lex-smaller non-frontier under road probe cap.
({ConnectivityDevSnapshot snapshot, String frontierTile, List<String> lexSorted})
connectivityDevFrontierRoadLexCase() {
  const frontierTile = 'oldWorld|p1|2|4';
  final lexSorted = <String>[
    for (var y = 0; y < 5; y++)
      for (var x = 0; x < 5; x++) 'oldWorld|p1|$x|$y',
  ];
  final snapshot = ConnectivityDevSnapshot(
    connected: {'oldWorld|p1|4|4', 'oldWorld|p1|3|4', 'oldWorld|p1|4|3'},
    pathTransportCap: const {},
    extensionDistanceByTile: {
      frontierTile: 6,
      'oldWorld|p1|3|3': 6,
      'oldWorld|p1|4|2': 6,
    },
    seaZonesReachableFromCapital: const {},
    provincesWithUnconnectedDevTargets: {'oldWorld|p1'},
    hasUnconnectedDevTargets: true,
    frontierExtensionTiles: {frontierTile, 'oldWorld|p1|3|3', 'oldWorld|p1|4|2'},
    bottleneckRailTiles: const {},
    adjacentToConnectedTiles: {
      frontierTile,
      'oldWorld|p1|3|3',
      'oldWorld|p1|4|2',
    },
  );
  return (snapshot: snapshot, frontierTile: frontierTile, lexSorted: lexSorted);
}

/// AC-F7: town-connected resource tile is not a frontier extension target.
({ConnectivityDevSnapshot snapshot, String townResourceTile, String frontierTile})
connectivityDevTownRuleFrontierCase() {
  const townResourceTile = 'oldWorld|p1|2|2';
  const frontierTile = 'oldWorld|p1|3|2';
  final snapshot = ConnectivityDevSnapshot(
    connected: {townResourceTile, 'oldWorld|p1|0|0'},
    pathTransportCap: const {},
    extensionDistanceByTile: const {frontierTile: 1},
    seaZonesReachableFromCapital: const {},
    provincesWithUnconnectedDevTargets: const {'oldWorld|p1'},
    hasUnconnectedDevTargets: true,
    frontierExtensionTiles: {frontierTile},
    bottleneckRailTiles: const {},
    adjacentToConnectedTiles: {frontierTile},
  );
  return (
    snapshot: snapshot,
    townResourceTile: townResourceTile,
    frontierTile: frontierTile,
  );
}

/// AC-F6 human suggestion parity for build_improvement connectivity ordering.
({
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
  String connectedGrain,
  String farGrain,
  ConnectivityDevSnapshot snapshot,
})
connectivityDevSuggestionParityCase() {
  const ow = 'oldWorld';
  const p1 = '$ow|p1';
  const playerId = 'gp1';
  const capTile = '$p1|2|2';
  const connectedGrain = '$p1|0|0';
  const farGrain = '$p1|4|0';
  final grid = List.generate(5, (_) => List.filled(5, 'p1'));
  final tileMap = TileMapResult(width: 5, height: 5, grid: grid);
  const topology = MapTopology(
    nodes: [TopologyNode(id: p1, regionId: ow, type: TopologyNodeType.province)],
    edges: [],
  );
  final tileState = TileMapState(
    improvementByTile: const {connectedGrain: 0, farGrain: 0},
    roadLevelByTile: {
      capTile: 1,
      '$p1|2|1': 1,
      '$p1|1|1': 1,
      '$p1|1|0': 1,
      connectedGrain: 1,
    },
  );
  final tiles = [
    for (var y = 0; y < 5; y++)
      for (var x = 0; x < 5; x++) '$p1|$x|$y',
  ];
  final game = ordersOwRegionGame(
    players: [
      Player(
        id: playerId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: p1,
        capitalTile: CapitalTile(regionId: ow, provinceId: p1, x: 2, y: 2),
        stockpile: const Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
      ),
    ],
    oldWorld: RegionData(
      provinces: [Province(id: p1, regionId: ow, ownerId: playerId)],
      units: [
        Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: playerId,
          locationProvinceId: p1,
          tileKey: capTile,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: {ow: {p1: tiles}},
    resourceByTileKey: {connectedGrain: 'grain', farGrain: 'grain'},
    tileState: tileState,
    playerVisibilityByTile: {playerId: {for (final t in tiles) t: 'fullyVisible'}},
  );
  final tileMapByRegion = {ow: tileMap};
  final snapshot = buildConnectivityDevSnapshot(
    game: game,
    playerId: playerId,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  )!;
  return (
    game: game,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    connectedGrain: connectedGrain,
    farGrain: farGrain,
    snapshot: snapshot,
  );
}

// dart format off
void connectivityDevRunForeignBarrierSnapshot() {final c = connectivityDevForeignBarrierCase(); final snapshot = buildConnectivityDevSnapshot(game: c.game,playerId: 'gp1',topology: c.topology,tileMapByRegion: c.tileMapByRegion,); expect(snapshot,isNotNull); expect(snapshot!.hasUnconnectedDevTargets,isTrue); expect(snapshot.extensionDistanceByTile[c.capTile],isNull,reason: 'foreign-province barrier must block owned-land extension distance toward the isolated resource province',);}

void connectivityDevRunFrontierRoadLexOrder() {final c = connectivityDevFrontierRoadLexCase(); final ordered = prioritizeBuildRoadCandidatesByConnectivity(snapshot: c.snapshot,sortedVisible: c.lexSorted,); expect(ordered.first,c.frontierTile); final unit = Unit(id: 'e1',type: kUnitTypeEngineer,ownerId: 'gp1',locationProvinceId: 'oldWorld|p1',); final suggestions = <WorkOrder>[]; WorkSuggestionPipeline.run(unit: unit,unitType: unit.type,unitRegionId: 'oldWorld',atProvinceId: 'oldWorld|p1',workTarget: kWorkTargetBuildRoad,existingTargetsByUnit: {},suggestions: suggestions,candidatesProvider: () sync* {for (final tileKey in ordered) {yield WorkOrder(unitId: unit.id,target: kWorkTargetBuildRoad,targetTileKey: tileKey,);}},candidateAcceptor: (_) => true,noCandidateReason: 'no_valid_tile',); expect(suggestions.single.targetTileKey,c.frontierTile);}

void connectivityDevRunTownRuleFrontier() {final c = connectivityDevTownRuleFrontierCase(); expect(c.snapshot.frontierExtensionTiles,isNot(contains(c.townResourceTile))); final ordered = prioritizeBuildRoadCandidatesByConnectivity(snapshot: c.snapshot,sortedVisible: [c.townResourceTile,c.frontierTile],); expect(ordered.first,c.frontierTile);}

void connectivityDevRunSuggestionParity() {final c = connectivityDevSuggestionParityCase(); expect(c.snapshot.connected,contains(c.connectedGrain)); expect(c.snapshot.connected,isNot(contains(c.farGrain))); final rawSorted = [c.farGrain,c.connectedGrain]..sort(); expect(prioritizeBuildImprovementCandidatesByConnectivity(snapshot: c.snapshot,sortedVisible: rawSorted,).first,c.connectedGrain,); final suggestions = suggestWorkOrders(buildPlayerView(c.game,c.topology,'gp1'),c.game,c.topology,const Orders(),tileMapByRegion: c.tileMapByRegion,); final improve = suggestions.where((o) => o.unitId == 'b1' && o.target == kWorkTargetBuildImprovement).toList(); expect(improve,hasLength(1)); expect(improve.single.targetTileKey,c.connectedGrain); final assign = selectDevelopmentImproveAssignCandidate(game: c.game,playerId: 'gp1',currentOrders: const Orders(),topology: c.topology,tileMapByRegion: c.tileMapByRegion,commodityTileKeys: {c.connectedGrain,c.farGrain},connectedTileKeys: c.snapshot.connected,); expect(assign,isNotNull); expect(assign!.targetTileKey,improve.single.targetTileKey);}

void connectivityDevRunWorkOrdersDeterminism() {final game = feedstockPriorityGame(); final topology = feedstockPriorityTopology(game); final view = buildPlayerView(game,topology,feedstockPrioritySupplierId); final tileMapByRegion = tileMapByRegionFromGame(game); final first = suggestWorkOrders(view,game,topology,const Orders(),tileMapByRegion: tileMapByRegion,); final second = suggestWorkOrders(view,game,topology,const Orders(),tileMapByRegion: tileMapByRegion,); expect(second.map((o) => (o.unitId,o.target,o.targetTileKey)).toList(),first.map((o) => (o.unitId,o.target,o.targetTileKey)).toList(),);}
// dart format on
