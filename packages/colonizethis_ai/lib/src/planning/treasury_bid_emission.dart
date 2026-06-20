part of 'treasury_planner.dart';

// Bid prioritization, cargo/treasury-budget clamping, and tier alignment for
// the treasury planner (Refs #3122 + #2924 F12/F16), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Behaviour-preserving move: same library scope (this is a `part of` the
// treasury-planner library), so imports, shared helpers, and visibility are
// unchanged.

List<TradeOrder> _prioritizedBids({
  required List<TradeOrder> rawBids,
  required Map<CommodityId, int> need,
  required int bidTypeCap,
  required int tradeCargoCapacity,
  required int offerPriority,
  required bool alignBidPriorityWithUrgentOffers,
  required int treasuryBudgetForBids,
  required WorldMarketState worldMarketState,
  required ResourceRules resourceRules,
  int? forceBidPriority,
  CommodityId? preferCommodityId,
}) {
  if (rawBids.isEmpty || bidTypeCap <= 0 || tradeCargoCapacity <= 0) {
    return const <TradeOrder>[];
  }
  final byCommodity = <CommodityId, TradeOrder>{
    for (final bid in rawBids) bid.commodityId: bid,
  };
  final orderedIds = need.keys.toList(growable: false)
    ..sort((a, b) {
      if (preferCommodityId != null) {
        if (a == preferCommodityId) return -1;
        if (b == preferCommodityId) return 1;
      }
      final priorityCmp =
          _bidPriorityForCommodity(a).compareTo(_bidPriorityForCommodity(b));
      if (priorityCmp != 0) return priorityCmp;
      return a.compareTo(b);
    });

  final result = <TradeOrder>[];
  var remainingCargo = tradeCargoCapacity;
  var remainingTreasuryBudget =
      treasuryBudgetForBids < 0 ? 0 : treasuryBudgetForBids;
  var admitted = 0;
  for (final commodityId in orderedIds) {
    if (admitted >= bidTypeCap) break;
    if (remainingCargo <= 0) break;
    final bid = byCommodity[commodityId];
    if (bid == null) continue;
    final cargoClampedQty = bid.quantity < remainingCargo
        ? bid.quantity
        : remainingCargo;
    if (cargoClampedQty <= 0) continue;
    // Refs #3122: clamp every bid to the running treasury budget so the
    // matcher (#3115) does not have to truncate to zero/near-zero fills.
    // When the commodity has no effective price (manufactured commodity
    // before in-game price discovery seeds a price), fall back to the
    // cargo-clamped quantity; the matcher applies its own per-tier
    // accounting if such a bid ever clears.
    final pricePerUnit = effectiveMarketPriceForCommodityId(
      commodityId: commodityId,
      worldMarket: worldMarketState,
      resourceRules: resourceRules,
    );
    int cappedQty;
    if (pricePerUnit == null) {
      cappedQty = cargoClampedQty;
    } else if (pricePerUnit <= 0) {
      cappedQty = cargoClampedQty;
    } else {
      final maxAffordable = remainingTreasuryBudget ~/ pricePerUnit;
      cappedQty = cargoClampedQty < maxAffordable
          ? cargoClampedQty
          : maxAffordable;
    }
    if (cappedQty <= 0) continue;
    result.add(
      bid.copyWith(
        quantity: cappedQty,
        priority: forceBidPriority ??
            (alignBidPriorityWithUrgentOffers
                ? offerPriority
                : _bidPriorityForCommodity(commodityId)),
      ),
    );
    remainingCargo -= cappedQty;
    if (pricePerUnit != null && pricePerUnit > 0) {
      remainingTreasuryBudget -= cappedQty * pricePerUnit;
    }
    admitted += 1;
  }
  return result;
}
