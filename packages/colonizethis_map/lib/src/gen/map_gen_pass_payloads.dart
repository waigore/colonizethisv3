/// Typed [MapGenPass] payloads/results. SPEC/program/tile-map-gen-algorithm.md.
/// Standalone library so `run` signatures stay free of `part` classes (Refs #3574).
library map_gen_pass_payloads;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

/// Pass 2–3 land seeding/assignment inputs.
class LandSeedPassPayload {
  const LandSeedPassPayload({
    required this.grid,
    required this.provinceToContinent,
    required this.seaZoneId,
    required this.rnd,
    required this.seedBeforeAssignment,
  });

  final List<List<String>> grid;
  final Map<String, int> provinceToContinent;
  final String seaZoneId;
  final Random rnd;
  final bool seedBeforeAssignment;
}

/// Land-seed pass result: assigned grid plus seed bookkeeping.
class LandSeedPassResult {
  const LandSeedPassResult({
    required this.grid,
    required this.continentSeeds,
    required this.landSeeds,
    required this.continentBySeedIndex,
  });

  final List<List<String>> grid;
  final List<(int x, int y)> continentSeeds;
  final List<(int x, int y)> landSeeds;
  final List<int> continentBySeedIndex;
}

/// Pass 4–5 lake/moat fill and border noise inputs.
class LakesPassPayload {
  const LakesPassPayload({
    required this.grid,
    required this.seaZoneId,
    required this.landSeeds,
    required this.continentBySeedIndex,
    required this.rnd,
  });

  final List<List<String>> grid;
  final String seaZoneId;
  final List<(int x, int y)> landSeeds;
  final List<int> continentBySeedIndex;
  final Random rnd;
}

/// Pass 6–7 terrain and resource assignment inputs.
class TerrainPassPayload {
  const TerrainPassPayload({
    required this.grid,
    required this.regionId,
    required this.resourceRules,
    required this.rnd,
  });

  final List<List<String>> grid;
  final String regionId;
  final ResourceRules? resourceRules;
  final Random rnd;
}

/// Terrain/resource pass result; both grids are `null` when skipped.
typedef TerrainPassResult = (
  List<List<TerrainType?>>? terrainGrid,
  List<List<Resource?>>? resourceGrid,
);

/// Pass 10 continent joining inputs. SPEC/program/tile-map-gen-algorithm.md.
class ContinentJoinPassPayload {
  const ContinentJoinPassPayload({
    required this.grid,
    required this.terrainGrid,
    required this.resourceGrid,
    required this.provinceToContinent,
    required this.seaZoneId,
    required this.mapRegionId,
    required this.landSeeds,
    required this.continentBySeedIndex,
    required this.resourceRules,
    required this.rnd,
  });

  final List<List<String>> grid;
  final List<List<TerrainType?>>? terrainGrid;
  final List<List<Resource?>>? resourceGrid;
  final Map<String, int> provinceToContinent;
  final String seaZoneId;
  final String? mapRegionId;
  final List<(int x, int y)> landSeeds;
  final List<int> continentBySeedIndex;
  final ResourceRules? resourceRules;
  final Random rnd;
}

/// Continent-join result plus whether a land bridge was added.
class ContinentJoinPassResult {
  const ContinentJoinPassResult({
    required this.grid,
    required this.terrainGrid,
    required this.resourceGrid,
    required this.didJoin,
  });

  final List<List<String>> grid;
  final List<List<TerrainType?>>? terrainGrid;
  final List<List<Resource?>>? resourceGrid;
  final bool didJoin;
}

/// Pass 10b terrain jitter inputs. SPEC/program/tile-map-gen-algorithm.md.
class TerrainJitterPassPayload {
  const TerrainJitterPassPayload({
    required this.grid,
    required this.terrainGrid,
    required this.resourceGrid,
    required this.regionId,
    required this.rnd,
  });

  final List<List<String>> grid;
  final List<List<TerrainType?>> terrainGrid;
  final List<List<Resource?>> resourceGrid;
  final String regionId;
  final Random rnd;
}

/// Pass 11 sea-zone subdivision inputs.
class SeaZoneSubdividePassPayload {
  const SeaZoneSubdividePassPayload({
    required this.grid,
    required this.seaZoneId,
    required this.totalSea,
  });

  final List<List<String>> grid;
  final String seaZoneId;
  final int totalSea;
}

/// Subdivided grid and sea-zone count.
typedef SeaZoneSubdividePassResult = (
  List<List<String>> grid,
  int seaZoneCount,
);
