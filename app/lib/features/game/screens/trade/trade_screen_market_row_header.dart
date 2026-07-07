// Top read-only line of a Market tab commodity row (Refs #3093, #3487).
// Split from `trade_screen_market_row.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).

part of 'trade_screen.dart';

/// Resource icon, commodity name, sellable `(N)` headroom readout, then a
/// fixed-width trailing column that right-aligns the coin icon and price so
/// every row shares the same price-digit column edge.
class _MarketCommodityRowHeader extends StatelessWidget {
  const _MarketCommodityRowHeader({
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.sellableHeadroom,
    required this.nameStyle,
    required this.priceStyle,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final int sellableHeadroom;
  final TextStyle nameStyle;
  final TextStyle priceStyle;

  @override
  Widget build(BuildContext context) {
    final TextStyle sellableStyle = nameStyle.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ResourceIcon(
          key: TradeScreen.marketRowResourceIconKey(commodityId),
          commodityId: commodityId,
          size: TradeScreen.marketRowResourceIconSize,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
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
                key: TradeScreen.marketRowSellableReadoutKey(commodityId),
                style: sellableStyle,
              ),
            ],
          ),
        ),
        SizedBox(
          width: TradeScreen.marketRowPriceColumnWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                StrictAssetIcon(
                  key: TradeScreen.marketRowPriceCoinIconKey(commodityId),
                  assetPath: TradeScreen.marketRowPriceCoinAssetPath,
                  width: TradeScreen.marketRowPriceCoinIconSize,
                  height: TradeScreen.marketRowPriceCoinIconSize,
                ),
                const SizedBox(
                  width: TradeScreen.marketRowPriceColumnInnerGap,
                ),
                Text(priceText, style: priceStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
