// Interactive controls strip for Market tab commodity rows (Refs #2993 E5b).
// Split from `trade_screen_market_row.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).

/// Direction selector + quantity stepper below the static read-only data on a
/// Market tab commodity row.

import 'package:flutter/material.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../widgets/ct_choice_chip.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_row_stepper.dart';
import 'trade_screen_market_tab.dart';

class MarketCommodityRowControls extends StatelessWidget {
  const MarketCommodityRowControls({
    required this.commodityId,
    required this.stagedType,
    required this.quantityText,
    required this.quantityStyle,
    required this.canDecrement,
    required this.canIncrement,
    required this.canSelectOffer,
    required this.onDirectionChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CommodityId commodityId;
  final TradeOrderType? stagedType;
  final String quantityText;
  final TextStyle quantityStyle;
  final bool canDecrement;
  final bool canIncrement;

  /// Refs #3093 — sellable clamp slice. When `false` the Offer chip
  /// reads as disabled (no `onSelected` handler) so the player cannot
  /// stage an offer for a commodity whose per-commodity offer cap is
  /// `0`. Offers already staged on the row remain interactive (the
  /// player can decrement / drop them) regardless of this gate.
  final bool canSelectOffer;

  final ValueChanged<TradeOrderType?> onDirectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        CtChoiceChip(
          key: TradeScreenMarketKeys.marketRowNoneChipKey(commodityId),
          selected: stagedType == null,
          onSelected: (_) => onDirectionChanged(null),
          label: const Text(MarketTabContent.noneChipLabel),
        ),
        CtChoiceChip(
          key: TradeScreenMarketKeys.marketRowBidChipKey(commodityId),
          selected: stagedType == TradeOrderType.bid,
          onSelected: (_) => onDirectionChanged(TradeOrderType.bid),
          label: const Text(MarketTabContent.bidChipLabel),
        ),
        CtChoiceChip(
          key: TradeScreenMarketKeys.marketRowOfferChipKey(commodityId),
          selected: stagedType == TradeOrderType.offer,
          onSelected: canSelectOffer
              ? (_) => onDirectionChanged(TradeOrderType.offer)
              : null,
          label: const Text(MarketTabContent.offerChipLabel),
        ),
        StepperButton(
          buttonKey: TradeScreenMarketKeys.marketRowDecrementKey(commodityId),
          // ignore: avoid_hardcoded_strings_in_widgets
          glyph: '−',
          semanticLabel: MarketTabContent.decrementSemanticLabel,
          onPressed: canDecrement ? onDecrement : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            quantityText,
            key: TradeScreenMarketKeys.marketRowQuantityTextKey(commodityId),
            style: quantityStyle,
            textAlign: TextAlign.center,
          ),
        ),
        StepperButton(
          buttonKey: TradeScreenMarketKeys.marketRowIncrementKey(commodityId),
          // ignore: avoid_hardcoded_strings_in_widgets
          glyph: '+',
          semanticLabel: MarketTabContent.incrementSemanticLabel,
          onPressed: canIncrement ? onIncrement : null,
        ),
      ],
    );
  }
}
