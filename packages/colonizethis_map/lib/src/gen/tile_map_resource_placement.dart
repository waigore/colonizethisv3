import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_resource_cap_state.dart';

/// Probability threshold for placing a resource on an eligible land cell (Pass 7).
const double kTileMapResourcePlaceProbability = 0.4;

/// Weighted random resource placement for a cell with known [terrain].
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
