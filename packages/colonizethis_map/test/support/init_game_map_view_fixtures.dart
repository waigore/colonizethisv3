import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared scaffolding for the `buildInitGameMapViewData` view-builder test suite
/// (`init_game_map_view_builder_*_test.dart`).
///
/// Promotes the former file-private `_minimalGame` /
/// `_singleProvinceAndSeaTopology` helpers out of
/// `init_game_map_view_builder_slice_test.dart` and adds dual-region
/// `TileMapResult` / `MapTopology` builders so each view-builder test collapses
/// its inline `owMap`/`nwMap`/`owTopology`/`nwTopology`/`Game` boilerplate to a
/// few builder calls. The `repo.map_test_no_duplicate_view_fixtures` gate keeps
/// the inline dual-region clone from returning. This file stays inside the map
/// package `test/`; `colonizethis_test` gains no dependency on
/// `colonizethis_map`. Refs #3746.

/// Builds a [TileMapResult] from a [grid], deriving width/height from the rows.
///
/// All view-builder tests use rectangular grids, so width is taken from the
/// first row and height from the row count.
TileMapResult mapTileGrid(
  List<List<String>> grid, {
  List<List<TerrainType?>>? terrainGrid,
  List<List<Resource?>>? resourceGrid,
}) {
  return TileMapResult(
    width: grid.isEmpty ? 0 : grid.first.length,
    height: grid.length,
    grid: grid,
    terrainGrid: terrainGrid,
    resourceGrid: resourceGrid,
  );
}

/// Builds a [MapTopology] for one region from province and sea-zone node ids.
///
/// Province ids become `TopologyNodeType.province` nodes and sea-zone ids become
/// `TopologyNodeType.seaZone` nodes, all tagged with [regionId]; [edges] are
/// passed through unchanged.
MapTopology regionTopology({
  required String regionId,
  List<String> provinceIds = const [],
  List<String> seaZoneIds = const [],
  List<TopologyEdge> edges = const [],
}) {
  return MapTopology(
    nodes: [
      for (final id in provinceIds)
        TopologyNode(
          id: id,
          regionId: regionId,
          type: TopologyNodeType.province,
        ),
      for (final id in seaZoneIds)
        TopologyNode(
          id: id,
          regionId: regionId,
          type: TopologyNodeType.seaZone,
        ),
    ],
    edges: edges,
  );
}

/// Single province `p1` + single sea zone `s1` joined by one edge, in [regionId].
MapTopology singleProvinceAndSeaTopology(String regionId) {
  return regionTopology(
    regionId: regionId,
    provinceIds: const ['p1'],
    seaZoneIds: const ['s1'],
    edges: const [TopologyEdge(id1: 'p1', id2: 's1')],
  );
}

/// Minimal dual-region [Game] for `buildInitGameMapViewData` tests.
///
/// Wires the standard `WorldState(turnState: orders, oldWorld, newWorld)` shape
/// with optional units, fleets, players, minor nations, tribes, ports, and
/// sea-zone display names. Every parameter keeps the production default so a
/// bare `minimalGame(...)` matches the inline boilerplate it replaces.
Game minimalGame({
  String id = 'map-view-test',
  int turnNumber = 0,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  List<Fleet> fleets = const [],
  List<Player> players = const [],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
  Map<String, String> portsByProvinceSeaboard = const {},
  Map<String, String> seaZoneDisplayNameById = const {},
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      seaZoneDisplayNameById: seaZoneDisplayNameById,
      oldWorld: RegionData(provinces: oldWorldProvinces, units: oldWorldUnits),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      fleets: fleets,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Dual-region topology + tile maps used by visualization render tests.
MapTopology oldWorldTwoProvinceSeaVisualizationTopology() {
  return regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1', 'p2'],
    seaZoneIds: const ['s1'],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'p2'),
      TopologyEdge(id1: 'p1', id2: 's1'),
    ],
  );
}

