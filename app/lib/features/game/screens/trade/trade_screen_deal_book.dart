// Deal Book tab body for the World Market Trade screen
// (Refs #2993 E6, split out from `trade_screen.dart` to keep the
// host file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`).
//
// All classes here are library-private (`_DealBook*`) and consumed
// only by `TradeScreenTabsBody` inside the parent library.

/// Live Deal Book tab body (Refs #2993 E6). Renders the player's
/// previous-turn buying and selling activity in a two-panel ledger
/// sourced from `Game.worldMarketState.lastTurnActivity[*].deals`
/// (filtered by `buyerFactionId` / `sellerFactionId`) and
/// `carryForward{Bids,Offers}ByFactionId[playerId]`.
///
/// Layout collapses to a single stacked column below
/// `TradeScreenDealBookKeys.dealBookTwoPanelMinWidth` so the 320 dp minimum viewport
/// stays overflow-safe (`SPEC/ui/mobile-adaptation.md` § 7). On wider
/// viewports the bids panel sits left of the offers panel inside a
/// `Row`.

import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_contract_deal_book.dart';
import 'trade_screen_deal_book_panel.dart';

class DealBookTabContent extends StatelessWidget {
  const DealBookTabContent({
    super.key,
    required this.game,
    required this.playerId,
  });

  final Game game;
  final String playerId;

  @override
  Widget build(BuildContext context) {
    final DealBookViewData data = DealBookViewData.build(
      worldMarket: game.worldMarketState,
      playerId: playerId,
    );
    return Container(
      key: TradeScreenDealBookKeys.dealBookContentKey,
      alignment: Alignment.topLeft,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool wide =
              constraints.maxWidth >= TradeScreenDealBookKeys.dealBookTwoPanelMinWidth;
          return _layoutPanels(
            bidsPanel: _buildBidsPanel(data),
            offersPanel: _buildOffersPanel(data),
            wide: wide,
          );
        },
      ),
    );
  }

  DealBookPanel _buildBidsPanel(DealBookViewData data) {
    return DealBookPanel(
      key: TradeScreenDealBookKeys.dealBookBidsPanelKey,
      panelTitle: TradeScreenDealBookKeys.dealBookBidsPanelTitle,
      side: TradeScreenDealBookKeys.dealBookSideBids,
      filledRows: data.filledBids,
      unfilledRows: data.unfilledBids,
      totalsKey: TradeScreenDealBookKeys.dealBookBidsTotalsKey,
      emptyKey: TradeScreenDealBookKeys.dealBookBidsEmptyKey,
      totalsLabel: TradeScreenDealBookKeys.dealBookTotalSpentLabel,
      totalsAmount: data.totalSpent,
      emptyText: TradeScreenDealBookKeys.dealBookBidsEmptyText,
    );
  }

  DealBookPanel _buildOffersPanel(DealBookViewData data) {
    return DealBookPanel(
      key: TradeScreenDealBookKeys.dealBookOffersPanelKey,
      panelTitle: TradeScreenDealBookKeys.dealBookOffersPanelTitle,
      side: TradeScreenDealBookKeys.dealBookSideOffers,
      filledRows: data.filledOffers,
      unfilledRows: data.unfilledOffers,
      totalsKey: TradeScreenDealBookKeys.dealBookOffersTotalsKey,
      emptyKey: TradeScreenDealBookKeys.dealBookOffersEmptyKey,
      totalsLabel: TradeScreenDealBookKeys.dealBookTotalReceivedLabel,
      totalsAmount: data.totalReceived,
      emptyText: TradeScreenDealBookKeys.dealBookOffersEmptyText,
    );
  }

  Widget _layoutPanels({
    required Widget bidsPanel,
    required Widget offersPanel,
    required bool wide,
  }) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: bidsPanel),
          const SizedBox(width: 12),
          Expanded(child: offersPanel),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        bidsPanel,
        const SizedBox(height: 12),
        offersPanel,
      ],
    );
  }
}

/// Pure value object built from `WorldMarketState` for the player's
/// Deal Book view. Holds the four per-side row lists (filled / unfilled
/// for bids and offers) and the two treasury totals. Pulled out so the
/// rendering widget tree stays declarative and unit-testable.
class DealBookViewData {
  const DealBookViewData({
    required this.filledBids,
    required this.filledOffers,
    required this.unfilledBids,
    required this.unfilledOffers,
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
    return DealBookViewData(
      filledBids: List<FilledDeal>.unmodifiable(bids),
      filledOffers: List<FilledDeal>.unmodifiable(offers),
      unfilledBids:
          worldMarket.carryForwardBidsByFactionId[playerId] ??
              const <TradeOrder>[],
      unfilledOffers:
          worldMarket.carryForwardOffersByFactionId[playerId] ??
              const <TradeOrder>[],
      totalSpent: spent,
      totalReceived: received,
    );
  }

  final List<FilledDeal> filledBids;
  final List<FilledDeal> filledOffers;
  final List<TradeOrder> unfilledBids;
  final List<TradeOrder> unfilledOffers;
  final int totalSpent;
  final int totalReceived;
}
