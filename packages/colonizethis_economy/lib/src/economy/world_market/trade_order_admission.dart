/// Shared world-market trade-order **admission** helpers.
///
/// SPEC/game/world-market.md § Tradeable commodities § Validation rules,
/// SPEC/program/world-market-resolution.md § Trade order validation
/// (rules 2 / 3 / 4) and § Trade order suggestion API.
///
/// These pure helpers centralize the rule-2 (riches not tradeable), rule-3
/// (mutual exclusion) and rule-4 (bid type cap admission) contracts so the
/// validator and suggester cannot drift. Before #3615 the riches predicate
/// and the bid-admission loop were copy-pasted across
/// `trade_order_validator.dart`, `trade_order_suggester.dart`,
/// `sellable_quantity.dart`, and `treasury_bid_budget.dart`.
///
/// The helpers are **pure**: deterministic for fixed inputs, silent (no
/// logger calls), and safe to call from order-submission, AI suggestion,
/// resolver-prep, and per-frame UI paths under the 15-second
/// turn-resolution budget (`.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
library;

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Whether [commodityId] may trade on the world market.
///
/// Riches commodities (`gold`, `silver`, `gems`, `diamonds`, `spices` per
/// [data.richesCommodityIds]) never trade — they are excluded from bids,
/// offers, sellable headroom, and bid-budget pricing
/// (`SPEC/game/world-market.md` § Tradeable commodities, validation rule 2).
bool isWorldMarketTradeableCommodity(CommodityId commodityId) =>
    !data.richesCommodityIds.contains(commodityId);

/// Commodity ids that appear in [proposedOrders] as **both** a bid and an
/// offer (validation rule 3 — mutual exclusion). Every order on either side
/// of such a commodity is rejected, so neither survives.
///
/// Returns a `const` empty set when there is no overlap (no bid side or no
/// offer side present), matching the legacy fast-path the validator relied
/// on.
Set<CommodityId> commoditiesWithBidAndOffer(List<TradeOrder> proposedOrders) {
  final bidCommodities = <CommodityId>{};
  final offerCommodities = <CommodityId>{};
  for (final order in proposedOrders) {
    if (order.type == TradeOrderType.bid) {
      bidCommodities.add(order.commodityId);
    } else {
      offerCommodities.add(order.commodityId);
    }
  }
  if (bidCommodities.isEmpty || offerCommodities.isEmpty) {
    return const <CommodityId>{};
  }
  return bidCommodities.intersection(offerCommodities);
}

/// Bid commodity ids admitted under [bidTypeCap], in **submission order**
/// (validation rule 4).
///
/// Bids are admitted as their commodity is first encountered scanning
/// [proposedOrders] in order, until [bidTypeCap] distinct commodities are
/// admitted. A bid is skipped (does not consume a cap slot) when it has a
/// non-positive quantity (rule 1), a riches commodity (rule 2), or a
/// commodity already excluded by mutual exclusion
/// ([mutuallyExcludedCommodityIds], rule 3). Returns a `const` empty set
/// when [bidTypeCap] is `<= 0`.
///
/// This is the order contract the **validator** enforces. The suggester
/// builds its bid set in alphabetical commodity order with net-deficit
/// logic and therefore does not call this helper — both order contracts are
/// deliberately kept distinct (see #3615 Cluster 1 risk note).
Set<CommodityId> admittedBidCommodityIdsInSubmissionOrder({
  required List<TradeOrder> proposedOrders,
  required int bidTypeCap,
  required Set<CommodityId> mutuallyExcludedCommodityIds,
}) {
  if (bidTypeCap <= 0) return const <CommodityId>{};
  final admitted = <CommodityId>{};
  for (final order in proposedOrders) {
    if (order.type != TradeOrderType.bid) continue;
    if (order.quantity <= 0) continue;
    if (!isWorldMarketTradeableCommodity(order.commodityId)) continue;
    if (mutuallyExcludedCommodityIds.contains(order.commodityId)) continue;
    if (admitted.contains(order.commodityId)) continue;
    if (admitted.length >= bidTypeCap) break;
    admitted.add(order.commodityId);
  }
  return admitted;
}
