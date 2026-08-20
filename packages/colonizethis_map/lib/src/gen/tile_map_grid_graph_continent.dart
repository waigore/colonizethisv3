/// Nearest land-seed and continent identity for tile map generation.
/// SPEC/program/tile-map-gen-algorithm.md

import 'tile_map_distance_sentinels.dart';
import 'tile_map_land_seed_contract.dart';

class TileMapGridGraphContinent {
  TileMapGridGraphContinent(this.params);

  final TileMapLandSeedParams params;

  /// Index of the land seed with smallest squared distance to (x, y).
  ///
  /// Returns 0 when [landSeeds] is empty. Refs #2489.
  int nearestLandSeedIndexForCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
  ) {
    if (landSeeds.isEmpty) return 0;
    var bestSeedIndex = 0;
    var bestD2 = kUnsetSquaredDistanceInt31;
    for (var i = 0; i < landSeeds.length; i++) {
      final (sx, sy) = landSeeds[i];
      final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
      if (d2 < bestD2) {
        bestD2 = d2;
        bestSeedIndex = i;
      }
    }
    return bestSeedIndex;
  }

  /// Continent index for a land cell from nearest land seed. Returns 0 when seeds empty.
  int continentForLandCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    if (landSeeds.isEmpty) return 0;
    return continentBySeedIndex[
      nearestLandSeedIndexForCell(x, y, landSeeds)
    ];
  }
}
