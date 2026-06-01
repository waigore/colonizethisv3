/// Per-commodity *offer cap* + staged-offer aggregation helpers for the
/// world-market trade UI (Trade Screen Market tab `(N)` display + offer
/// quantity clamp), AI suggestion code, and validator pre-pass.
///
/// SPEC/game/world-market.md § Trade orders § Validation rules,
/// SPEC/ui/trade-screen.md § Market tab — Sellable + offer clamp.
///
/// The helpers are **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion,
/// resolver-prep, and per-frame UI paths under the 15-second
/// turn-resolution budget (`.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart' show GamePlayerLookup;

/// Per-commodity offer cap for [playerId] in [game].
///
/// For each non-riches commodity `c` with positive stockpile, returns:
///
///     offerCap[c] = max(0, stockpile[c] - industryAllocation[c])
///
/// Today `industryAllocation[c]` is treated as `0`: the AI's
/// `treasury_planner` projects post-production stockpile via
/// `_projectStockpileAfterProduction` (internal helper), but no
/// generic logic-level projector is exposed for UI/validator
/// consumers yet. Wiring the production-input projection is a known
/// follow-up tracked under #3093 (sellable clamp slice). Until then,
/// `offerCap` equals the raw post-extraction stockpile for non-riches
/// commodities, which matches the pre-existing
/// `tradeOrderValidationContextFromGame.availableStockpileByCommodityId`
/// behaviour.
///
/// Riches commodities (`gold`, `silver`, `gems`, `diamonds`, `spices`
/// per [data.richesCommodityIds]) are excluded — they do not trade on
/// the world market (`SPEC/game/world-market.md` § Tradeable
/// commodities).
///
/// Returns an empty map when [playerId] does not resolve to a player.
Map<CommodityId, int> offerCapByCommodityId({
  required Game game,
  required String playerId,
}) {
  final player = game.playerById(playerId);
  if (player == null) return const <CommodityId, int>{};
  final cap = <CommodityId, int>{};
  for (final entry in player.stockpile.quantities.entries) {
    if (entry.value <= 0) continue;
    if (data.richesCommodityIds.contains(entry.key)) continue;
    cap[entry.key] = entry.value;
  }
  return cap;
}

/// Sum of staged `TradeOrderType.offer` quantities per commodity for
/// [playerId] in [orders].
///
/// Mutual exclusion guarantees at most one staged `TradeOrder` per
/// `(playerId, commodityId)` pair
/// (`SPEC/game/world-market.md` § Trade orders), so each commodity in
/// the returned map maps to a single staged offer's quantity. Bids,
/// removed entries, and non-positive quantities are excluded.
Map<CommodityId, int> stagedOfferQuantitiesByCommodityId({
  required Orders orders,
  required String playerId,
}) {
  final list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null || list.isEmpty) {
    return const <CommodityId, int>{};
  }
  final byCommodity = <CommodityId, int>{};
  for (final TradeOrder o in list) {
    if (o.type != TradeOrderType.offer) continue;
    if (o.quantity <= 0) continue;
    byCommodity[o.commodityId] = (byCommodity[o.commodityId] ?? 0) + o.quantity;
  }
  return byCommodity;
}

/// Per-commodity sellable headroom remaining for [playerId] after
/// subtracting the player's already-staged offer quantities in [orders]
/// from [offerCapByCommodityId].
///
/// Mirrors the `(N)` text rendered next to commodity names on the
/// Trade Market tab. `N` is the number of additional units the player
/// can grow the row's offer by before saturating the per-commodity
/// offer cap.
///
/// For each non-riches commodity `c`:
///
///     sellable[c] = max(0, offerCap[c] - stagedOffer[c])
///
/// Commodities with no positive stockpile (and no staged offer) are
/// absent from the returned map (consumers should treat a missing key
/// as `0`). Riches are excluded.
Map<CommodityId, int> sellableHeadroomByCommodityId({
  required Game game,
  required String playerId,
  required Orders orders,
}) {
  final cap = offerCapByCommodityId(game: game, playerId: playerId);
  final staged = stagedOfferQuantitiesByCommodityId(
    orders: orders,
    playerId: playerId,
  );
  if (staged.isEmpty) return cap;
  final result = <CommodityId, int>{...cap};
  for (final entry in staged.entries) {
    final commodityId = entry.key;
    if (data.richesCommodityIds.contains(commodityId)) continue;
    final capValue = result[commodityId] ?? 0;
    final headroom = capValue - entry.value;
    if (headroom <= 0) {
      result.remove(commodityId);
    } else {
      result[commodityId] = headroom;
    }
  }
  return result;
}
