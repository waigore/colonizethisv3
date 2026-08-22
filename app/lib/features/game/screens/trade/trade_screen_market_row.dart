// Market tab commodity row host for the World Market Trade screen
// (Refs #2993, #3093, #3487, split out from `trade_screen.dart` to keep
// the host file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`).
//
// All classes here are library-private (`MarketCommodityRow*`,
// `StepperButton`) and consumed only by `MarketTabContent` inside the
// parent library, so they keep using `TradeScreen` / `MarketTabContent`
// static constants without further plumbing.

/// One row of the Market tab commodity table. Lays the read-only
/// content on the first two lines and the interactive direction
/// selector + stepper on a third line so the row remains overflow-safe
/// at the 320 dp minimum viewport (SPEC/ui/mobile-adaptation.md §7).
library;

import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_contract_market.dart';
import 'trade_screen_market_row_controls.dart';
import 'trade_screen_market_row_header.dart';
import 'trade_screen_market_tab.dart';

export 'trade_screen_market_row_compact.dart';

class MarketCommodityRow extends StatelessWidget {
  const MarketCommodityRow({
    super.key,
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.volumeText,
    required this.stagedOrder,
    required this.sellableHeadroom,
    required this.offerCap,
    required this.canSelectBid,
    required this.nameStyle,
    required this.priceStyle,
    required this.volumeStyle,
    required this.quantityStyle,
    required this.onDirectionChanged,
    required this.onIncrement,
    required this.onDecrement,
    this.priceDeltaCoins,
    this.priceDeltaTooltip = '',
    this.showFirstRightChip = false,
    this.firstRightChipLabel = '',
    this.firstRightTooltip = '',
    this.counselStar,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final String volumeText;
  final int? priceDeltaCoins;
  final String priceDeltaTooltip;
  final TradeOrder? stagedOrder;

  /// Refs #3093 — sellable clamp slice. The `(N)` value rendered
  /// next to the commodity name. Computed in [MarketTabContent] as
  /// `max(0, offerCap − stagedOffer)`.
  final int sellableHeadroom;

  /// Refs #3093 — sellable clamp slice. The per-commodity offer cap
  /// (`stockpile − industryAllocation`, alloc=0 today). Used to gate
  /// the Offer chip and offer-side `+` button so they read as
  /// disabled when the cap is `0`.
  final int offerCap;

  /// Refs #4170 — bid-type cap slice. When `false` the Bid chip reads as
  /// disabled so the player cannot stage a bid on a fresh commodity when
  /// the distinct-bid count has reached `worldMarketBidTypeCap`. Rows that
  /// already stage a bid remain editable.
  final bool canSelectBid;

  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle volumeStyle;
  final TextStyle quantityStyle;
  final ValueChanged<TradeOrderType?> onDirectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool showFirstRightChip;
  final String firstRightChipLabel;
  final String firstRightTooltip;
  final Widget? counselStar;

  bool get _hasStagedOrder => stagedOrder != null;

  String get _quantityText => stagedOrder == null
      ? TradeScreenMarketKeys.marketRowQuantityIdleGlyph
      : stagedOrder!.quantity.toString();

  bool get _canDecrement =>
      stagedOrder != null &&
      stagedOrder!.quantity > TradeScreenMarketKeys.marketRowQuantityMin;

  /// True when the row's `+` button can grow the staged order quantity.
  /// For bids the cross-commodity cargo cap (Refs #2993 E5c) gates this
  /// via the `handleQuantityDelta` no-op when cargo is exhausted; for
  /// offers (Refs #3093) the per-commodity offer cap caps the row at
  /// `offerCap` so the button reads as disabled at saturation.
  bool get _canIncrement {
    if (!_hasStagedOrder) return false;
    if (stagedOrder!.type == TradeOrderType.offer) {
      return stagedOrder!.quantity < offerCap;
    }
    return true;
  }

  /// True when the Offer chip can be toggled on. When the per-commodity
  /// offer cap is `0` (stockpile exhausted) and no offer is already
  /// staged, the chip reads as disabled so the player gets immediate
  /// visual feedback that no units are sellable.
  bool get _canSelectOffer {
    if (stagedOrder?.type == TradeOrderType.offer) return true;
    return offerCap > 0;
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
          counselStar: counselStar,
        ),
        const SizedBox(height: 2),
        Text(volumeText, style: volumeStyle),
        const SizedBox(height: 6),
        MarketCommodityRowControls(
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
        ),
      ],
    );
  }
}
