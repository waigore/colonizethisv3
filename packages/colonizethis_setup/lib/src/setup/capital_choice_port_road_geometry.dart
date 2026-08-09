// SPEC/game/capital-choice-phase — port/road adjacency geometry helpers
// (Refs #4086 Slice B de-part).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'setup_topology_adjacency.dart';

bool isTileAdjacentToSea(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? provinceNodeIds(topology);
  return anyCardinalNeighborCell(x, y, map, (cellId) => !ids.contains(cellId));
}

bool isTileAdjacentToOtherProvince(
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIds,
  String provinceId,
) {
  return anyCardinalNeighborCell(
    x,
    y,
    map,
    (cellId) => provinceIds.contains(cellId) && cellId != provinceId,
  );
}
