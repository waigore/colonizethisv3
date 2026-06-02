/// Treasury budget helpers for the world-market bid clamp on the Trade
/// Screen Market tab.
///
/// SPEC/game/world-market.md § Treasury budget for bids,
/// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.
///
/// The helpers are **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion,
/// resolver-prep, and per-frame UI paths under the 15-second
/// turn-resolution budget (`.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
///
/// Scope (#3093 — treasury bid budget slices):
///
/// * `effectiveMarketPriceForCommodityId` and `stagedBidTotalSpendByPlayer`
///   compose the per-player running bid-spend total from
///   `currentOrdersProvider`.
/// * `treasuryAvailableForBidsByPlayer` returns the player's bid budget.
///   When the caller supplies `projectedNonBidTreasuryDelta` (the signed
///   treasury change from the player's **non-bid** staged orders this turn
///   — i.e. `projectOrderEffects(orders).treasuryDelta` plus the player's
///   own running bid spend so the bid contribution is netted back out)
///   the helper subtracts the projected **deficit** from raw treasury
///   (a non-positive delta becomes a positive deficit; a positive delta
///   is ignored so net income from non-bid orders never raises the
///   budget). With the default `projectedNonBidTreasuryDelta == 0` the
///   helper falls back to the legacy "raw treasury" contract for
///   callers that don't run a projection.
///
/// Validator-side enforcement lives in `trade_order_validator.dart` (rule 5).
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart' show GamePlayerLookup;

/// Effective per-unit market price used by bid budget logic.
///
/// Reads the integer treasury-unit price stored on
/// [WorldMarketState.prices] (per `SPEC/game/world-market.md` § Price
/// discovery), falling back to
/// `resourceRules.defaultMarketPriceForCommodityId(commodityId)` when
/// the market state lacks an entry for [commodityId] (typically on
/// first-turn games before price discovery runs). Returns `null` only
/// when **neither** source has a value (manufactured commodities whose
/// first price is discovered in-game, until that follow-up lands) or
/// when [commodityId] is in [data.richesCommodityIds] (those do not
/// trade on the world market per SPEC § Tradeable commodities).
///
/// Callers should treat a `null` return as "no spend contribution"
/// (`0`) so bid budget math remains defensive against missing-data
/// states — UI consumers cannot stage a bid whose price is unknown
/// because the row's price text reads as the em-dash in that case.
int? effectiveMarketPriceForCommodityId({
  required CommodityId commodityId,
  required WorldMarketState worldMarket,
  required data.ResourceRules resourceRules,
}) {
  if (data.richesCommodityIds.contains(commodityId)) return null;
  final int? stored = worldMarket.prices[commodityId];
  if (stored != null && stored >= 0) return stored;
  return resourceRules.defaultMarketPriceForCommodityId(commodityId);
}

/// Sum of `quantity × effectiveMarketPrice` across every staged
/// `TradeOrderType.bid` for [playerId] in [orders].
///
/// Offers do not contribute to bid spend. Non-positive quantities and
/// bids on commodities with no effective price (missing in both
/// `worldMarket.prices` and the catalog default) are skipped — the UI
/// clamp would not let those bids land in the first place, but the
/// helper stays defensive in case AI or save state injects an
/// out-of-band order.
int stagedBidTotalSpendByPlayer({
  required Orders orders,
  required String playerId,
  required Game game,
  required data.ResourceRules resourceRules,
}) {
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[playerId];
  if (list == null || list.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in list) {
    if (o.type != TradeOrderType.bid) continue;
    if (o.quantity <= 0) continue;
    final int? price = effectiveMarketPriceForCommodityId(
      commodityId: o.commodityId,
      worldMarket: game.worldMarketState,
      resourceRules: resourceRules,
    );
    if (price == null) continue;
    total += o.quantity * price;
  }
  return total;
}

/// Treasury budget [playerId] may commit to bids this turn.
///
/// Returns `max(0, treasury − pendingNonBidDeficit)`, where
/// `pendingNonBidDeficit = max(0, −projectedNonBidTreasuryDelta)`. The
/// helper therefore stays **conservative**:
///
/// * A negative `projectedNonBidTreasuryDelta` (the player's non-bid
///   staged orders — build / recruit / civilian work / subsidies — would
///   net-debit treasury this turn) reduces the bid budget by exactly
///   that deficit.
/// * A non-negative `projectedNonBidTreasuryDelta` (net income or
///   neutral) leaves the bid budget at the raw `treasury` value; net
///   non-bid income never raises the budget so the clamp never lets the
///   player commit treasury they only project to earn.
///
/// `projectedNonBidTreasuryDelta` defaults to `0`, which preserves the
/// legacy "raw treasury" contract for callers that do not run a
/// projection (e.g. Widgetbook stories, isolated widget tests, and AI
/// suggestion paths that have not yet wired projection).
///
/// Callers (UI + validator) factor in the player's own staged **other**
/// bid spend by composing this helper with [stagedBidTotalSpendByPlayer],
/// so the effective treasury budget for the row currently being clamped
/// is:
///
///     treasuryAvailableForBidsByPlayer(...) - (
///        stagedBidTotalSpendByPlayer(...) - rowPriorBidSpend
///     )
///
/// The Trade Screen Market tab computes
/// `projectedNonBidTreasuryDelta` as
/// `treasurySummaryProvider.projectedDelta + stagedBidTotalSpendByPlayer(...)`
/// (`projectedDelta` is the signed `projectOrderEffects(orders)` net
/// treasury change including bids; adding the player's running bid spend
/// back reconstructs the non-bid contribution) per
/// `SPEC/ui/trade-screen.md` § Market tab — treasury bid cap. When the
/// projection is unavailable
/// (`treasurySummaryProvider.projectedDelta == null`) the UI passes `0`
/// and the helper falls back to raw treasury.
///
/// Returns `0` when [playerId] does not resolve to a player.
int treasuryAvailableForBidsByPlayer({
  required Game game,
  required String playerId,
  int projectedNonBidTreasuryDelta = 0,
}) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  final int treasury = player.treasury;
  if (treasury <= 0) return 0;
  final int pendingDeficit = projectedNonBidTreasuryDelta < 0
      ? -projectedNonBidTreasuryDelta
      : 0;
  final int budget = treasury - pendingDeficit;
  return budget < 0 ? 0 : budget;
}
