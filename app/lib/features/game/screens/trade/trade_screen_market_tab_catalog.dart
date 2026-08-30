// Market-tab catalog helpers and section row builders.
// Split from `trade_screen_market_tab_handlers.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878, #4352).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../../../../widgets/ct_section_label.dart';
import 'trade_market_staging_context.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_catalog_layout.dart';

export 'trade_screen_market_tab_catalog_data.dart'
    show
        SectionedTradeableCommodities,
        effectiveMarketPriceCoins,
        formatMarketPrice,
        lastMarketTooltip,
        showLastMarketChip,
        tradeableCommoditiesByCategory;

extension MarketTabContentCatalog on MarketTabContent {
  /// Builds the widget list that renders one Market commodity category
  /// section: a `CtSectionLabel` header keyed by [sectionKey] followed
  /// by the per-commodity rows for [commodities] in their input order.
  List<Widget> buildCommoditySectionWidgets({
    required Key sectionKey,
    required String sectionLabel,
    required List<Commodity> commodities,
    required TradeMarketStagingContext staging,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle quantityStyle,
    required AppLocalizations l10n,
    bool isFirstSection = true,
    bool wideLayout = false,
  }) {
    if (commodities.isEmpty) return const <Widget>[];
    return <Widget>[
      if (!isFirstSection) const SizedBox(height: 12),
      CtSectionLabel(sectionLabel, key: sectionKey),
      const SizedBox(height: 6),
      if (wideLayout)
        ...buildWideCommodityGrid(
          commodities: commodities,
          staging: staging,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
          quantityStyle: quantityStyle,
          l10n: l10n,
        )
      else
        ...buildNarrowCommodityList(
          commodities: commodities,
          staging: staging,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
          quantityStyle: quantityStyle,
          l10n: l10n,
        ),
    ];
  }
}
