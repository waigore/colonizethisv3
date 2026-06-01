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
/// Scope today (#3093 — treasury bid budget slice): the helpers expose
/// the **player's raw treasury** as the bid budget plus the per-player
/// running bid-spend total computed from `currentOrdersProvider`. The
/// "treasury minus all other pending costs" reduction called out in
/// SPEC (production / recruit-train / civilian / subsidy commitments)
/// is a planned follow-up — the UI clamp landing alongside this helper
/// only subtracts the player's own already-staged bid spend, so the
/// contract is unambiguous: every staged bid's total spend
/// (`quantity × effectiveMarketPrice`) sums to at most `treasury`. The
/// validator-side enforcement is also a follow-up (see SPEC).
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
/// Today returns the player's raw `treasury` field (per
/// `Player.treasury`). The "treasury minus all other pending costs"
/// reduction described in `SPEC/game/world-market.md`
/// § Treasury budget for bids is a planned refinement: production,
/// recruit/train, civilian-work, and subsidy commitments will be
/// subtracted via a generic projector once one is available. Until
/// then, callers (UI + validator) factor in the player's own staged
/// **other** bid spend by composing this helper with
/// [stagedBidTotalSpendByPlayer], so the effective treasury budget for
/// the row currently being clamped is:
///
///     treasuryAvailableForBidsByPlayer(...) - (
///        stagedBidTotalSpendByPlayer(...) - rowPriorBidSpend
///     )
///
/// Returns `0` when [playerId] does not resolve to a player.
int treasuryAvailableForBidsByPlayer({
  required Game game,
  required String playerId,
}) {
  final player = game.playerById(playerId);
  if (player == null) return 0;
  final int treasury = player.treasury;
  return treasury < 0 ? 0 : treasury;
}
