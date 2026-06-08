part of 'full_ai_civilian_work_selection.dart';

// Old World feedstock-tile ownership predicates and the feedstock-tile
// acquisition residual for the below-quota zero-NW lock-recovery seller /
// supplier roles (Refs #2847 § H8-extraction). The feedstock-extraction
// resource-id gates these build on now live in the `orders` domain
// (`orders/feedstock_extraction_targets.dart`) so the one-way orders↔ai
// dependency direction holds (Refs #3290). Split out of
// full_ai_civilian_work_selection.dart by concern to keep each library file
// at or below the repo non-comment line limit; shares the parent library's
// private scope via `part`.

/// True iff [playerId] owns at least one province tile hosting a resource in
/// [feedstockIds] at **any** improvement level — the inverse precondition of
/// the feedstock-tile acquisition residual
/// ([sellerNeedsImprovementInputFeedstockTileAcquisition]). An already-improved
/// feedstock tile still counts as owned (the seller has the tile; it needs no
/// acquisition). Province ownership is derived from the tile key
/// (`Unit.provinceIdFromTileKey`) so the scan works from
/// `WorldState.resourceByTileKey` alone. Read-only and deterministic; Refs #2847
/// § H8-extraction seller feedstock-tile acquisition residual.
bool _ownsFeedstockResourceTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
    if (province == null || province.ownerId != playerId) continue;
    return true;
  }
  return false;
}

/// True iff the below-quota zero-NW lock-recovery seller [playerId] needs a
/// producible level-0 `build_improvement` input (`lumber` / `castIron`) it must
/// produce domestically, but owns **no** province tile hosting **any** of that
/// input's feedstock resource — at **any** improvement level — so it cannot be
/// routed to extract the feedstock and must instead **acquire** a feedstock tile
/// (Refs #2847 § H8-extraction seller feedstock-tile acquisition residual).
///
/// Detection contract for the residual disclosed in [economy-planner.md]
/// (`SPEC/ai/economy-planner.md` § Residual feedstock-tile dependency and
/// § Seller improvement-input feedstock extraction): the seller-side routing
/// gate `sellerImprovementInputFeedstockExtractionResourceIds` only
/// re-prioritises an **existing** owned unimproved feedstock tile — it acquires
/// no tile, so a failing GP whose Old World territory contains no `timber` tile
/// still cannot source `lumber` domestically and the turn-100 conquest gate
/// stays open on that axis. This predicate isolates exactly that class so an
/// acquisition slice can gate on it deterministically.
///
/// Returns `true` only when both hold:
///   * the seller's improvement-input feedstock **demand**
///     (`sellerImprovementInputFeedstockResourceIds`) is non-empty — i.e. the
///     improvement-cost gate is active and the seller is short of a producible
///     input; **and**
///   * the seller owns **no** tile hosting any feedstock resource in that demand
///     set ([_ownsFeedstockResourceTile] is `false`).
///
/// Returns `false` for every player whose improvement-input gate is inactive
/// (at or above the conquest quota, owns a regiment, owns a New World province,
/// or already holds the inputs) — so the +6 Old World conquest baseline GPs are
/// never flagged — and for a seller that already owns a feedstock tile, whether
/// **unimproved** (the routing gate handles it) or **improved** (a distinct
/// improved-tile residual, not feedstock-tile acquisition).
///
/// Pure and deterministic over `(game, playerId)` and the static
/// `ProductionRecipesCatalog`; performs no I/O and no logging.
bool sellerNeedsImprovementInputFeedstockTileAcquisition(
  Game game,
  String playerId,
) {
  final feedstock = sellerImprovementInputFeedstockResourceIds(game, playerId);
  if (feedstock.isEmpty) return false;
  return !_ownsFeedstockResourceTile(game, playerId, feedstock);
}
