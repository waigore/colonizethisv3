// Market-tab per-commodity row builder (Refs #4352, #4653).
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
    final bool lastMarket = showLastMarketChip(activity);
    final bool absorbControlPointers = !canEdit;
    final rowParams = (
      commodityId: commodityId,
      commodityDisplayName: commodityDisplayName(l10n, commodityId),
      priceText: formatMarketPrice(
        staging.market.prices[commodityId],
        commodityId: commodityId,
      ),
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
      quantityStyle: quantityStyle,
      onDirectionChanged: (TradeOrderType? next) =>
          staging.onDirectionChanged(commodityId, next),
      onIncrement: () => staging.onQuantityDelta(commodityId, 1),
      onDecrement: () => staging.onQuantityDelta(commodityId, -1),
      absorbControlPointers: absorbControlPointers,
      showLastMarketChip: lastMarket,
      lastMarketChipLabel: l10n.tradeMarket_lastMarketChip,
      lastMarketTooltip: lastMarket ? lastMarketTooltip(activity, l10n) : '',
    );
    final Widget row = compact
        ? MarketCommodityRowCompact(
            commodityId: rowParams.commodityId,
            commodityDisplayName: rowParams.commodityDisplayName,
            priceText: rowParams.priceText,
            priceDeltaCoins: rowParams.priceDeltaCoins,
            priceDeltaTooltip: rowParams.priceDeltaTooltip,
            stagedOrder: rowParams.stagedOrder,
            sellableHeadroom: rowParams.sellableHeadroom,
            offerCap: rowParams.offerCap,
            canSelectBid: rowParams.canSelectBid,
            nameStyle: rowParams.nameStyle,
            priceStyle: rowParams.priceStyle,
            quantityStyle: rowParams.quantityStyle,
            onDirectionChanged: rowParams.onDirectionChanged,
            onIncrement: rowParams.onIncrement,
            onDecrement: rowParams.onDecrement,
            absorbControlPointers: rowParams.absorbControlPointers,
            showFirstRightChip: showFirstRightChip,
            firstRightChipLabel: l10n.tradeMarket_firstRightChip,
            firstRightTooltip: l10n.tradeMarket_firstRightTooltip,
            showLastMarketChip: rowParams.showLastMarketChip,
            lastMarketChipLabel: rowParams.lastMarketChipLabel,
            lastMarketTooltip: rowParams.lastMarketTooltip,
            counselStar: counselStar,
          )
        : MarketCommodityRow(
            commodityId: rowParams.commodityId,
            commodityDisplayName: rowParams.commodityDisplayName,
            priceText: rowParams.priceText,
            priceDeltaCoins: rowParams.priceDeltaCoins,
            priceDeltaTooltip: rowParams.priceDeltaTooltip,
            stagedOrder: rowParams.stagedOrder,
            sellableHeadroom: rowParams.sellableHeadroom,
            offerCap: rowParams.offerCap,
            canSelectBid: rowParams.canSelectBid,
            nameStyle: rowParams.nameStyle,
            priceStyle: rowParams.priceStyle,
            quantityStyle: rowParams.quantityStyle,
            onDirectionChanged: rowParams.onDirectionChanged,
            onIncrement: rowParams.onIncrement,
            onDecrement: rowParams.onDecrement,
            absorbControlPointers: rowParams.absorbControlPointers,
            showFirstRightChip: showFirstRightChip,
            firstRightChipLabel: l10n.tradeMarket_firstRightChip,
            firstRightTooltip: l10n.tradeMarket_firstRightTooltip,
            showLastMarketChip: rowParams.showLastMarketChip,
            lastMarketChipLabel: rowParams.lastMarketChipLabel,
            lastMarketTooltip: rowParams.lastMarketTooltip,
            counselStar: counselStar,
          );
    return MarketCommodityRowHighlight(
      commodityId: commodityId,
      highlighted: highlightCommodityId == commodityId,
      child: row,
    );
  }
}
