// Top read-only line of a Market tab commodity row (Refs #3093, #3487).
// Split from `trade_screen_market_row.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).

/// Resource icon, commodity name, sellable `(N)` headroom readout, then a
/// fixed-width trailing column that right-aligns the coin icon and price so
/// every row shares the same price-digit column edge.
library;

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../widgets/resource_icon.dart';
import '../../../../widgets/strict_asset_icon.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_price_delta.dart';

class MarketCommodityRowHeader extends StatelessWidget {
  const MarketCommodityRowHeader({
    super.key,
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.sellableHeadroom,
    required this.nameStyle,
    required this.priceStyle,
    this.priceDeltaCoins,
    this.priceDeltaTooltip = '',
    this.showFirstRightChip = false,
    this.firstRightChipLabel = '',
    this.firstRightTooltip = '',
    this.showLastMarketChip = false,
    this.lastMarketChipLabel = '',
    this.lastMarketTooltip = '',
    this.counselStar,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final int sellableHeadroom;
  final TextStyle nameStyle;
  final TextStyle priceStyle;

  /// Last-turn reconstructed coin delta (Refs `#4345`). Null / omitted
  /// when activity is missing, percent is zero, or delta rounds to 0.
  final int? priceDeltaCoins;
  final String priceDeltaTooltip;
  final bool showFirstRightChip;
  final String firstRightChipLabel;
  final String firstRightTooltip;
  final bool showLastMarketChip;
  final String lastMarketChipLabel;
  final String lastMarketTooltip;
  final Widget? counselStar;

  @override
  Widget build(BuildContext context) {
    final TextStyle sellableStyle = nameStyle.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final TextStyle chipStyle =
        (Theme.of(context).textTheme.labelSmall ??
                const TextStyle(fontSize: 11))
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
        Expanded(child: _titleBand(sellableStyle, chipStyle)),
        _MarketCommodityRowPriceTrailing(
          commodityId: commodityId,
          priceText: priceText,
          priceStyle: priceStyle,
          priceDeltaCoins: priceDeltaCoins,
          priceDeltaTooltip: priceDeltaTooltip,
        ),
      ],
    );
  }

  Widget _titleBand(TextStyle sellableStyle, TextStyle chipStyle) {
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
        ..._chip(
          show: showFirstRightChip,
          tooltip: firstRightTooltip,
          label: firstRightChipLabel,
          chipKey: TradeScreenMarketKeys.marketRowFirstRightChipKey(
            commodityId,
          ),
          chipStyle: chipStyle,
        ),
        ..._chip(
          show: showLastMarketChip,
          tooltip: lastMarketTooltip,
          label: lastMarketChipLabel,
          chipKey: TradeScreenMarketKeys.marketRowLastMarketChipKey(
            commodityId,
          ),
          chipStyle: chipStyle,
          tap: true,
        ),
        if (counselStar != null) counselStar!,
      ],
    );
  }
}

List<Widget> _chip({
  required bool show,
  required String tooltip,
  required String label,
  required Key chipKey,
  required TextStyle chipStyle,
  bool tap = false,
}) {
  if (!show) return const <Widget>[];
  return <Widget>[
    const SizedBox(width: 4),
    Tooltip(
      message: tooltip,
      triggerMode: tap ? TooltipTriggerMode.tap : TooltipTriggerMode.longPress,
      child: Text(label, key: chipKey, style: chipStyle),
    ),
  ];
}

class _MarketCommodityRowPriceTrailing extends StatelessWidget {
  const _MarketCommodityRowPriceTrailing({
    required this.commodityId,
    required this.priceText,
    required this.priceStyle,
    this.priceDeltaCoins,
    this.priceDeltaTooltip = '',
  });

  final CommodityId commodityId;
  final String priceText;
  final TextStyle priceStyle;
  final int? priceDeltaCoins;
  final String priceDeltaTooltip;

  @override
  Widget build(BuildContext context) {
    final int? delta = priceDeltaCoins;
    final Widget coinAndPrice = Row(
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
    );
    final Widget cluster = delta == null
        ? coinAndPrice
        : Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              coinAndPrice,
              Text(
                formatMarketPriceDelta(delta),
                key: TradeScreenMarketKeys.marketRowPriceDeltaKey(commodityId),
                style:
                    (Theme.of(context).textTheme.labelSmall ??
                            const TextStyle(fontSize: 11))
                        .copyWith(
                          color: delta > 0
                              ? EditorialMonoclePalette.success
                              : EditorialMonoclePalette.danger,
                        ),
              ),
            ],
          );
    final Widget child = delta == null || priceDeltaTooltip.isEmpty
        ? cluster
        : Tooltip(message: priceDeltaTooltip, child: cluster);
    return SizedBox(
      width: TradeScreenMarketKeys.marketRowPriceColumnWidth,
      child: Align(alignment: Alignment.centerRight, child: child),
    );
  }
}
