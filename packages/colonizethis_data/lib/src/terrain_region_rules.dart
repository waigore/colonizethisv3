/// Allowed terrain types per region. SPEC/program/tile-map-gen-resources.md, SPEC/game/resource-terrain-region-rules.md.
/// Canonical source: Imperialism II Terrain and Development table (OW-only, NW-only, Both).
/// Phase 1: minimal mapping from current TerrainType enum; extend when terrain enum is expanded.

import 'terrain_type.dart';

/// Terrains allowed in the Old World (OW-only + Both from canonical table).
/// Phase 1: all current types; extend when adding e.g. Grain Farm, Open Range.
const List<TerrainType> oldWorldTerrains = [
  TerrainType.plains,
  TerrainType.hardwoodForest,
  TerrainType.scrubForest,
  TerrainType.hills,
  TerrainType.mountain,
  TerrainType.swamp,
];

/// Terrains allowed in the New World (NW-only + Both from canonical table).
/// Includes desert (diamonds). SPEC/game/resource-terrain-region-rules.md.
const List<TerrainType> newWorldTerrains = [
  TerrainType.plains,
  TerrainType.hardwoodForest,
  TerrainType.scrubForest,
  TerrainType.hills,
  TerrainType.mountain,
  TerrainType.swamp,
  TerrainType.desert,
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
//
// Forest is split into hardwood (rare, weight 0.3) and scrub (common, weight
// 1.2) at a 1:4 ratio; total forest weight is halved (3.0 -> 1.5) and the freed
// 1.5 weight is added to plains (4.0 -> 5.5). See issue #3573 R6.
const double _oldWorldMountainFraction = 0.15;
const Map<TerrainType, double> _oldWorldNonMountainWeights = {
  TerrainType.plains: 5.5,
  TerrainType.hardwoodForest: 0.3,
  TerrainType.scrubForest: 1.2,
  TerrainType.hills: 2.0,
  TerrainType.swamp: 1.0,
};

// New World: includes desert (diamonds). SPEC/game/resource-terrain-region-rules.md.
// Same hardwood/scrub forest split and plains reweighting as the Old World
// (issue #3573 R6).
const double _newWorldMountainFraction = 0.15;
const Map<TerrainType, double> _newWorldNonMountainWeights = {
  TerrainType.plains: 5.5,
  TerrainType.hardwoodForest: 0.3,
  TerrainType.scrubForest: 1.2,
  TerrainType.hills: 2.0,
  TerrainType.swamp: 1.0,
  TerrainType.desert: 1.0,
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
