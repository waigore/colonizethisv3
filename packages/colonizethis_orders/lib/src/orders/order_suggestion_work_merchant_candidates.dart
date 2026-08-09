import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_suggestion_helpers.dart';

/// Tile keys that are merchant purchase-land suggestion candidates for [game]:
/// tiles in provinces not owned by any [Game.players] entry that carry a
/// resource, excluding development-exclusive tiles.
///
/// Built once per [suggestWorkOrders] pass when any merchant unit is present so
/// each merchant does not rescan ownership (Refs #2394, #3393,
/// SPEC/program/order-suggestions.md, SPEC/program/worldstate-projection.md).
///
/// Reads non-player owners from the memoised [ProvinceOwnerCache] instead of
/// walking every province (including unowned ones); the returned list is sorted
/// before return, so the pre-sort iteration order is irrelevant.
List<String> merchantPurchaseLandCandidateTileKeys({
  required Game game,
  required Map<String, Map<String, List<String>>> tileKeysByRegion,
  required Set<String> devExclusiveReservedTiles,
}) {
  final resourceByTile = game.worldState.resourceByTileKey;
  final playerIds = {for (final p in game.players) p.id};
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  final out = <String>[];
  for (final ownerId in ownerCache.ownerIds) {
    if (playerIds.contains(ownerId)) continue;
    for (final province in ownerCache.provincesOwnedBy(ownerId)) {
      final regionId = province.regionId;
      final tiles =
          tileKeysByRegion[regionId]?[province.id] ?? const <String>[];
      for (final tk in tiles) {
        if (resourceByTile[tk] == null) continue;
        if (devExclusiveReservedTiles.contains(tk)) continue;
        out.add(tk);
      }
    }
  }
  out.sort((a, b) {
    final rank = merchantPurchaseLandCandidateSortRank(
      game: game,
      tileKey: a,
    ).compareTo(merchantPurchaseLandCandidateSortRank(game: game, tileKey: b));
    if (rank != 0) return rank;
    return a.compareTo(b);
  });
  return out;
}
