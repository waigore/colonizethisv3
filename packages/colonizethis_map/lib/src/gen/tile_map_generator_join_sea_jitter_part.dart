part of 'tile_map_generator.dart';

extension _TileMapGenJoinSeaJitterPart on _TileMapGenJoinSea {
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
