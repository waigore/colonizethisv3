/// Bid **quantity caps** and fill-time treasury **decrement** for the
/// world-market treasury clamp (Refs #3093, #3856, #4049 phase-7 split).
///
/// SPEC/game/world-market.md § Treasury budget for bids,
/// SPEC/program/world-market-resolution.md § Step C.
///
/// Pure and silent like its siblings `treasury_bid_spend.dart` and
/// `treasury_bid_available.dart`; callers import the
/// `treasury_bid_budget.dart` barrel. The matcher, suggester, and
/// validator all share this module for treasury affordability.
library;

/// Caps [bidQuantity] by [remainingCargoBudget] and affordable treasury spend.
///
/// When [unitPrice] is null or non-positive, only the cargo cap applies.
/// Used by [TradeOrderSuggester] for per-bid quantity clamping; the
/// validator enforces the same constraints sequentially per order (rule 5).
int capBidQuantityForBudgets({
  required int bidQuantity,
  required int remainingCargoBudget,
  required int remainingTreasuryBudget,
  required int? unitPrice,
}) {
  if (bidQuantity <= 0 || remainingCargoBudget <= 0) return 0;
  var cappedQty = bidQuantity < remainingCargoBudget
      ? bidQuantity
      : remainingCargoBudget;
  if (unitPrice != null && unitPrice > 0) {
    final int maxAffordable = remainingTreasuryBudget ~/ unitPrice;
    if (cappedQty > maxAffordable) {
      cappedQty = maxAffordable;
    }
  }
  return cappedQty <= 0 ? 0 : cappedQty;
}

/// Maximum bid quantity affordable at [pricePerUnit] given
/// [remainingTreasuryBudget].
///
/// When [pricePerUnit] is non-positive, returns [bidRemaining] so the
/// deal matcher preserves the missing-price free-fill contract per
/// `SPEC/program/world-market-resolution.md` § Step C (Refs #3115): the
/// treasury clamp is skipped and the other three clamps dominate.
///
/// Used by [DealMatcher] `_attemptMatch`; [capBidQuantityForBudgets]
/// applies the same semantics for integer [unitPrice] on the suggester
/// and validator paths.
int maxAffordableBidQuantity({
  required int bidRemaining,
  required double pricePerUnit,
  required int remainingTreasuryBudget,
}) {
  if (pricePerUnit <= 0.0) return bidRemaining;
  if (remainingTreasuryBudget <= 0) return 0;
  final affordable = (remainingTreasuryBudget / pricePerUnit).floor();
  return affordable < 0 ? 0 : affordable;
}

/// Decrements [remainingTreasuryByBuyerFactionId] after a successful match.
///
/// Skips the decrement on the missing-price defect path
/// (`pricePerUnit <= 0`) so free-fill behavior is preserved — no treasury
/// accounting when no notional is owed. The matcher, suggester, and
/// validator share this module for treasury affordability (Refs #3856).
void decrementTreasuryForFill({
  required String buyerFactionId,
  required int matchQty,
  required double pricePerUnit,
  required Map<String, int> remainingTreasuryByBuyerFactionId,
}) {
  if (pricePerUnit <= 0.0 || matchQty <= 0) return;
  final notional = (matchQty * pricePerUnit).round();
  final treasuryLeft = remainingTreasuryByBuyerFactionId[buyerFactionId] ?? 0;
  final next = treasuryLeft - notional;
  remainingTreasuryByBuyerFactionId[buyerFactionId] = next < 0 ? 0 : next;
}
