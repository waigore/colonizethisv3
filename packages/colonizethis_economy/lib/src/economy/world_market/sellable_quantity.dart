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

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup;

import '../commodity_totals.dart' show addUnits;
import 'trade_order_admission.dart' show isWorldMarketTradeableCommodity;

/// Per-commodity offer cap for [playerId] in [game].
///
/// For each non-riches commodity `c` with positive stockpile, returns:
///
///     offerCap[c] = max(0, stockpile[c] - industryAllocation[c])
///
/// `industryAllocation[c]` is the per-commodity production-input
/// consumption the resolver will draw from the player's stockpile next
/// turn. Callers pass it via [productionInputConsumptionByCommodityId];
/// the canonical projection is
/// [productionInputConsumptionByCommodityIdForAssignments] applied to
/// the player's current labour assignments (the Trade UI derives those
/// from `productionDesiredOutputProvider` →
/// [assignedRecipesFromDesiredOutput]).
///
/// When [productionInputConsumptionByCommodityId] is `null` (legacy
/// callers — AI, tests, validator backfill) the cap falls back to the
/// raw post-extraction stockpile so the contract stays
/// backwards-compatible with
/// `tradeOrderValidationContextFromGame.availableStockpileByCommodityId`.
/// Empty maps are treated identically to `null` (no reservations).
/// Negative consumption entries are clamped at zero so callers cannot
/// inflate the cap above stockpile.
///
/// Commodities whose stockpile is fully reserved (consumption ≥
/// stockpile) are omitted from the result so consumers can treat a
/// missing key as `0` (mirroring the legacy "no positive stockpile"
/// rule). Riches commodities (`gold`, `silver`, `gems`, `diamonds`,
/// `spices` per [data.richesCommodityIds]) are excluded entirely — they
/// do not trade on the world market (`SPEC/game/world-market.md` §
/// Tradeable commodities).
///
/// Returns an empty map when [playerId] does not resolve to a player.
Map<CommodityId, int> offerCapByCommodityId({
  required Game game,
  required String playerId,
  Map<CommodityId, int>? productionInputConsumptionByCommodityId,
}) {
  final player = game.playerById(playerId);
  if (player == null) return const <CommodityId, int>{};
  final reservations = productionInputConsumptionByCommodityId;
  final cap = <CommodityId, int>{};
  for (final entry in player.stockpile.quantities.entries) {
    final stockpile = entry.value;
    if (stockpile <= 0) continue;
    final commodityId = entry.key;
    if (!isWorldMarketTradeableCommodity(commodityId)) continue;
    final reserved = reservations == null
        ? 0
        : (reservations[commodityId] ?? 0).clamp(0, stockpile);
    final remaining = stockpile - reserved;
    if (remaining <= 0) continue;
    cap[commodityId] = remaining;
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
    addUnits(byCommodity, o.commodityId, o.quantity);
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
///       offerCap[c] = max(0, stockpile[c] - industryAllocation[c])
///
/// [productionInputConsumptionByCommodityId] forwards to
/// [offerCapByCommodityId] — pass the projected next-turn input
/// consumption to enforce the AC "stockpile 10 timber, industry
/// allocation reserving 3, staged offer 2 → sellable 5" per
/// `SPEC/game/world-market.md` § Per-commodity quantity cap. `null`
/// (default) preserves the legacy `industryAllocation == 0` behaviour.
///
/// Commodities with no positive stockpile (and no staged offer) are
/// absent from the returned map (consumers should treat a missing key
/// as `0`). Riches are excluded.
Map<CommodityId, int> sellableHeadroomByCommodityId({
  required Game game,
  required String playerId,
  required Orders orders,
  Map<CommodityId, int>? productionInputConsumptionByCommodityId,
}) {
  final cap = offerCapByCommodityId(
    game: game,
    playerId: playerId,
    productionInputConsumptionByCommodityId:
        productionInputConsumptionByCommodityId,
  );
  final staged = stagedOfferQuantitiesByCommodityId(
    orders: orders,
    playerId: playerId,
  );
  if (staged.isEmpty) return cap;
  final result = <CommodityId, int>{...cap};
  for (final entry in staged.entries) {
    final commodityId = entry.key;
    if (!isWorldMarketTradeableCommodity(commodityId)) continue;
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