/// Two adjacent sea zones in [regionId] (sea–sea border render tests).
MapTopology twoAdjacentSeaZonesTopology(String regionId) {
  return regionTopology(
    regionId: regionId,
    seaZoneIds: const ['s1', 's2'],
    edges: const [TopologyEdge(id1: 's1', id2: 's2')],
  );
}

/// Standard 4×3 visualization grid with p1/p2 land and s1 sea.
TileMapResult visualizationSmallTileMap() {
  return mapTileGrid([
    ['p1', 'p1', 'p2', 'p2'],
    ['p1', 's1', 's1', 'p2'],
    ['p1', 'p1', 'p2', 'p2'],
  ]);
}

/// Dual-region view-builder / visualizer scenario wiring.
class DualRegionViewScenario {
  const DualRegionViewScenario({
    required this.game,
    required this.tileMapByRegion,
    required this.topologyByRegion,
  });

  final Game game;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;

  InitGameMapViewData buildViewData({
    int cellSize = 8,
    int? seed,
    String? configSummary,
    Map<String, (int r, int g, int b)>? greatPowerColorOverride,
    Map<String, TileVisibility>? visibilityByTile,
    List<WarpLink>? warpLinks,
    Map<String, int>? resourceExtractionUnitsByTile,
    Map<String, int>? resourceExtractionEffectiveUnitsByTile,
    Map<String, int>? resourceExtractionBlockedUnitsByTile,
    Set<String>? civilianMarkerOwnerIds,
  }) {
    return buildInitGameMapViewData(
      game: game,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      cellSize: cellSize,
      seed: seed,
      configSummary: configSummary,
      greatPowerColorOverride: greatPowerColorOverride,
      visibilityByTile: visibilityByTile,
      warpLinks: warpLinks,
      resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
      resourceExtractionEffectiveUnitsByTile:
          resourceExtractionEffectiveUnitsByTile,
      resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
      civilianMarkerOwnerIds: civilianMarkerOwnerIds,
    );
  }
}

/// Builds a [DualRegionViewScenario] from dual-region maps, topologies, and game.
DualRegionViewScenario dualRegionViewScenario({
  required Game game,
  required TileMapResult oldWorldMap,
  required TileMapResult newWorldMap,
  required MapTopology oldWorldTopology,
  required MapTopology newWorldTopology,
}) {
  return DualRegionViewScenario(
    game: game,
    tileMapByRegion: {'oldWorld': oldWorldMap, 'newWorld': newWorldMap},
    topologyByRegion: {
      'oldWorld': oldWorldTopology,
      'newWorld': newWorldTopology,
    },
  );
}

/// Convenience wrapper for the common dual-region [buildInitGameMapViewData] call.
InitGameMapViewData buildViewDataForScenario(
  DualRegionViewScenario scenario, {
  int cellSize = 8,
  int? seed,
  String? configSummary,
  Map<String, (int r, int g, int b)>? greatPowerColorOverride,
  Map<String, TileVisibility>? visibilityByTile,
  List<WarpLink>? warpLinks,
  Map<String, int>? resourceExtractionUnitsByTile,
  Map<String, int>? resourceExtractionEffectiveUnitsByTile,
  Map<String, int>? resourceExtractionBlockedUnitsByTile,
  Set<String>? civilianMarkerOwnerIds,
}) {
  return scenario.buildViewData(
    cellSize: cellSize,
    seed: seed,
    configSummary: configSummary,
    greatPowerColorOverride: greatPowerColorOverride,
    visibilityByTile: visibilityByTile,
    warpLinks: warpLinks,
    resourceExtractionUnitsByTile: resourceExtractionUnitsByTile,
    resourceExtractionEffectiveUnitsByTile: resourceExtractionEffectiveUnitsByTile,
    resourceExtractionBlockedUnitsByTile: resourceExtractionBlockedUnitsByTile,
    civilianMarkerOwnerIds: civilianMarkerOwnerIds,
  );
}
