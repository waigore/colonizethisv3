import 'package:colonizethis_data/colonizethis_data.dart';
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
