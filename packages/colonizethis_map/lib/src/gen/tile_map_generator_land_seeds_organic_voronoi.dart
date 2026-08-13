/// Organic land-seed Voronoi assignment with continent no-join buffer.
///
/// SPEC/program/tile-map-gen-algorithm.md § Land assignment modes.
library;

import 'tile_map_generator_land_seeds_shared.dart';
import 'tile_map_land_seed_contract.dart';
import '../tile_map_grid.dart';
import 'tile_map_land_sentinel.dart';

/// Small per-round Voronoi land assignment that refuses cells that would join
/// another continent within the buffer.
class LandSeedOrganicVoronoi {
  const LandSeedOrganicVoronoi._();

  /// Voronoi with no-join: do not assign cell to [c] if any cell within buffer
  /// is land of another continent.
  static (List<List<String>>, List<List<int>>) assignLandByLandSeedsWithNoJoin(
    TileMapLandSeedParams params,
    List<List<String>> grid,
    List<List<int>> continentGrid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    List<int> budgetPerContinent,
  ) {
    if (landSeeds.isEmpty) return (grid, continentGrid);
    final numContinents = budgetPerContinent.length;

    final seedStartByContinent = List<int>.filled(numContinents, 0);
    final seedEndByContinent = List<int>.filled(numContinents, 0);
    LandSeedShared.fillLandSeedIndexRangesByContinent(
      continentBySeedIndex,
      numContinents,
      landSeeds.length,
      seedStartByContinent,
      seedEndByContinent,
    );

    final entries = LandSeedShared.voronoiLandCellEntries(
      params,
      landSeeds,
      numContinents,
      seedStartByContinent,
      seedEndByContinent,
    );
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    final next = TileMapGrid.copy(grid);
    final nextContinent = TileMapGrid.copy(continentGrid);
    final used = List<int>.filled(numContinents, 0);
    final buffer = params.continentBufferTiles == 0
        ? 1
        : params.continentBufferTiles;
    final offsets = LandSeedShared.bufferOffsets(buffer);
    for (final (_, x, y, c) in entries) {
      if (next[y][x] == kTileMapLandSentinel) continue;
      if (used[c] >= budgetPerContinent[c]) continue;
      if (LandSeedShared.wouldJoinOtherContinentInBuffer(
        nextContinent,
        params,
        x,
        y,
        c,
        offsets,
      )) {
        continue;
      }
      next[y][x] = kTileMapLandSentinel;
      nextContinent[y][x] = c;
      used[c]++;
    }
    return (next, nextContinent);
  }
}
