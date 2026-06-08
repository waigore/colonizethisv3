part of 'world_market_phase.dart';

/// Forwards the matcher's per-commodity `MarketActivity.notes` (currently
/// `bidPartialFillTreasuryInsufficient` entries from the treasury-clamp
/// pass per Refs #3115) onto the phase-built `activity` map. The matcher
/// runs in isolation, so it carries its own notes inside
/// `DealMatchResult.activityByCommodityId`; the phase handler's
/// `_buildActivity` reassembles `MarketActivity` from filled deals and
/// submitted quantities and would otherwise drop these notes. We merge
/// them in by appending. Carry-forward drop notes from `_attachDropNotes`
/// continue to coexist on the same `MarketActivity` (drop notes are
/// added later in the pipeline and replace the list, so this helper
/// runs **before** `_attachDropNotes` and uses replacement-with-existing
/// semantics to preserve any prior notes when the drop-notes attacher
/// later appends).
void _attachMatcherNotes({
  required Map<CommodityId, MarketActivity> activity,
  required DealMatchResult matchResult,
}) {
  if (matchResult.activityByCommodityId.isEmpty) return;
  for (final entry in matchResult.activityByCommodityId.entries) {
    final matcherActivity = entry.value;
    if (matcherActivity.notes.isEmpty) continue;
    final commodity = entry.key;
    final existing = activity[commodity];
    if (existing == null) {
      activity[commodity] = MarketActivity(
        notes: List<MarketActivityNote>.unmodifiable(matcherActivity.notes),
      );
    } else {
      final combined = <MarketActivityNote>[
        ...existing.notes,
        ...matcherActivity.notes,
      ];
      activity[commodity] = MarketActivity(
        totalBidQuantity: existing.totalBidQuantity,
        totalOfferQuantity: existing.totalOfferQuantity,
        filledQuantity: existing.filledQuantity,
        priceChangePercent: existing.priceChangePercent,
        deals: existing.deals,
        notes: List<MarketActivityNote>.unmodifiable(combined),
      );
    }
  }
}

/// Merges carry-forward drop notes into `activity` per commodity by
/// **appending** to any notes already attached (matcher-emitted notes
/// such as `bidPartialFillTreasuryInsufficient` are preserved per Refs
/// #3115; prior-turn notes are not re-emitted). The final list is
/// unmodifiable to keep `MarketActivity` immutable. Any `deals` already
/// attached for the commodity (from `_buildActivity`) are preserved
/// verbatim — drop notes and ledger entries coexist on the same
/// `MarketActivity` per `SPEC/program/world-market-resolution.md` § Step F
/// Activity rollup.
void _attachDropNotes({
  required Map<CommodityId, MarketActivity> activity,
  required Map<CommodityId, List<MarketActivityNote>> notesByCommodity,
}) {
  if (notesByCommodity.isEmpty) return;
  for (final entry in notesByCommodity.entries) {
    if (entry.value.isEmpty) continue;
    final commodity = entry.key;
    final existing = activity[commodity];
    if (existing == null) {
      activity[commodity] = MarketActivity(
        notes: List<MarketActivityNote>.unmodifiable(entry.value),
      );
    } else {
      final combined = <MarketActivityNote>[
        ...existing.notes,
        ...entry.value,
      ];
      activity[commodity] = MarketActivity(
        totalBidQuantity: existing.totalBidQuantity,
        totalOfferQuantity: existing.totalOfferQuantity,
        filledQuantity: existing.filledQuantity,
        priceChangePercent: existing.priceChangePercent,
        deals: existing.deals,
        notes: List<MarketActivityNote>.unmodifiable(combined),
      );
    }
  }
}

Map<CommodityId, MarketActivity> _buildActivity({
  required DealMatchResult matchResult,
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
  required Map<CommodityId, int> priorPrices,
  required Map<CommodityId, int> newPrices,
}) {
  final filledByCommodity = <CommodityId, int>{};
  final dealsByCommodity = <CommodityId, List<FilledDeal>>{};
  for (final deal in matchResult.filledDeals) {
    filledByCommodity[deal.commodityId] =
        (filledByCommodity[deal.commodityId] ?? 0) + deal.quantity;
    (dealsByCommodity[deal.commodityId] ??= <FilledDeal>[]).add(deal);
  }
  final commodityIds = <CommodityId>{
    ...newQuantitiesByCommodity.keys,
    ...filledByCommodity.keys,
  };
  final activity = <CommodityId, MarketActivity>{};
  for (final id in commodityIds) {
    final pair =
        newQuantitiesByCommodity[id] ??
        const _NewQuantityPair(bid: 0, offer: 0);
    final filled = filledByCommodity[id] ?? 0;
    final oldPrice = priorPrices[id] ?? 0;
    final newPrice = newPrices[id] ?? oldPrice;
    final percent = oldPrice > 0 ? (newPrice / oldPrice) - 1.0 : 0.0;
    final deals = dealsByCommodity[id];
    activity[id] = MarketActivity(
      totalBidQuantity: pair.bid,
      totalOfferQuantity: pair.offer,
      filledQuantity: filled,
      priceChangePercent: percent,
      deals: deals == null
          ? const <FilledDeal>[]
          : List<FilledDeal>.unmodifiable(deals),
    );
  }
  return activity;
}
