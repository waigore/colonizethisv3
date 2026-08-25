/// Coastal-tile registration and sea-neighbor expansion (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';
import 'tile_map_generator_land_seeds_coast_membership.dart';
import 'tile_map_land_seed_contract.dart';
import 'tile_map_land_sentinel.dart';

/// Register coastal sea tiles and append orthogonal sea neighbors.
class LandSeedCoastRegister {
  const LandSeedCoastRegister._();

  static void appendOrthogonalSeaNeighborsToCoastalList(
    TileMapLandSeedParams params,
    List<List<String>> g,
    String seaZoneId,
    int sx,
    int sy,
    LandSeedCoastalCells coastal,
  ) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = sx + dx;
      final ny = sy + dy;
      if (nx >= 0 &&
          nx < params.width &&
          ny >= 0 &&
          ny < params.height &&
          g[ny][nx] == seaZoneId &&
          !coastal.contains((nx, ny))) {
        coastal.addIfAbsent((nx, ny));
      }
    }
  }

  static void registerFirstOrthogonalSeaTouchingLand(
    TileMapLandSeedParams params,
    List<List<String>> g,
    String seaZoneId,
    int x,
    int y,
    void Function(int nx, int ny) onSea,
  ) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (g[ny][nx] != seaZoneId) continue;
      onSea(nx, ny);
      return;
    }
  }

  static void registerCoastalSeaTilesAdjacentToLand(
    TileMapLandSeedParams params,
    List<List<String>> g,
    List<List<int>> cg,
    String seaZoneId,
    Map<int, LandSeedCoastalCells> coastalByContinent,
  ) {
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (g[y][x] != kTileMapLandSentinel) return;
      final c = cg[y][x];
      if (c < 0) return;
      registerFirstOrthogonalSeaTouchingLand(
        params,
        g,
        seaZoneId,
        x,
        y,
        (nx, ny) => coastalByContinent[c]!.addAllowingDuplicate((nx, ny)),
      );
    });
  }
}
