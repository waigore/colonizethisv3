import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_resource_cap_state.dart';

/// Probability threshold for placing a resource on an eligible land cell (Pass 7).
const double kTileMapResourcePlaceProbability = 0.4;

/// Probability that a guaranteed New-World hardwood-forest cell receives `furs`
/// rather than `timber` (R3.4, issue #3573). Every NW hardwood cell always
/// receives one of the two. SPEC/program/tile-map-gen-resources.md.
const double kHardwoodForestNewWorldFursProbability = 0.7;

/// The guaranteed resource placed on a forest [terrain] cell (R3, issue #3573):
/// scrub forest → always `timber`; hardwood forest → `timber` in the Old World,
/// and a [kHardwoodForestNewWorldFursProbability] furs / remainder timber split
/// in the New World (where `furs` is region-allowed on hardwood).
/// SPEC/program/tile-map-gen-resources.md.
Resource guaranteedForestResource({
  required TerrainType terrain,
  required String mapRegionId,
  required ResourceRules rules,
  required Random rnd,
}) {
  if (terrain == TerrainType.scrubForest) {
    return Resource.timber;
  }
  final fursAllowed =
      rules.isAllowedInRegion(Resource.furs, mapRegionId) &&
      rules.isAllowedOnTerrain(Resource.furs, terrain);
  if (fursAllowed && rnd.nextDouble() < kHardwoodForestNewWorldFursProbability) {
    return Resource.furs;
  }
  return Resource.timber;
}

/// Weighted random resource placement for a cell with known [terrain].
///
/// Forest terrain (hardwood and scrub) is a special case (R3, issue #3573): the
/// cell **always** receives a resource ([guaranteedForestResource]), bypassing
/// the [kTileMapResourcePlaceProbability] gate. Guaranteed forest placements are
/// excluded from [capState] accounting (they are never recorded), mirroring the
/// bootstrap-grain exclusion, so they neither raise nor are suppressed by the
/// multi-region cap. SPEC/program/tile-map-gen-resources.md.
///
/// Returns `true` when a resource was written to [resourceGrid].
bool tryPlaceWeightedResourceAtCell({
  required List<List<Resource?>> resourceGrid,
  required int x,
  required int y,
  required TerrainType terrain,
  required String mapRegionId,
  required ResourceRules rules,
  required Random rnd,
  MultiRegionCapState? capState,
}) {
  if (isForestTerrain(terrain)) {
    resourceGrid[y][x] = guaranteedForestResource(
      terrain: terrain,
      mapRegionId: mapRegionId,
      rules: rules,
      rnd: rnd,
    );
    return true;
  }
  var allowed = Resource.values
      .where(
        (r) =>
            rules.isAllowedInRegion(r, mapRegionId) &&
            rules.isAllowedOnTerrain(r, terrain),
      )
      .toList();
  if (allowed.isEmpty) return false;
  if (capState != null && capState.shouldRestrictToRegionOnly(allowed)) {
    allowed = capState.filterToRegionOnly(allowed);
    if (allowed.isEmpty) return false;
  }
  if (rnd.nextDouble() > kTileMapResourcePlaceProbability) return false;
  final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
  final sum = weights.reduce((a, b) => a + b);
  var roll = rnd.nextDouble() * sum;
  for (var i = 0; i < allowed.length; i++) {
    roll -= weights[i];
    if (roll > 0) continue;
    final placed = allowed[i];
    resourceGrid[y][x] = placed;
    capState?.record(placed);
    return true;
  }
  return false;
}
