import 'planning_imports.dart';
import 'treasury_planner_constants.dart';

/// Speculative-bid pass for affluent GPs (Refs #2924 F10). Mutates [need] in
/// place with synthetic stockpile-target deficits for non-riches commodities
/// the F1–F5 path did not already speak for. Adds **at most one** entry per
/// invocation so bids are concentrated on the commodity most likely to clear
/// into a real deal (treasury only redistributes when matching offers exist).
/// Selection order:
/// 1. Commodities with prior-turn `MarketActivity.totalOfferQuantity > 0`
///    (descending offer volume, then alphabetical) — proven liquidity.
/// 2. Otherwise food commodities (deterministic alphabetical) — minor/tribe
///    auto-offers reliably surface food on the next world-market phase.
/// 3. Otherwise the alphabetical first non-riches commodity that meets the
///    target gap (deterministic fallback for an empty market — pure
///    determinism for tests that do not seed `lastTurnActivity`).
/// Skips:
/// - riches commodities (excluded from world-market trade),
/// - commodities already in [need] (F1–F5 deficit path owns them),
/// - commodities already in [available] (mutual-exclusion preserved),
/// - commodities whose projected stockpile already meets
///   [kSpeculativeBidStockpileTarget] (no positive target),
/// - commodities whose remaining target is already covered by a carry-forward
///   bid residual ([carryForwardBids]).
void addSpeculativeBidNeeds({
  required Map<CommodityId, int> need,
  required Map<CommodityId, int> available,
  required Stockpile projected,
  required Map<CommodityId, int> carryForwardBids,
  required WorldMarketState state,
}) {
  bool eligible(CommodityId id) {
    if (richesCommodityIds.contains(id)) return false;
    if (need.containsKey(id)) return false;
    if (available.containsKey(id)) return false;
    final projectedQty = projected.quantityOf(id);
    final carryQty = carryForwardBids[id] ?? 0;
    return kSpeculativeBidStockpileTarget - projectedQty - carryQty > 0;
  }

  int gapFor(CommodityId id) {
    final projectedQty = projected.quantityOf(id);
    final carryQty = carryForwardBids[id] ?? 0;
    return kSpeculativeBidStockpileTarget - projectedQty - carryQty;
  }

  int offerVolumeFor(CommodityId id) =>
      state.lastTurnActivity[id]?.totalOfferQuantity ?? 0;

  final eligibleIds = CommodityCatalog.all
      .map((c) => c.id)
      .where(eligible)
      .toList(growable: false);
  if (eligibleIds.isEmpty) return;

  CommodityId pick;
  final liquid = eligibleIds.where((id) => offerVolumeFor(id) > 0).toList()
    ..sort((a, b) {
      final volCmp = offerVolumeFor(b).compareTo(offerVolumeFor(a));
      if (volCmp != 0) return volCmp;
      return a.compareTo(b);
    });
  if (liquid.isNotEmpty) {
    pick = liquid.first;
  } else {
    final foods = eligibleIds
        .where(
          (id) => CommodityCatalog.byId[id]?.category == CommodityCategory.food,
        )
        .toList()
      ..sort();
    if (foods.isNotEmpty) {
      pick = foods.first;
    } else {
      final sortedEligible = [...eligibleIds]..sort();
      pick = sortedEligible.first;
    }
  }
  need[pick] = gapFor(pick);
}
