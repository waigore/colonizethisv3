// Market-tab section list assembly for `_MarketTabContent`.
// Split from `trade_screen_market_tab_build.dart` (Refs #3878).

part of 'trade_screen.dart';

extension _MarketTabContentBuildSections on _MarketTabContent {
  ({
    TextStyle nameStyle,
    TextStyle priceStyle,
    TextStyle volumeStyle,
    TextStyle quantityStyle,
    TextStyle cargoIndicatorStyle,
    TextStyle cargoWarningStyle,
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
          (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
              .copyWith(color: EditorialMonoclePalette.danger),
    );
  }

  List<Widget> buildMarketTabSectionWidgets({
    required AppLocalizations l10n,
    required _SectionedTradeableCommodities sectioned,
    required WorldMarketState market,
    required Orders orders,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle volumeStyle,
    required TextStyle quantityStyle,
    required TradeSectionHandlers sectionHandlers,
  }) {
    return <Widget>[
      ..._buildCommoditySectionWidgets(
        sectionKey: TradeScreen.marketSectionFoodKey,
        sectionLabel: l10n.production_food,
        commodities: sectioned.food,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
      ),
      ..._buildCommoditySectionWidgets(
        sectionKey: TradeScreen.marketSectionRawMaterialsKey,
        sectionLabel: l10n.production_rawMaterials,
        commodities: sectioned.rawMaterials,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        isFirstSection: false,
      ),
      ..._buildCommoditySectionWidgets(
        sectionKey: TradeScreen.marketSectionManufacturedKey,
        sectionLabel: l10n.production_manufactured,
        commodities: sectioned.manufactured,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        isFirstSection: false,
      ),
    ];
  }
}
