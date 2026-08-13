import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'region_map_component_shared_visibility_terrain.dart';

final class _PlainsDesertTally {
  int plains = 0;
  int desert = 0;
}

void _tallyDominantLandNeighbor(CellViewData? cell, _PlainsDesertTally tally) {
  if (cell == null || cell.isSea) {
    return;
  }
  final terrain = cell.terrainType;
  if (terrain == TerrainType.plains) {
    tally.plains++;
    return;
  }
  if (terrain == TerrainType.desert) {
    tally.desert++;
    return;
  }
  if (terrain != null && regionMapComponentIsFeatureTerrain(terrain)) {
    tally.plains++; // Features have plains underneath
  }
}

/// Get the dominant adjacent land base type for coastline tileset selection.
/// Returns 'plains' or 'desert' based on which is more common among neighbors.
TerrainType? regionMapComponentDominantAdjacentLandBase(
  int x,
  int y,
  CellViewData? Function(int, int) getCellAt,
) {
  final tally = _PlainsDesertTally();

  for (final dy in [-1, 0, 1]) {
    for (final dx in [-1, 0, 1]) {
      if (dx == 0 && dy == 0) {
        continue;
      }
      _tallyDominantLandNeighbor(getCellAt(x + dx, y + dy), tally);
    }
  }

  if (tally.plains >= tally.desert) {
    return TerrainType.plains;
  }
  return TerrainType.desert;
}
