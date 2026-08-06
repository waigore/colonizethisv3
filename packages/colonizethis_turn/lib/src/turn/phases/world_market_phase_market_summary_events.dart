import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../turn_event_sink.dart';

/// Emits [MarketTurnSummaryEvent] for GPs with last-turn fills and/or
/// carry-forward orders (Refs #4270).
void emitMarketTurnSummaryEvents({
  required List<FilledDeal> filledDeals,
  required Map<String, List<TradeOrder>> unfilledBidsByFactionId,
  required Map<String, List<TradeOrder>> unfilledOffersByFactionId,
  required Set<String> gpFactionIds,
  required int turn,
  required TurnEventSink sink,
}) {
  final spentByGpId = <String, int>{};
  final receivedByGpId = <String, int>{};
  for (final deal in filledDeals) {
    if (gpFactionIds.contains(deal.buyerFactionId)) {
      spentByGpId[deal.buyerFactionId] =
          (spentByGpId[deal.buyerFactionId] ?? 0) +
          deal.quantity * deal.pricePerUnit.floor();
    }
    if (gpFactionIds.contains(deal.sellerFactionId)) {
      receivedByGpId[deal.sellerFactionId] =
          (receivedByGpId[deal.sellerFactionId] ?? 0) +
          deal.quantity * deal.pricePerUnit.floor();
    }
  }
  final sortedGpIds = gpFactionIds.toList()..sort();
  for (final gpId in sortedGpIds) {
    final totalSpent = spentByGpId[gpId] ?? 0;
    final totalReceived = receivedByGpId[gpId] ?? 0;
    final carryForwardOrderCount =
        (unfilledBidsByFactionId[gpId]?.length ?? 0) +
        (unfilledOffersByFactionId[gpId]?.length ?? 0);
    if (totalSpent <= 0 &&
        totalReceived <= 0 &&
        carryForwardOrderCount <= 0) {
      continue;
    }
    sink.emit(
      MarketTurnSummaryEvent(
        playerId: gpId,
        totalSpent: totalSpent,
        totalReceived: totalReceived,
        carryForwardOrderCount: carryForwardOrderCount,
        turnNumber: turn,
      ),
    );
  }
}
