// Market-tab per-commodity row builder (Refs #4352).
// Split from `trade_screen_market_tab_catalog.dart`.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../widgets/production/commodity_ui_helpers.dart';
import '../counsel/trade_counsel_l10n.dart';
import 'trade_market_counsel_star.dart';
import 'trade_market_staging_context.dart';
import 'trade_screen_market_price_delta.dart';
import 'trade_screen_market_row.dart';
import 'trade_screen_market_row_highlight.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_catalog_data.dart';

extension MarketTabContentCatalogRow on MarketTabContent {
  Widget buildCommodityRow({
    required Commodity commodity,
    required bool compact,
    required TradeMarketStagingContext staging,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle volumeStyle,
    required TextStyle quantityStyle,
    required AppLocalizations l10n,
  }) {
    final CommodityId commodityId = commodity.id;
    final bool showFirstRightChip = staging.firstRightCommodityIds.contains(
      commodityId,
    );
    final highlight = staging.tradeCounselHighlightsByCommodityId[commodityId];
    final onOpenCounsel = staging.onOpenTradeCounsel;
    TradeMarketCounselStar? counselStar;
    if (highlight != null && onOpenCounsel != null) {
      final brief = tradeCounselBriefForReason(l10n, highlight.briefReasonKey);
      counselStar = TradeMarketCounselStar(
        briefMessage: brief,
        semanticLabel: l10n.tradeMarket_tradeCounselStarSemantic(brief),
        onOpenCounsel: () => onOpenCounsel(
          highlightRecommendationId: highlight.recommendationId,
        ),
      );
    }
    final MarketActivity activity =
        staging.market.lastTurnActivity[commodityId] ?? MarketActivity.empty;
    final int? effectivePrice = effectiveMarketPriceCoins(
      staging.market.prices[commodityId],
      commodityId: commodityId,
    );
    final int? priceDelta = marketPriceDeltaCoins(
      currentPrice: effectivePrice,
      priceChangePercent: activity.priceChangePercent,
    );
    final rowParams = (
      commodityId: commodityId,
      commodityDisplayName: commodityDisplayName(l10n, commodityId),
      priceText: formatMarketPrice(
        staging.market.prices[commodityId],
        commodityId: commodityId,
      ),
      volumeText: volumeText(activity, l10n),
      priceDeltaCoins: priceDelta,
      priceDeltaTooltip: priceDelta == null
          ? ''
          : l10n.tradeMarket_priceMovedTooltip,
      stagedOrder: staging.stagedOrderFor(commodityId),
      sellableHeadroom: staging.sellableHeadroomFor(commodityId),
      offerCap: staging.offerCap[commodityId] ?? 0,
      canSelectBid: staging.canSelectBidOn(commodityId),
      nameStyle: nameStyle,
      priceStyle: priceStyle,
      volumeStyle: volumeStyle,
      quantityStyle: quantityStyle,
      onDirectionChanged: (TradeOrderType? next) =>
          staging.onDirectionChanged(commodityId, next),
      onIncrement: () => staging.onQuantityDelta(commodityId, 1),
      onDecrement: () => staging.onQuantityDelta(commodityId, -1),
    );
    final Widget row = compact
        ? MarketCommodityRowCompact(
            commodityId: rowParams.commodityId,
            commodityDisplayName: rowParams.commodityDisplayName,
            priceText: rowParams.priceText,
            volumeText: rowParams.volumeText,
            priceDeltaCoins: rowParams.priceDeltaCoins,
            priceDeltaTooltip: rowParams.priceDeltaTooltip,
            stagedOrder: rowParams.stagedOrder,
            sellableHeadroom: rowParams.sellableHeadroom,
            offerCap: rowParams.offerCap,
            canSelectBid: rowParams.canSelectBid,
            nameStyle: rowParams.nameStyle,
            priceStyle: rowParams.priceStyle,
            volumeStyle: rowParams.volumeStyle,
            quantityStyle: rowParams.quantityStyle,
            onDirectionChanged: rowParams.onDirectionChanged,
            onIncrement: rowParams.onIncrement,
            onDecrement: rowParams.onDecrement,
            showFirstRightChip: showFirstRightChip,
            firstRightChipLabel: l10n.tradeMarket_firstRightChip,
            firstRightTooltip: l10n.tradeMarket_firstRightTooltip,
            counselStar: counselStar,
          )
        : MarketCommodityRow(
            commodityId: rowParams.commodityId,
            commodityDisplayName: rowParams.commodityDisplayName,
            priceText: rowParams.priceText,
            volumeText: rowParams.volumeText,
            priceDeltaCoins: rowParams.priceDeltaCoins,
            priceDeltaTooltip: rowParams.priceDeltaTooltip,
            stagedOrder: rowParams.stagedOrder,
            sellableHeadroom: rowParams.sellableHeadroom,
            offerCap: rowParams.offerCap,
            canSelectBid: rowParams.canSelectBid,
            nameStyle: rowParams.nameStyle,
            priceStyle: rowParams.priceStyle,
            volumeStyle: rowParams.volumeStyle,
            quantityStyle: rowParams.quantityStyle,
            onDirectionChanged: rowParams.onDirectionChanged,
            onIncrement: rowParams.onIncrement,
            onDecrement: rowParams.onDecrement,
            showFirstRightChip: showFirstRightChip,
            firstRightChipLabel: l10n.tradeMarket_firstRightChip,
            firstRightTooltip: l10n.tradeMarket_firstRightTooltip,
            counselStar: counselStar,
          );
    return MarketCommodityRowHighlight(
      commodityId: commodityId,
      highlighted: highlightCommodityId == commodityId,
      child: row,
    );
  }
}
