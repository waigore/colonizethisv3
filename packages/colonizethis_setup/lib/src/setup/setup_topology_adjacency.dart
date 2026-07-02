// SPEC/game/capital-and-connectivity.md § Capital Setup / Init town roads;
// SPEC/program/game-setup-pipeline.md.
//
// Package-internal source of truth for the *tile-grid* adjacency primitives the
// capital-choice port-road geometry and the province town-assignment site each
// previously carried as private clones:
//   - capital_choice_port_road_geometry.dart: `_anyCardinalNeighborCell`,
//     `_isTileAdjacentToSeaZone`.
//   - game_setup_helpers_towns.dart: the re-inlined cardinal-neighbor loop +
//     province-node-id set inside `_tileKeyAdjacentToProvinceSeaZone`.
//
// The pure *topology* adjacency concerns (`provinceNodeIds`,
// `seaZonesAdjacentToProvince`) are not re-declared here: both already exist as
// canonical, cached helpers in `colonizethis_world` (topology_helpers.dart) and
// are consumed directly, so this module covers only the tile-map-aware scans
// world does not provide. Topology node ids are stored in *local* form, so the
// helpers take the id form explicitly and never assume a prefixed shape
// (Refs #3740).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Visits the in-bounds 4-neighbor cell ids of ([x], [y]) in
/// [kGridNeighborsCardinal4] order, returning `true` as soon as [test] does.
/// Single neighbor-iteration skeleton shared by the adjacency scans.
bool anyCardinalNeighborCell(
  int x,
  int y,
  TileMapResult map,
  bool Function(String cellId) test,
) {
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    if (test(map.cell(nx, ny))) return true;
  }
  return false;
}

/// Whether tile ([x], [y]) in [map] is cardinally adjacent to a cell belonging
/// to sea zone [seaZoneId] (matched in either prefixed or local form), skipping
/// province cells. [provinceIds] may be precomputed via [provinceNodeIds].
bool tileAdjacentToSeaZone(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology,
  String seaZoneId, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? provinceNodeIds(topology);
  final seaZoneLocal = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
  return anyCardinalNeighborCell(x, y, map, (cellId) {
    if (ids.contains(cellId)) return false;
    return cellId == seaZoneId || cellId == seaZoneLocal;
  });
}

/// Whether tile ([x], [y]) in [map] is cardinally adjacent to any cell in
/// [seaZoneIds], skipping province cells. Multi-zone variant of
/// [tileAdjacentToSeaZone] for town-assignment seaboard scans (Refs #3840).
bool tileAdjacentToAnySeaZone(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology,
  Set<String> seaZoneIds, {
  Set<String>? provinceIds,
}) {
  if (seaZoneIds.isEmpty) return false;
  final ids = provinceIds ?? provinceNodeIds(topology);
  return anyCardinalNeighborCell(x, y, map, (cellId) {
    if (ids.contains(cellId)) return false;
    return seaZoneIds.contains(cellId);
  });
}

/// Whether [tileKey] is cardinally adjacent to any sea zone in [seaZoneIds].
bool tileKeyAdjacentToAnySeaZone({
  required String tileKey,
  required String provinceId,
  required Set<String> seaZoneIds,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
}) {
  if (seaZoneIds.isEmpty) return false;
  final regionId = ProvinceId.regionIdFrom(provinceId);
  final map = tileMapByRegion[regionId];
  final topology = topologyByRegion[regionId];
  if (map == null || topology == null) return false;
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return false;
  return tileAdjacentToAnySeaZone(
    coords.x,
    coords.y,
    map,
    topology,
    seaZoneIds,
  );
}
