part of 'capital_choice.dart';

bool _isTileAdjacentToSea(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? provinceNodeIds(topology);
  return anyCardinalNeighborCell(x, y, map, (cellId) => !ids.contains(cellId));
}

bool _isTileAdjacentToOtherProvince(
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
