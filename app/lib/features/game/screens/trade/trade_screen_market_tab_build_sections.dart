// Market-tab section list assembly for `MarketTabContent`.
// Split from `trade_screen_market_tab_build.dart` (Refs #3878).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'trade_market_staging_context.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_catalog.dart';

extension MarketTabContentBuildSections on MarketTabContent {
  ({
    TextStyle nameStyle,
    TextStyle priceStyle,
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
      quantityStyle:
          (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
              .copyWith(color: EditorialMonoclePalette.accentBright),
      cargoIndicatorStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
            color: EditorialMonoclePalette.accent,
          ),
      cargoWarningStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)),
      bidGoodsIndicatorStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
            color: EditorialMonoclePalette.accent,
          ),
      bidTypeWarningStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)),
      bidBudgetIndicatorStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
            color: EditorialMonoclePalette.accent,
          ),
      bidBudgetWarningStyle:
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)),
    );
  }

  List<Widget> buildMarketTabSectionWidgets({
    required AppLocalizations l10n,
    required SectionedTradeableCommodities sectioned,
    required TradeMarketStagingContext staging,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle quantityStyle,
    bool wideLayout = false,
  }) {
    return <Widget>[
      ...buildCommoditySectionWidgets(
        sectionKey: TradeScreenMarketKeys.marketSectionFoodKey,
        sectionLabel: l10n.production_food,
        commodities: sectioned.food,
        staging: staging,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        quantityStyle: quantityStyle,
        l10n: l10n,
        wideLayout: wideLayout,
      ),
      ...buildCommoditySectionWidgets(
        sectionKey: TradeScreenMarketKeys.marketSectionRawMaterialsKey,
        sectionLabel: l10n.production_rawMaterials,
        commodities: sectioned.rawMaterials,
        staging: staging,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        quantityStyle: quantityStyle,
        isFirstSection: false,
        l10n: l10n,
        wideLayout: wideLayout,
      ),
      ...buildCommoditySectionWidgets(
        sectionKey: TradeScreenMarketKeys.marketSectionManufacturedKey,
        sectionLabel: l10n.production_manufactured,
        commodities: sectioned.manufactured,
        staging: staging,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        quantityStyle: quantityStyle,
        isFirstSection: false,
        l10n: l10n,
        wideLayout: wideLayout,
      ),
    ];
  }
}
