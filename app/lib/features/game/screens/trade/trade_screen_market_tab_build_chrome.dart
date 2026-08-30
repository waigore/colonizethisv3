// Market-tab header / observe-mode chrome for `MarketTabContent`.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_nine_patch_button.dart';
import 'trade_market_staging_context.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_cargo_header.dart';

extension MarketTabContentBuildChrome on MarketTabContent {
  static const double observeModeOpacity = 0.7;
  Widget buildMarketTabCounselAndHeader({
    required AppLocalizations l10n,
    required int stagedDistinctBidCount,
    required int bidTypeCap,
    required int clampedRemaining,
    required bool cargoWarningVisible,
    required ({int budgetTotal, int budgetRemaining, bool warningVisible})
    bidBudgetHeader,
    required TextStyle bidGoodsIndicatorStyle,
    required TextStyle bidTypeWarningStyle,
    required TextStyle cargoIndicatorStyle,
    required TextStyle cargoWarningStyle,
    required TextStyle bidBudgetIndicatorStyle,
    required TextStyle bidBudgetWarningStyle,
    TradeOpenCounselCallback? onOpenTradeCounsel,
  }) {
    return RepaintBoundary(
      key: TradeScreenMarketKeys.marketBidTypeCapGoldenKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onOpenTradeCounsel != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: CtNinePatchButton(
                  key: const ValueKey<String>('trade_market_counsel_button'),
                  onPressed: () => onOpenTradeCounsel(),
                  child: Text(l10n.tradeMarket_counsel),
                ),
              ),
            ),
          MarketTabHeaderStrip(
            stagedDistinctBidCount: stagedDistinctBidCount,
            bidTypeCap: bidTypeCap,
            clampedRemaining: clampedRemaining,
            cargoWarningVisible: cargoWarningVisible,
            bidBudgetTotal: bidBudgetHeader.budgetTotal,
            bidBudgetRemaining: bidBudgetHeader.budgetRemaining,
            bidBudgetWarningVisible: bidBudgetHeader.warningVisible,
            bidGoodsIndicatorStyle: bidGoodsIndicatorStyle,
            bidTypeWarningStyle: bidTypeWarningStyle,
            cargoIndicatorStyle: cargoIndicatorStyle,
            cargoWarningStyle: cargoWarningStyle,
            bidBudgetIndicatorStyle: bidBudgetIndicatorStyle,
            bidBudgetWarningStyle: bidBudgetWarningStyle,
          ),
        ],
      ),
    );
  }

  Widget wrapMarketTabObserveList({
    required Widget header,
    required Widget list,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        header,
        Flexible(
          child: Opacity(
            opacity: MarketTabContentBuildChrome.observeModeOpacity,
            child: list,
          ),
        ),
      ],
    );
  }
}
