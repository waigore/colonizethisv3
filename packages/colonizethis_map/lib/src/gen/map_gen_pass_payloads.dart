/// Typed payloads/results for the [MapGenPass] uniform pass entry points
/// adopted by the land-seed, lakes/province, and terrain/resource generation
/// service families (Refs #3574, slice 4).
///
/// These types live in a standalone library (not a generator `part` file) so
/// the families can name them in their public `run` signatures without tripping
/// `repo.map_no_partfile_classes`. SPEC/program/tile-map-gen-algorithm.md.
library map_gen_pass_payloads;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

/// Inputs for [TileMapGenLandSeeds] Pass 2–3 land seeding/assignment.
class LandSeedPassPayload {
  const LandSeedPassPayload({
    required this.grid,
    required this.provinceToContinent,
    required this.seaZoneId,
    required this.rnd,
    required this.seedBeforeAssignment,
  });

  /// Initial all-sea grid to assign land into.
  final List<List<String>> grid;

  /// Province id → continent index partition.
  final Map<String, int> provinceToContinent;

  /// Sea zone sentinel id used for unassigned cells.
  final String seaZoneId;

  /// Deterministic RNG shared across the generation pipeline.
  final Random rnd;

  /// When `true`, use the seed-before-assignment path; otherwise organic.
  final bool seedBeforeAssignment;
}

/// Result of the land-seed pass: assigned grid plus seed bookkeeping.
class LandSeedPassResult {
  const LandSeedPassResult({
    required this.grid,
    required this.continentSeeds,
    required this.landSeeds,
    required this.continentBySeedIndex,
  });

  /// Grid with land cells assigned (sentinel land vs [seaZoneId]).
  final List<List<String>> grid;

  /// One continent seed per continent.
  final List<(int x, int y)> continentSeeds;

  /// All placed land-shape seeds.
  final List<(int x, int y)> landSeeds;

  /// Parallel to [landSeeds]: continent index for each land seed.
  final List<int> continentBySeedIndex;
}

/// Inputs for [MapGenPass] Pass 4–5 lake/moat fill and border noise.
class LakesPassPayload {
  const LakesPassPayload({
    required this.grid,
    required this.seaZoneId,
    required this.landSeeds,
    required this.continentBySeedIndex,
    required this.rnd,
  });

  /// Post-Pass-3 grid (land sentinel vs [seaZoneId]).
  final List<List<String>> grid;

  /// Sea zone sentinel id.
  final String seaZoneId;

  /// Land seeds used for ocean/continent classification.
  final List<(int x, int y)> landSeeds;

  /// Parallel to [landSeeds]: continent index per land seed.
  final List<int> continentBySeedIndex;

  /// Deterministic RNG shared across the generation pipeline.
  final Random rnd;
}

/// Inputs for Pass 6–7 terrain and resource assignment.
class TerrainPassPayload {
  const TerrainPassPayload({
    required this.grid,
    required this.regionId,
    required this.resourceRules,
    required this.rnd,
  });

  /// Grid with provinces/land assigned.
  final List<List<String>> grid;

  /// Map region id (`oldWorld` / `newWorld`).
  final String regionId;

  /// Resource rules; `null` skips terrain/resource assignment entirely.
  final ResourceRules? resourceRules;

  /// Deterministic RNG shared across the generation pipeline.
  final Random rnd;
}

/// Result of the terrain/resource pass; both grids are `null` when skipped.
typedef TerrainPassResult = (
  List<List<TerrainType?>>? terrainGrid,
  List<List<Resource?>>? resourceGrid,
);
