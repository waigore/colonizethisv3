import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'trade_screen_contract_market.dart';
import 'trade_screen_market_row_controls.dart';
import 'trade_screen_market_row_header.dart';

/// Wide-layout (≥ 600 dp) Market row: two-line compact structure with
/// interactive controls on line 2 (Refs #4227, #4653).
class MarketCommodityRowCompact extends StatelessWidget {
  const MarketCommodityRowCompact({
    super.key,
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.stagedOrder,
    required this.sellableHeadroom,
    required this.offerCap,
    required this.canSelectBid,
    required this.nameStyle,
    required this.priceStyle,
    required this.quantityStyle,
    required this.onDirectionChanged,
    required this.onIncrement,
    required this.onDecrement,
    this.priceDeltaCoins,
    this.priceDeltaTooltip = '',
    this.absorbControlPointers = false,
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
  final int? priceDeltaCoins;
  final String priceDeltaTooltip;
  final TradeOrder? stagedOrder;
  final int sellableHeadroom;
  final int offerCap;
  final bool canSelectBid;
  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle quantityStyle;
  final ValueChanged<TradeOrderType?> onDirectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool absorbControlPointers;
  final bool showFirstRightChip;
  final String firstRightChipLabel;
  final String firstRightTooltip;
  final bool showLastMarketChip;
  final String lastMarketChipLabel;
  final String lastMarketTooltip;
  final Widget? counselStar;

  bool get _hasStagedOrder => stagedOrder != null;

  String get _quantityText => stagedOrder == null
      ? TradeScreenMarketKeys.marketRowQuantityIdleGlyph
      : stagedOrder!.quantity.toString();

  bool get _canDecrement =>
      stagedOrder != null &&
      stagedOrder!.quantity > TradeScreenMarketKeys.marketRowQuantityMin;

  bool get _canIncrement {
    if (!_hasStagedOrder) return false;
    if (stagedOrder!.type == TradeOrderType.offer) {
      return stagedOrder!.quantity < offerCap;
    }
    return true;
  }

  bool get _canSelectOffer {
    if (stagedOrder?.type == TradeOrderType.offer) return true;
    return offerCap > 0;
  }

  Widget _controls() {
    final Widget child = MarketCommodityRowControls(
      commodityId: commodityId,
      stagedType: stagedOrder?.type,
      quantityText: _quantityText,
      quantityStyle: quantityStyle,
      canDecrement: _canDecrement,
      canIncrement: _canIncrement,
      canSelectOffer: _canSelectOffer,
      canSelectBid: canSelectBid,
      onDirectionChanged: onDirectionChanged,
      onIncrement: onIncrement,
      onDecrement: onDecrement,
    );
    if (!absorbControlPointers) return child;
    return IgnorePointer(child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MarketCommodityRowHeader(
          commodityId: commodityId,
          commodityDisplayName: commodityDisplayName,
          priceText: priceText,
          sellableHeadroom: sellableHeadroom,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
          priceDeltaCoins: priceDeltaCoins,
          priceDeltaTooltip: priceDeltaTooltip,
          showFirstRightChip: showFirstRightChip,
          firstRightChipLabel: firstRightChipLabel,
          firstRightTooltip: firstRightTooltip,
          showLastMarketChip: showLastMarketChip,
          lastMarketChipLabel: lastMarketChipLabel,
          lastMarketTooltip: lastMarketTooltip,
          counselStar: counselStar,
        ),
        Padding(padding: const EdgeInsets.only(top: 2), child: _controls()),
      ],
    );
  }
}
