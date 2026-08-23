import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_deal_book_reasons.dart';

/// Pure value object built from `WorldMarketState` for the player's
/// Deal Book view. Holds the four per-side row lists (filled / unfilled
/// for bids and offers) and the two treasury totals. Pulled out so the
/// rendering widget tree stays declarative and unit-testable.
class DealBookViewData {
  const DealBookViewData({
    required this.filledBids,
    required this.filledOffers,
    required this.bidReasonData,
    required this.offerReasonData,
    required this.totalSpent,
    required this.totalReceived,
  });

  factory DealBookViewData.build({
    required WorldMarketState worldMarket,
    required String playerId,
  }) {
    final List<FilledDeal> bids = <FilledDeal>[];
    final List<FilledDeal> offers = <FilledDeal>[];
    for (final MarketActivity activity in worldMarket.lastTurnActivity.values) {
      for (final FilledDeal deal in activity.deals) {
        if (deal.buyerFactionId == playerId) bids.add(deal);
        if (deal.sellerFactionId == playerId) offers.add(deal);
      }
    }
    int spent = 0;
    for (final FilledDeal deal in bids) {
      spent += deal.quantity * deal.pricePerUnit.floor();
    }
    int received = 0;
    for (final FilledDeal deal in offers) {
      received += deal.quantity * deal.pricePerUnit.floor();
    }
    final List<TradeOrder> unfilledBids =
        worldMarket.carryForwardBidsByFactionId[playerId] ??
        const <TradeOrder>[];
    final List<TradeOrder> unfilledOffers =
        worldMarket.carryForwardOffersByFactionId[playerId] ??
        const <TradeOrder>[];
    return DealBookViewData(
      filledBids: List<FilledDeal>.unmodifiable(bids),
      filledOffers: List<FilledDeal>.unmodifiable(offers),
      bidReasonData: DealBookReasonBuilder.buildBids(
        worldMarket: worldMarket,
        playerId: playerId,
        unfilledBids: unfilledBids,
      ),
      offerReasonData: DealBookReasonBuilder.buildOffers(
        worldMarket: worldMarket,
        playerId: playerId,
        unfilledOffers: unfilledOffers,
      ),
      totalSpent: spent,
      totalReceived: received,
    );
  }

  final List<FilledDeal> filledBids;
  final List<FilledDeal> filledOffers;
  final DealBookPanelReasonData bidReasonData;
  final DealBookPanelReasonData offerReasonData;
  final int totalSpent;
  final int totalReceived;
}
