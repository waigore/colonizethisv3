/// Allowed terrain types per region. TDD 04b, SPEC/program/tile-map-generation.md.
/// Canonical source: Imperialism II Terrain and Development table (OW-only, NW-only, Both).
/// Phase 1: minimal mapping from current TerrainType enum; extend when terrain enum is expanded.

import 'terrain_type.dart';

/// Terrains allowed in the Old World (OW-only + Both from canonical table).
/// Phase 1: all current types; extend when adding e.g. Grain Farm, Open Range.
const List<TerrainType> oldWorldTerrains = [
  TerrainType.plains,
  TerrainType.forest,
  TerrainType.hills,
  TerrainType.mountain,
  TerrainType.swamp,
];

/// Terrains allowed in the New World (NW-only + Both from canonical table).
/// Phase 1: all current types; extend when adding e.g. Sugar Plantation, Desert.
const List<TerrainType> newWorldTerrains = [
  TerrainType.plains,
  TerrainType.forest,
  TerrainType.hills,
  TerrainType.mountain,
  TerrainType.swamp,
];

/// Normalized terrain distribution for a map region.
///
/// [mountainFraction] is the target fraction of land tiles that should be
/// [TerrainType.mountain]. [nonMountainFractions] are target fractions for all
/// other terrain types; they sum to (1 - mountainFraction).
class TerrainDistribution {
  const TerrainDistribution({
    required this.mountainFraction,
    required this.nonMountainFractions,
  });

  /// Target fraction of land tiles that are mountains (0–1).
  final double mountainFraction;

  /// Target fractions for all non-mountain terrain types.
  /// Keys are terrain types; values are in [0, 1]. Sum of all values is
  /// (1 - [mountainFraction]).
  final Map<TerrainType, double> nonMountainFractions;

  /// Returns the target fraction for [terrain]. Mountains use
  /// [mountainFraction]; other terrains use [nonMountainFractions] (or 0 when
  /// missing).
  double fractionFor(TerrainType terrain) {
    if (terrain == TerrainType.mountain) {
      return mountainFraction;
    }
    return nonMountainFractions[terrain] ?? 0.0;
  }
}

// Phase 1 default terrain weights and mountain fractions per region.
//
// These are implementation defaults; rulesets in future phases may override
// them via data-driven configuration.

// Old World: moderately mountainous with significant plains and forest, some
// hills and a small amount of swamp.
const double _oldWorldMountainFraction = 0.15;
const Map<TerrainType, double> _oldWorldNonMountainWeights = {
  TerrainType.plains: 4.0,
  TerrainType.forest: 3.0,
  TerrainType.hills: 2.0,
  TerrainType.swamp: 1.0,
};

// New World: similar defaults for Phase 1; can diverge in later rulesets.
const double _newWorldMountainFraction = 0.15;
const Map<TerrainType, double> _newWorldNonMountainWeights = {
  TerrainType.plains: 4.0,
  TerrainType.forest: 3.0,
  TerrainType.hills: 2.0,
  TerrainType.swamp: 1.0,
};

TerrainDistribution _buildDistribution(
  double mountainFraction,
  Map<TerrainType, double> nonMountainWeights,
) {
  final safeMountain = mountainFraction.clamp(0.0, 0.9);
  final weights = <TerrainType, double>{};
  var sum = 0.0;
  for (final entry in nonMountainWeights.entries) {
    final w = entry.value;
    if (w <= 0) continue;
    weights[entry.key] = w.toDouble();
    sum += w;
  }
  if (weights.isEmpty || sum <= 0) {
    return TerrainDistribution(
      mountainFraction: safeMountain,
      nonMountainFractions: const {},
    );
  }
  final scale = (1.0 - safeMountain) / sum;
  final fractions = <TerrainType, double>{};
  for (final entry in weights.entries) {
    fractions[entry.key] = entry.value * scale;
  }
  return TerrainDistribution(
    mountainFraction: safeMountain,
    nonMountainFractions: fractions,
  );
}

/// Returns the normalized terrain distribution for map generation in
/// [regionId]. Recognized ids: 'oldWorld', 'newWorld'. Unknown regions fall
/// back to the Old World distribution.
TerrainDistribution terrainDistributionForRegion(String regionId) {
  switch (regionId) {
    case 'newWorld':
      return _buildDistribution(
        _newWorldMountainFraction,
        _newWorldNonMountainWeights,
      );
    case 'oldWorld':
    default:
      return _buildDistribution(
        _oldWorldMountainFraction,
        _oldWorldNonMountainWeights,
      );
  }
}

/// Returns the list of terrain types allowed for map generation in [regionId].
/// Recognized region ids: 'oldWorld', 'newWorld'. Unknown regions fall back to [oldWorldTerrains].
List<TerrainType> allowedTerrainsForRegion(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return oldWorldTerrains;
    case 'newWorld':
      return newWorldTerrains;
    default:
      return oldWorldTerrains;
  }
}
