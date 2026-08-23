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
library;

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_contract_deal_book.dart';
import 'trade_screen_deal_book_data.dart';
import 'trade_screen_deal_book_overseas.dart';
import 'trade_screen_deal_book_panel.dart';

export 'trade_screen_deal_book_data.dart';

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
    final AppLocalizations l10n = appL10n(context);
    final DealBookViewData data = DealBookViewData.build(
      worldMarket: game.worldMarketState,
      playerId: playerId,
    );
    final List<OverseasProfitCreditRecord> overseasProfitRecords =
        game.worldMarketState.lastTurnOverseasProfitCreditsByGpId[playerId] ??
        const <OverseasProfitCreditRecord>[];
    return Container(
      key: TradeScreenDealBookKeys.dealBookContentKey,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (overseasProfitRecords.isNotEmpty)
            DealBookOverseasProfitLedgerSection(
              records: overseasProfitRecords,
              l10n: l10n,
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool wide =
                  constraints.maxWidth >=
                  TradeScreenDealBookKeys.dealBookTwoPanelMinWidth;
              return _layoutPanels(
                bidsPanel: _buildBidsPanel(data, l10n),
                offersPanel: _buildOffersPanel(data, l10n),
                wide: wide,
              );
            },
          ),
        ],
      ),
    );
  }

  DealBookPanel _buildBidsPanel(DealBookViewData data, AppLocalizations l10n) {
    return DealBookPanel(
      key: TradeScreenDealBookKeys.dealBookBidsPanelKey,
      panelTitle: TradeScreenDealBookKeys.dealBookBidsPanelTitle,
      side: TradeScreenDealBookKeys.dealBookSideBids,
      filledRows: data.filledBids,
      stillOpenRows: data.bidReasonData.stillOpenRows,
      didNotStayOpenRows: data.bidReasonData.didNotStayOpenRows,
      totalsKey: TradeScreenDealBookKeys.dealBookBidsTotalsKey,
      emptyKey: TradeScreenDealBookKeys.dealBookBidsEmptyKey,
      totalsLabel: TradeScreenDealBookKeys.dealBookTotalSpentLabel,
      totalsAmount: data.totalSpent,
      emptyText: TradeScreenDealBookKeys.dealBookBidsEmptyText,
      matchTagFirstRight: l10n.tradeDealBook_matchTagFirstRight,
      matchTagFavoredPartner: l10n.tradeDealBook_matchTagFavoredPartner,
    );
  }

  DealBookPanel _buildOffersPanel(
    DealBookViewData data,
    AppLocalizations l10n,
  ) {
    return DealBookPanel(
      key: TradeScreenDealBookKeys.dealBookOffersPanelKey,
      panelTitle: TradeScreenDealBookKeys.dealBookOffersPanelTitle,
      side: TradeScreenDealBookKeys.dealBookSideOffers,
      filledRows: data.filledOffers,
      stillOpenRows: data.offerReasonData.stillOpenRows,
      didNotStayOpenRows: data.offerReasonData.didNotStayOpenRows,
      totalsKey: TradeScreenDealBookKeys.dealBookOffersTotalsKey,
      emptyKey: TradeScreenDealBookKeys.dealBookOffersEmptyKey,
      totalsLabel: TradeScreenDealBookKeys.dealBookTotalReceivedLabel,
      totalsAmount: data.totalReceived,
      emptyText: TradeScreenDealBookKeys.dealBookOffersEmptyText,
      matchTagFirstRight: l10n.tradeDealBook_matchTagFirstRight,
      matchTagFavoredPartner: l10n.tradeDealBook_matchTagFavoredPartner,
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
      children: <Widget>[bidsPanel, const SizedBox(height: 12), offersPanel],
    );
  }
}
