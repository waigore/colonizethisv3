/// Local-density scoring for coastline growth (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'tile_map_land_seed_contract.dart';
import 'tile_map_land_sentinel.dart';

/// Score coastal sea cells by nearby same-continent land.
class LandSeedCoastScore {
  const LandSeedCoastScore._();

  static int coastalNeighborScoreDelta(
    List<List<String>> g,
    List<List<int>> cg,
    int nx,
    int ny,
    int continentIndex,
  ) {
    if (g[ny][nx] != kTileMapLandSentinel) return 0;
    final nc = cg[ny][nx];
    if (nc == continentIndex) return 1;
    if (nc >= 0 && nc != continentIndex) return -10;
    return 0;
  }

  static int scoreCoastalCellForContinent(
    List<List<String>> g,
    List<List<int>> cg,
    TileMapLandSeedParams params,
    int sx,
    int sy,
    int continentIndex,
    int scoreRadius,
  ) {
    var score = 0;
    for (var dy = -scoreRadius; dy <= scoreRadius; dy++) {
      for (var dx = -scoreRadius; dx <= scoreRadius; dx++) {
        final nx = sx + dx;
        final ny = sy + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (dx == 0 && dy == 0) continue;
        score += coastalNeighborScoreDelta(g, cg, nx, ny, continentIndex);
      }
    }
    return score;
  }
}
