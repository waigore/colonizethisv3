/// Shared per-component / per-blob terrain helpers for the generation layer.
///
/// Deduplicates the blob-walking primitives that previously lived as private
/// members of the `part of 'tile_map_generator.dart'` terrain fragment and were
/// re-used independently by the region-growing, pattern-refinement, noise, and
/// hardwood passes. Extracted into a standalone library so each pass can consume
/// them without `part`/`part of` coupling (Refs #3588).
/// SPEC/program/tile-map-gen-algorithm.md § Implementation Structure.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

/// Cells of [component] whose assigned terrain equals [t].
Set<(int x, int y)> componentCellsOfTerrain(
  List<List<TerrainType?>> terrainGrid,
  Set<(int x, int y)> component,
  TerrainType t,
) {
  final out = <(int x, int y)>{};
  for (final (x, y) in component) {
    if (terrainGrid[y][x] != t) continue;
    out.add((x, y));
  }
  return out;
}

/// Cells of [blob] all of whose [directions] neighbours are also in [blob] and
/// in-bounds (so the cell is fully interior, never on the blob edge or grid
/// boundary). Used to keep blob shapes recognizable when carving pockets.
List<(int x, int y)> blobInteriorCells(
  Set<(int x, int y)> blob,
  int width,
  int height,
  List<(int dx, int dy)> directions,
) {
  final interior = <(int x, int y)>[];
  for (final (x, y) in blob) {
    if (!_blobCellIsFullyInterior(blob, width, height, directions, x, y)) {
      continue;
    }
    interior.add((x, y));
  }
  return interior;
}

bool _blobCellIsFullyInterior(
  Set<(int x, int y)> blob,
  int width,
  int height,
  List<(int dx, int dy)> directions,
  int x,
  int y,
) {
  for (final (dx, dy) in directions) {
    final nx = x + dx;
    final ny = y + dy;
    if (nx < 0 || nx >= width || ny < 0 || ny >= height) return false;
    if (!blob.contains((nx, ny))) return false;
  }
  return true;
}

/// Weighted pick of a terrain from [options], biased by each terrain's desired
/// non-mountain fraction in [distribution]. Deterministic for a fixed [rnd]
/// sequence and a fixed [options] order (generation determinism preserved).
TerrainType weightedPickTerrainFromOptions(
  List<TerrainType> options,
  TerrainDistribution distribution,
  Random rnd,
) {
  final weights = <double>[];
  for (final t in options) {
    final desired = distribution.nonMountainFractions[t] ?? 0.0;
    weights.add(max(0.0001, desired));
  }
  final total = weights.fold<double>(0, (a, b) => a + b);
  var roll = rnd.nextDouble() * total;
  for (var idx = 0; idx < options.length; idx++) {
    roll -= weights[idx];
    if (roll > 0) continue;
    return options[idx];
  }
  return options.first;
}
