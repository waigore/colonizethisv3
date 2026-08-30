/// Organic land-seed candidate selection and per-round placement.
///
/// SPEC/program/tile-map-gen-algorithm.md § Land assignment modes.
library;

import 'dart:math';

import 'tile_map_land_seed_contract.dart';
import '../tile_map_grid.dart';
import 'tile_map_manhattan_distance_transform.dart';

/// Close-sea candidate enumeration and best-cell selection for one organic
/// land seed per continent per round.
class LandSeedOrganicPlacement {
  const LandSeedOrganicPlacement._();

  static List<(int x, int y)> organicSeedCloseSeaCandidates(
    TileMapLandSeedParams params,
    List<List<String>> grid,
    String seaZoneId,
    int closeRadius,
    List<List<int>> minDistToOwnLand,
  ) {
    final candidates = <(int x, int y)>[];
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != seaZoneId) return;
      final minDistToOwn = minDistToOwnLand[y][x];
      if (minDistToOwn > closeRadius) return;
      candidates.add((x, y));
    });
    return candidates;
  }

  static (int, int) pickBestOrganicSeaCandidate(
    List<(int x, int y)> candidates,
    List<List<int>> minDistToOwnLand,
    List<List<int>> distToOtherContinent,
    double awayPenalty,
    Random rnd,
  ) {
    var bestScore = -1e100;
    final bestCandidates = <(int x, int y)>[];
    for (final (x, y) in candidates) {
      final minDistToOwn = minDistToOwnLand[y][x];
      final minDistToOther = distToOtherContinent[y][x];
      final score = -minDistToOwn + awayPenalty * minDistToOther;
      if (score > bestScore) {
        bestScore = score;
        bestCandidates.clear();
        bestCandidates.add((x, y));
      } else if ((score - bestScore).abs() < 0.01) {
        bestCandidates.add((x, y));
      }
    }
    if (bestCandidates.isEmpty) return (-1, -1);
    return bestCandidates[rnd.nextInt(bestCandidates.length)];
  }

  /// Place one land seed near existing land of continent [c], preferably away
  /// from others.
  static (int, int) placeOneOrganicSeed(
    TileMapLandSeedParams params,
    List<List<String>> grid,
    List<List<int>> distToOtherContinent,
    (int x, int y) continentSeed,
    List<(int x, int y)> existingLandSeeds,
    List<int> continentBySeedIndex,
    int c,
    int closeRadius,
    double awayPenalty,
    String seaZoneId,
    Random rnd,
  ) {
    final ownLandOrSeed = <(int x, int y)>[continentSeed];
    for (var i = 0; i < existingLandSeeds.length; i++) {
      if (continentBySeedIndex[i] == c) {
        ownLandOrSeed.add(existingLandSeeds[i]);
      }
    }
    final minDistToOwnLand = manhattanDistToNearestPoints(
      params.width,
      params.height,
      ownLandOrSeed,
      distanceWhenNoSources: 1 << 30,
    );
    final candidates = organicSeedCloseSeaCandidates(
      params,
      grid,
      seaZoneId,
      closeRadius,
      minDistToOwnLand,
    );
    if (candidates.isEmpty) {
      final (cx, cy) = continentSeed;
      const jitter = 2;
      final jx = (cx + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(
        0,
        params.width - 1,
      );
      final jy = (cy + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(
        0,
        params.height - 1,
      );
      return (jx, jy);
    }
    return pickBestOrganicSeaCandidate(
      candidates,
      minDistToOwnLand,
      distToOtherContinent,
      awayPenalty,
      rnd,
    );
  }
}
