part of 'world_market_phase.dart';

/// Result of [_validateCarryForwards]: surviving carry-forward orders that
/// pass the start-of-phase stockpile (offers) and trade cargo capacity
/// (bids) re-checks, plus the [MarketActivityNote] entries the phase
/// should attach to per-commodity `MarketActivity` for dropped orders.
class _CarryForwardValidationResult {
  const _CarryForwardValidationResult({
    required this.validOffersByFactionId,
    required this.validBidsByFactionId,
    required this.dropNotesByCommodity,
  });

  final Map<String, List<TradeOrder>> validOffersByFactionId;
  final Map<String, List<TradeOrder>> validBidsByFactionId;
  final Map<CommodityId, List<MarketActivityNote>> dropNotesByCommodity;
}

/// Re-validates carry-forward orders against the submitter's current
/// stockpile (offers) and trade cargo capacity (bids), implementing the
/// drop branch of `SPEC/game/world-market.md` § Order persistence and
/// `SPEC/program/world-market-resolution.md` § Step A Gather (A.3).
///
/// Per faction the carry-forwards are walked in original list order so
/// that earlier orders (higher submission priority) consume the available
/// stockpile/capacity first; later orders that would push the cumulative
/// kept total above the constraint are dropped and recorded as a
/// [MarketActivityNote]. Factions that are not present in
/// [stockpileByFactionId] / [tradeCapacityByFactionId] (e.g. minor/tribe
/// sellers whose offers persist through purchased-tile plumbing) keep all
/// their carry-forward orders unchanged — there is no GP-side constraint
/// to enforce on them in this slice.
_CarryForwardValidationResult _validateCarryForwards({
  required Map<String, List<TradeOrder>> carryForwardOffersByFactionId,
  required Map<String, List<TradeOrder>> carryForwardBidsByFactionId,
  required Map<String, Stockpile> stockpileByFactionId,
  required Map<String, int> tradeCapacityByFactionId,
}) {
  final validOffers = <String, List<TradeOrder>>{};
  final validBids = <String, List<TradeOrder>>{};
  final notesByCommodity = <CommodityId, List<MarketActivityNote>>{};

  void recordNote(MarketActivityNote note) {
    final list = notesByCommodity.putIfAbsent(
      note.commodityId,
      () => <MarketActivityNote>[],
    );
    list.add(note);
  }

  for (final entry in carryForwardOffersByFactionId.entries) {
    final factionId = entry.key;
    final orders = entry.value;
    if (orders.isEmpty) continue;
    final stockpile = stockpileByFactionId[factionId];
    if (stockpile == null) {
      validOffers[factionId] = List<TradeOrder>.from(orders);
      continue;
    }
    final cumulativeByCommodity = <CommodityId, int>{};
    final kept = <TradeOrder>[];
    for (final order in orders) {
      final available = stockpile.quantityOf(order.commodityId);
      final alreadyKept = cumulativeByCommodity[order.commodityId] ?? 0;
      if (alreadyKept + order.quantity <= available) {
        cumulativeByCommodity[order.commodityId] = alreadyKept + order.quantity;
        kept.add(order);
      } else {
        recordNote(
          MarketActivityNote(
            kind: MarketActivityNoteKind
                .carryForwardDroppedStockpileInsufficient,
            factionId: factionId,
            commodityId: order.commodityId,
            quantity: order.quantity,
          ),
        );
      }
    }
    if (kept.isNotEmpty) validOffers[factionId] = kept;
  }

  for (final entry in carryForwardBidsByFactionId.entries) {
    final factionId = entry.key;
    final orders = entry.value;
    if (orders.isEmpty) continue;
    final capacity = tradeCapacityByFactionId[factionId];
    if (capacity == null) {
      validBids[factionId] = List<TradeOrder>.from(orders);
      continue;
    }
    int cumulative = 0;
    final kept = <TradeOrder>[];
    for (final order in orders) {
      if (cumulative + order.quantity <= capacity) {
        cumulative += order.quantity;
        kept.add(order);
      } else {
        recordNote(
          MarketActivityNote(
            kind:
                MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
            factionId: factionId,
            commodityId: order.commodityId,
            quantity: order.quantity,
          ),
        );
      }
    }
    if (kept.isNotEmpty) validBids[factionId] = kept;
  }

  return _CarryForwardValidationResult(
    validOffersByFactionId: validOffers,
    validBidsByFactionId: validBids,
    dropNotesByCommodity: notesByCommodity,
  );
}
