part of 'world_market_phase.dart';

class _NewQuantityPair {
  const _NewQuantityPair({required this.bid, required this.offer});
  final int bid;
  final int offer;
}

/// Aggregates per-commodity the filled portion of this turn's
/// newly-submitted bids attributable to each faction (Refs #3115). The
/// matcher consumes newly-submitted bids at the head of each faction's
/// merged bid list (see `_mergeOrdersByFaction`), so the filled units
/// served to any given faction are allocated to its newly-submitted bids
/// first; carry-forward bids only receive fills once newly-submitted
/// bids are exhausted. Therefore:
///
///     filledNewBids[f, c] = min(submittedNewBids[f, c], filledTotal[f, c])
///
/// where `filledTotal[f, c]` is the sum of `FilledDeal.quantity` whose
/// `buyerFactionId == f` and `commodityId == c`. Summing across factions
/// yields `totalBid_new[c]` per
/// `SPEC/program/world-market-resolution.md` § Step E.
Map<CommodityId, int> _aggregateFilledNewBidsByCommodity({
  required Map<String, List<TradeOrder>> newBidsByFactionId,
  required List<FilledDeal> filledDeals,
}) {
  if (newBidsByFactionId.isEmpty || filledDeals.isEmpty) {
    return const <CommodityId, int>{};
  }
  final submittedNewByBuyerCommodity = <String, Map<CommodityId, int>>{};
  for (final entry in newBidsByFactionId.entries) {
    final byCommodity = <CommodityId, int>{};
    for (final order in entry.value) {
      byCommodity[order.commodityId] =
          (byCommodity[order.commodityId] ?? 0) + order.quantity;
    }
    if (byCommodity.isNotEmpty) {
      submittedNewByBuyerCommodity[entry.key] = byCommodity;
    }
  }
  if (submittedNewByBuyerCommodity.isEmpty) {
    return const <CommodityId, int>{};
  }
  final filledByBuyerCommodity = <String, Map<CommodityId, int>>{};
  for (final deal in filledDeals) {
    final byCommodity = filledByBuyerCommodity.putIfAbsent(
      deal.buyerFactionId,
      () => <CommodityId, int>{},
    );
    byCommodity[deal.commodityId] =
        (byCommodity[deal.commodityId] ?? 0) + deal.quantity;
  }
  final result = <CommodityId, int>{};
  for (final entry in submittedNewByBuyerCommodity.entries) {
    final buyerFilled = filledByBuyerCommodity[entry.key];
    if (buyerFilled == null) continue;
    for (final commodityEntry in entry.value.entries) {
      final submitted = commodityEntry.value;
      final filled = buyerFilled[commodityEntry.key] ?? 0;
      final attributable = filled <= submitted ? filled : submitted;
      if (attributable <= 0) continue;
      result[commodityEntry.key] =
          (result[commodityEntry.key] ?? 0) + attributable;
    }
  }
  return result;
}

/// Builds the per-commodity price-discovery aggregation pair used by
/// `_computeNextPrices` and `_buildActivity` (Refs #3115). Offers report
/// the submitted quantity unchanged; bids report only the filled portion
/// of newly-submitted bids per
/// `SPEC/program/world-market-resolution.md` § Step E.
Map<CommodityId, _NewQuantityPair> _buildPriceDiscoveryPairs({
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
  required Map<CommodityId, int> filledNewBidsByCommodity,
}) {
  if (newQuantitiesByCommodity.isEmpty) {
    return const <CommodityId, _NewQuantityPair>{};
  }
  final result = <CommodityId, _NewQuantityPair>{};
  for (final entry in newQuantitiesByCommodity.entries) {
    final filledBid = filledNewBidsByCommodity[entry.key] ?? 0;
    result[entry.key] = _NewQuantityPair(
      bid: filledBid,
      offer: entry.value.offer,
    );
  }
  return result;
}

Map<CommodityId, _NewQuantityPair> _aggregateNewQuantitiesPerCommodity({
  required Map<String, List<TradeOrder>> newOffersByFactionId,
  required Map<String, List<TradeOrder>> newBidsByFactionId,
}) {
  final bid = <CommodityId, int>{};
  final offer = <CommodityId, int>{};
  for (final list in newOffersByFactionId.values) {
    for (final order in list) {
      offer[order.commodityId] =
          (offer[order.commodityId] ?? 0) + order.quantity;
    }
  }
  for (final list in newBidsByFactionId.values) {
    for (final order in list) {
      bid[order.commodityId] = (bid[order.commodityId] ?? 0) + order.quantity;
    }
  }
  final all = <CommodityId>{...offer.keys, ...bid.keys};
  final result = <CommodityId, _NewQuantityPair>{};
  for (final id in all) {
    result[id] = _NewQuantityPair(bid: bid[id] ?? 0, offer: offer[id] ?? 0);
  }
  return result;
}

/// Computes the next-turn integer prices for every commodity with newly-
/// submitted activity this turn. Carries the prior integer price forward
/// for any commodity that did not see activity (preserves the existing
/// behavior of `_computeNextPrices` that returned a full prices map).
///
/// `SPEC/game/world-market.md` § Price discovery requires the persisted
/// price to be the integer floor of `PriceDiscovery.computeNextPrice`; the
/// floating-point math is retained internally for the supply/demand delta
/// but the world-market phase floors the result before storing it on
/// `WorldMarketState.prices`. Floor is non-negative because
/// `PriceDiscovery.computeNextPrice` returns a non-negative double (the
/// price floor of `basePrice * 0.30` is non-negative).
Map<CommodityId, int> _computeNextPrices({
  required Map<CommodityId, int> priorPrices,
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
}) {
  final out = <CommodityId, int>{...priorPrices};
  for (final entry in newQuantitiesByCommodity.entries) {
    final basePrice = _basePriceForCommodityId(entry.key);
    final oldPrice = priorPrices[entry.key]?.toDouble() ?? basePrice.toDouble();
    final next = PriceDiscovery.computeNextPrice((
      oldPrice: oldPrice,
      basePrice: basePrice,
      newBidQuantity: entry.value.bid,
      newOfferQuantity: entry.value.offer,
    ));
    out[entry.key] = next.floor();
  }
  return out;
}

/// Resolves a commodity's integer base price from `ResourceRules.defaultRules`.
///
/// The price floor (`basePrice * priceFloorRatio`) anchors at the original
/// starting price per `SPEC/game/world-market.md` § Price discovery.
/// Manufactured commodities are not yet enumerated in
/// `ResourceRules.defaultMarketPrice` (raw resources only); for those, the
/// prior `WorldMarketState.prices` entry already encodes the seed value, so
/// returning `0` keeps the floor inert without re-clamping mid-game prices.
int _basePriceForCommodityId(CommodityId id) {
  final priceMap = ResourceRules.defaultRules.defaultMarketPrice;
  for (final entry in priceMap.entries) {
    if (entry.key.name == id) return entry.value;
  }
  return 0;
}
