/// Pass 10b: per-province terrain jitter.
///
/// Extracted from the former `_TileMapGenJoinSea` jitter fragment into a
/// standalone [MapGenPass] family (Refs #3588). Breaks up overly homogeneous
/// provinces by reassigning a bounded fraction of edge cells of the dominant
/// terrain to neighbour-supported terrains. Mutates the terrain grid in place.
/// SPEC/program/tile-map-gen-algorithm.md § Pass 10b.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';
import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_params.dart';

/// Pass 10b terrain-jitter service.
class TerrainJitterPass implements MapGenPass<TerrainJitterPassPayload, void> {
  TerrainJitterPass(this.params);

  @override
  final TileMapParams params;

  /// Uniform pass entry: applies [jitterTerrainByProvince] in place (Refs #3588).
  @override
  void run(MapGenPassContext<TerrainJitterPassPayload> ctx) {
    final payload = ctx.payload;
    jitterTerrainByProvince(
      payload.grid,
      payload.terrainGrid,
      payload.resourceGrid,
      payload.regionId,
      payload.rnd,
    );
  }

  bool _jitterTileIsTerrainOrProvinceEdge(
    int x,
    int y,
    String provinceId,
    TerrainType dominant,
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    int width,
    int height,
    List<(int dx, int dy)> directions4,
  ) {
    for (final (dx, dy) in directions4) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
      final neighborProvince = grid[ny][nx];
      final neighborTerrain = terrainGrid[ny][nx];
      if (neighborProvince != provinceId) return true;
      if (neighborTerrain != null && neighborTerrain != dominant) {
        return true;
      }
    }
    return false;
  }

  void jitterTerrainByProvince(
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    String regionId,
    Random rnd,
  ) {
    final allowedNonMountain = allowedTerrainsForRegion(
      regionId,
    ).where((t) => t != TerrainType.mountain).toList();
    if (allowedNonMountain.isEmpty) return;

    final height = grid.length;
    if (height == 0) return;
    final width = grid[0].length;
    final tilesByProvince = <String, List<(int x, int y)>>{};
    final provinceIdPattern = RegExp(r'^p\d+$');
    TileMapGrid.forEachCell(grid, (y, x, id) {
      if (!provinceIdPattern.hasMatch(id)) return;
      tilesByProvince.putIfAbsent(id, () => []).add((x, y));
    });
    if (tilesByProvince.isEmpty) return;

    const directions4 = kTileMapDirections4;
    const directions8 = kTileMapDirections8;

    for (final entry in tilesByProvince.entries) {
      final tiles = entry.value;
      if (tiles.length < params.jitterMinProvinceSize) continue;

      final counts = <TerrainType, int>{};
      var terrainTiles = 0;
      for (final (x, y) in tiles) {
        final t = terrainGrid[y][x];
        if (t == null) continue;
        counts[t] = (counts[t] ?? 0) + 1;
        terrainTiles++;
      }
      if (terrainTiles == 0 || counts.isEmpty) continue;

      TerrainType dominant = counts.keys.first;
      var maxCount = counts[dominant]!;
      for (final e in counts.entries) {
        if (e.value > maxCount) {
          dominant = e.key;
          maxCount = e.value;
        }
      }
      final fDom = maxCount / terrainTiles;
      if (fDom < params.jitterHomogeneityThreshold) continue;

      final candidates = <(int x, int y)>[];
      for (final (x, y) in tiles) {
        if (terrainGrid[y][x] != dominant) continue;
        if (resourceGrid[y][x] != null) continue;
        if (!_jitterTileIsTerrainOrProvinceEdge(
          x,
          y,
          entry.key,
          dominant,
          grid,
          terrainGrid,
          width,
          height,
          directions4,
        )) {
          continue;
        }
        candidates.add((x, y));
      }
      if (candidates.isEmpty) continue;

      candidates.shuffle(rnd);
      final maxChanges = (params.jitterMaxFraction * tiles.length).floor();
      if (maxChanges <= 0) continue;
      var changes = 0;
      for (final (x, y) in candidates) {
        if (changes >= maxChanges) break;
        if (rnd.nextDouble() > params.jitterProbability) continue;

        final neighborCounts = <TerrainType, int>{};
        for (final (dx, dy) in directions8) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          if (grid[ny][nx] != entry.key) continue;
          final nt = terrainGrid[ny][nx];
          if (nt == null || nt == dominant || nt == TerrainType.mountain) {
            continue;
          }
          neighborCounts[nt] = (neighborCounts[nt] ?? 0) + 1;
        }

        final supported = neighborCounts.entries
            .where((e) => e.value >= params.jitterNeighborSupportThreshold)
            .map((e) => e.key)
            .toList();
        if (supported.isEmpty) continue;
        terrainGrid[y][x] = supported[rnd.nextInt(supported.length)];
        changes++;
      }
    }
  }
}
