// Market-tab section list assembly for `MarketTabContent`.
// Split from `trade_screen_market_tab_build.dart` (Refs #3878).


import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_catalog.dart';
import 'trade_section_handlers.dart';

extension MarketTabContentBuildSections on MarketTabContent {
  ({
    TextStyle nameStyle,
    TextStyle priceStyle,
    TextStyle volumeStyle,
    TextStyle quantityStyle,
    TextStyle cargoIndicatorStyle,
    TextStyle cargoWarningStyle,
    TextStyle bidGoodsIndicatorStyle,
    TextStyle bidTypeWarningStyle,
    TextStyle bidBudgetIndicatorStyle,
    TextStyle bidBudgetWarningStyle,
  })
  marketTabTextStyles(ThemeData theme) {
    return (
      nameStyle: (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
          .copyWith(color: EditorialMonoclePalette.accent),
      priceStyle: (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
          .copyWith(color: EditorialMonoclePalette.accentBright),
      volumeStyle: (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
          .copyWith(color: EditorialMonoclePalette.muted),
      quantityStyle:
          (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
              .copyWith(color: EditorialMonoclePalette.accentBright),
      cargoIndicatorStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
              .copyWith(color: EditorialMonoclePalette.accent),
      cargoWarningStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)),
      bidGoodsIndicatorStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
              .copyWith(color: EditorialMonoclePalette.accent),
      bidTypeWarningStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)),
      bidBudgetIndicatorStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
              .copyWith(color: EditorialMonoclePalette.accent),
      bidBudgetWarningStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)),
    );
  }

  List<Widget> buildMarketTabSectionWidgets({
    required AppLocalizations l10n,
    required SectionedTradeableCommodities sectioned,
    required WorldMarketState market,
    required Orders orders,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required int bidTypeCap,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle volumeStyle,
    required TextStyle quantityStyle,
    required TradeSectionHandlers sectionHandlers,
  }) {
    return <Widget>[
      ...buildCommoditySectionWidgets(
        sectionKey: TradeScreenMarketKeys.marketSectionFoodKey,
        sectionLabel: l10n.production_food,
        commodities: sectioned.food,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        bidTypeCap: bidTypeCap,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        l10n: l10n,
      ),
      ...buildCommoditySectionWidgets(
        sectionKey: TradeScreenMarketKeys.marketSectionRawMaterialsKey,
        sectionLabel: l10n.production_rawMaterials,
        commodities: sectioned.rawMaterials,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        bidTypeCap: bidTypeCap,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        isFirstSection: false,
        l10n: l10n,
      ),
      ...buildCommoditySectionWidgets(
        sectionKey: TradeScreenMarketKeys.marketSectionManufacturedKey,
        sectionLabel: l10n.production_manufactured,
        commodities: sectioned.manufactured,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        bidTypeCap: bidTypeCap,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        isFirstSection: false,
        l10n: l10n,
      ),
    ];
  }
}
