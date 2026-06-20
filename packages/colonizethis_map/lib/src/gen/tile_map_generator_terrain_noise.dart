/// Pass 6b.5: smooth-noise terrain variation perturbation.

part of 'tile_map_generator.dart';

extension _TileMapGenTerrainResourceNoise on _TileMapGenTerrainResource {
  /// Pass 6b.5 — Noise perturbation. For each large non-mountain blob in
  /// `component`, scatter small patches of other non-mountain terrains into
  /// the blob's **interior** cells using a smooth 2D noise field. The pass
  /// is bypassed entirely (no RNG advance, no iteration) when
  /// `params.terrainVariation == 0.0`. Mountain cells, blob edge cells, and
  /// blobs smaller than `params.patternMinBlobSize` are never modified.
  /// SPEC/program/tile-map-gen-algorithm.md § Pass 6b.5.
  void _applyTerrainNoisePerturbation(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    if (params.terrainVariation <= 0.0) return;
    if (component.isEmpty || allowedNonMountain.isEmpty) return;

    const directions = kTileMapDirections4;
    final threshold = 1.0 - params.terrainVariation;

    for (final terrain in allowedNonMountain) {
      final cells = _componentCellsOfTerrain(terrainGrid, component, terrain);
      if (cells.isEmpty) continue;
      final blobs = _graph.connectedComponentsOfLand(cells);
      if (blobs.isEmpty) continue;

      for (final blob in blobs) {
        _perturbOneBlobWithNoise(
          terrainGrid,
          grid,
          blob,
          terrain,
          allowedNonMountain,
          distribution,
          directions,
          threshold,
          rnd,
        );
      }
    }
  }

  void _perturbOneBlobWithNoise(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> blob,
    TerrainType blobTerrain,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    List<(int dx, int dy)> directions,
    double threshold,
    Random rnd,
  ) {
    if (blob.length < params.patternMinBlobSize) return;

    final interior = _interiorCellsOfBlob(blob, directions);
    if (interior.isEmpty) return;

    final options = allowedNonMountain
        .where((t) => t != blobTerrain)
        .toList();
    if (options.isEmpty) return;

    for (final (x, y) in interior) {
      if (terrainGrid[y][x] == TerrainType.mountain) continue;
      if (terrainGrid[y][x] != blobTerrain) continue;
      if (grid[y][x] != _landSentinel) continue;
      final n = _smoothNoiseAt(x, y);
      if (n <= threshold) continue;
      final replacement = _weightedPickTerrainFromOptions(
        options,
        distribution,
        rnd,
      );
      terrainGrid[y][x] = replacement;
    }
  }

  /// Smooth 2D noise in [-1, 1] via bilinear interpolation of
  /// `deterministicNoise(params.seed, gx, gy)` corner samples on a fixed
  /// grid spacing of 4 cells. SPEC/program/tile-map-gen-algorithm.md § Pass 6b.5.
  double _smoothNoiseAt(int x, int y) {
    const gridSpacing = 4;
    final gx0 = (x ~/ gridSpacing) * gridSpacing;
    final gy0 = (y ~/ gridSpacing) * gridSpacing;
    final gx1 = gx0 + gridSpacing;
    final gy1 = gy0 + gridSpacing;
    final tx = (x - gx0) / gridSpacing;
    final ty = (y - gy0) / gridSpacing;
    final c00 = deterministicNoise(params.seed, gx0, gy0);
    final c10 = deterministicNoise(params.seed, gx1, gy0);
    final c01 = deterministicNoise(params.seed, gx0, gy1);
    final c11 = deterministicNoise(params.seed, gx1, gy1);
    final top = c00 * (1 - tx) + c10 * tx;
    final bot = c01 * (1 - tx) + c11 * tx;
    return top * (1 - ty) + bot * ty;
  }
}
