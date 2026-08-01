// Top read-only line of a Market tab commodity row (Refs #3093, #3487).
// Split from `trade_screen_market_row.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).

/// Resource icon, commodity name, sellable `(N)` headroom readout, then a
/// fixed-width trailing column that right-aligns the coin icon and price so
/// every row shares the same price-digit column edge.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../widgets/resource_icon.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'trade_screen_contract_market.dart';

class MarketCommodityRowHeader extends StatelessWidget {
  const MarketCommodityRowHeader({
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.sellableHeadroom,
    required this.nameStyle,
    required this.priceStyle,
    this.showFirstRightChip = false,
    this.firstRightChipLabel = '',
    this.firstRightTooltip = '',
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final int sellableHeadroom;
  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final bool showFirstRightChip;
  final String firstRightChipLabel;
  final String firstRightTooltip;

  @override
  Widget build(BuildContext context) {
    final TextStyle sellableStyle = nameStyle.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final TextStyle chipStyle = (Theme.of(context).textTheme.labelSmall ??
            const TextStyle(fontSize: 10))
        .copyWith(color: EditorialMonoclePalette.muted);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ResourceIcon(
          key: TradeScreenMarketKeys.marketRowResourceIconKey(commodityId),
          commodityId: commodityId,
          size: TradeScreenMarketKeys.marketRowResourceIconSize,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _MarketCommodityRowTitleBand(
            commodityId: commodityId,
            commodityDisplayName: commodityDisplayName,
            sellableHeadroom: sellableHeadroom,
            nameStyle: nameStyle,
            sellableStyle: sellableStyle,
            chipStyle: chipStyle,
            showFirstRightChip: showFirstRightChip,
            firstRightChipLabel: firstRightChipLabel,
            firstRightTooltip: firstRightTooltip,
          ),
        ),
        _MarketCommodityRowPriceTrailing(
          commodityId: commodityId,
          priceText: priceText,
          priceStyle: priceStyle,
        ),
      ],
    );
  }
}

class _MarketCommodityRowTitleBand extends StatelessWidget {
  const _MarketCommodityRowTitleBand({
    required this.commodityId,
    required this.commodityDisplayName,
    required this.sellableHeadroom,
    required this.nameStyle,
    required this.sellableStyle,
    required this.chipStyle,
    required this.showFirstRightChip,
    required this.firstRightChipLabel,
    required this.firstRightTooltip,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final int sellableHeadroom;
  final TextStyle nameStyle;
  final TextStyle sellableStyle;
  final TextStyle chipStyle;
  final bool showFirstRightChip;
  final String firstRightChipLabel;
  final String firstRightTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            commodityDisplayName,
            style: nameStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          // ignore: avoid_hardcoded_strings_in_widgets
          '($sellableHeadroom)',
          key: TradeScreenMarketKeys.marketRowSellableReadoutKey(commodityId),
          style: sellableStyle,
        ),
        if (showFirstRightChip) ...<Widget>[
          const SizedBox(width: 4),
          Tooltip(
            message: firstRightTooltip,
            child: Text(
              firstRightChipLabel,
              key: TradeScreenMarketKeys.marketRowFirstRightChipKey(commodityId),
              style: chipStyle,
            ),
          ),
        ],
      ],
    );
  }
}

class _MarketCommodityRowPriceTrailing extends StatelessWidget {
  const _MarketCommodityRowPriceTrailing({
    required this.commodityId,
    required this.priceText,
    required this.priceStyle,
  });

  final CommodityId commodityId;
  final String priceText;
  final TextStyle priceStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TradeScreenMarketKeys.marketRowPriceColumnWidth,
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StrictAssetIcon(
              key: TradeScreenMarketKeys.marketRowPriceCoinIconKey(commodityId),
              assetPath: TradeScreenMarketKeys.marketRowPriceCoinAssetPath,
              width: TradeScreenMarketKeys.marketRowPriceCoinIconSize,
              height: TradeScreenMarketKeys.marketRowPriceCoinIconSize,
            ),
            const SizedBox(
              width: TradeScreenMarketKeys.marketRowPriceColumnInnerGap,
            ),
            Text(priceText, style: priceStyle),
          ],
        ),
      ),
    );
  }
}
