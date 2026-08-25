// Market-tab catalog narrow/wide layout builders (Refs #4352).
// Split from `trade_screen_market_tab_catalog.dart`.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'trade_market_staging_context.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_catalog_row.dart';

extension MarketTabContentCatalogLayout on MarketTabContent {
  List<Widget> buildNarrowCommodityList({
    required List<Commodity> commodities,
    required TradeMarketStagingContext staging,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle quantityStyle,
    required AppLocalizations l10n,
  }) {
    return <Widget>[
      for (int index = 0; index < commodities.length; index++)
        Padding(
          key: TradeScreenMarketKeys.marketCommodityRowKey(
            commodities[index].id,
          ),
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: buildCommodityRow(
            commodity: commodities[index],
            compact: false,
            staging: staging,
            nameStyle: nameStyle,
            priceStyle: priceStyle,
            quantityStyle: quantityStyle,
            l10n: l10n,
          ),
        ),
    ];
  }

  List<Widget> buildWideCommodityGrid({
    required List<Commodity> commodities,
    required TradeMarketStagingContext staging,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle quantityStyle,
    required AppLocalizations l10n,
  }) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < commodities.length; index += 2) {
      final Commodity left = commodities[index];
      final Commodity? right = index + 1 < commodities.length
          ? commodities[index + 1]
          : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 0 : TradeScreenMarketKeys.marketGridRowGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  key: TradeScreenMarketKeys.marketCommodityRowKey(left.id),
                  padding: EdgeInsets.zero,
                  child: buildCommodityRow(
                    commodity: left,
                    compact: true,
                    staging: staging,
                    nameStyle: nameStyle,
                    priceStyle: priceStyle,
                    quantityStyle: quantityStyle,
                    l10n: l10n,
                  ),
                ),
              ),
              const SizedBox(width: TradeScreenMarketKeys.marketGridColumnGap),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: TradeScreenMarketKeys.marketCommodityRowKey(
                          right.id,
                        ),
                        padding: EdgeInsets.zero,
                        child: buildCommodityRow(
                          commodity: right,
                          compact: true,
                          staging: staging,
                          nameStyle: nameStyle,
                          priceStyle: priceStyle,
                          quantityStyle: quantityStyle,
                          l10n: l10n,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
}
