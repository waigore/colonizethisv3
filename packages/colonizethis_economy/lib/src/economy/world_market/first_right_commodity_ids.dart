/// Purchased-tile commodity lookup for Market first-right cues (Refs #4226).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'purchased_tile_index.dart';

/// Returns the set of commodity ids for which [playerId] holds a still-valid
/// purchased-tile first-right attribution.
///
/// Each attribution's [PurchasedTileAttribution.tileKey] is mapped through
/// [Game.worldState.resourceAtTile]; [Resource.name] is the canonical commodity
/// id. Duplicate commodities are deduplicated.
Set<CommodityId> firstRightCommodityIdsForPlayer(Game game, String playerId) {
  final index = PurchasedTileIndex.fromGame(game);
  if (index.isEmpty) return const <CommodityId>{};

  final result = <CommodityId>{};
  for (final attribution in index.attributions) {
    if (attribution.owningGpId != playerId) continue;
    final resourceId = game.worldState.resourceAtTile(attribution.tileKey);
    if (resourceId == null || resourceId.isEmpty) continue;
    result.add(resourceId);
  }
  return Set<CommodityId>.unmodifiable(result);
}
