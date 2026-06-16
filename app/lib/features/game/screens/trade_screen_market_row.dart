// Market tab commodity row widgets for the World Market Trade screen
// (Refs #2993, #3093, #3487, split out from `trade_screen.dart` to keep
// the host file under the repo-lint non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`).
//
// All classes here are library-private (`_MarketCommodityRow*`,
// `_StepperButton`) and consumed only by `_MarketTabContent` inside the
// parent library, so they keep using `TradeScreen` / `_MarketTabContent`
// static constants without further plumbing.

part of 'trade_screen.dart';

/// One row of the Market tab commodity table. Lays the read-only
/// content on the first two lines and the interactive direction
/// selector + stepper on a third line so the row remains overflow-safe
/// at the 320 dp minimum viewport (SPEC/ui/mobile-adaptation.md §7).
class _MarketCommodityRow extends StatelessWidget {
  const _MarketCommodityRow({
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.volumeText,
    required this.stagedOrder,
    required this.sellableHeadroom,
    required this.offerCap,
    required this.nameStyle,
    required this.priceStyle,
    required this.volumeStyle,
    required this.quantityStyle,
    required this.onDirectionChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final String volumeText;
  final TradeOrder? stagedOrder;

  /// Refs #3093 — sellable clamp slice. The `(N)` value rendered
  /// next to the commodity name. Computed in [_MarketTabContent] as
  /// `max(0, offerCap − stagedOffer)`.
  final int sellableHeadroom;

  /// Refs #3093 — sellable clamp slice. The per-commodity offer cap
  /// (`stockpile − industryAllocation`, alloc=0 today). Used to gate
  /// the Offer chip and offer-side `+` button so they read as
  /// disabled when the cap is `0`.
  final int offerCap;

  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle volumeStyle;
  final TextStyle quantityStyle;
  final ValueChanged<TradeOrderType?> onDirectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  bool get _hasStagedOrder => stagedOrder != null;

  String get _quantityText => stagedOrder == null
      ? TradeScreen.marketRowQuantityIdleGlyph
      : stagedOrder!.quantity.toString();

  bool get _canDecrement =>
      stagedOrder != null &&
      stagedOrder!.quantity > TradeScreen.marketRowQuantityMin;

  /// True when the row's `+` button can grow the staged order quantity.
  /// For bids the cross-commodity cargo cap (Refs #2993 E5c) gates this
  /// via the `_handleQuantityDelta` no-op when cargo is exhausted; for
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
        _MarketCommodityRowHeader(
          commodityId: commodityId,
          commodityDisplayName: commodityDisplayName,
          priceText: priceText,
          sellableHeadroom: sellableHeadroom,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
        ),
        const SizedBox(height: 2),
        Text(volumeText, style: volumeStyle),
        const SizedBox(height: 6),
        _MarketCommodityRowControls(
          commodityId: commodityId,
          stagedType: stagedOrder?.type,
          quantityText: _quantityText,
          quantityStyle: quantityStyle,
          canDecrement: _canDecrement,
          canIncrement: _canIncrement,
          canSelectOffer: _canSelectOffer,
          onDirectionChanged: onDirectionChanged,
          onIncrement: onIncrement,
          onDecrement: onDecrement,
        ),
      ],
    );
  }
}

/// Top read-only line of a Market tab commodity row (Refs #3093, #3487):
/// resource icon, commodity name, sellable `(N)` headroom readout, then a
/// fixed-width trailing column that right-aligns the coin icon and price so
/// every row shares the same price-digit column edge.
/// Extracted from `_MarketCommodityRow.build` to keep the parent
/// `build` body within the `widget_build_method_too_long` AST cap.
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

/// Interactive controls strip below the static read-only data on a
/// Market tab commodity row (Refs #2993 E5b).
class _MarketCommodityRowControls extends StatelessWidget {
  const _MarketCommodityRowControls({
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
          key: TradeScreen.marketRowNoneChipKey(commodityId),
          selected: stagedType == null,
          onSelected: (_) => onDirectionChanged(null),
          label: const Text(_MarketTabContent.noneChipLabel),
        ),
        CtChoiceChip(
          key: TradeScreen.marketRowBidChipKey(commodityId),
          selected: stagedType == TradeOrderType.bid,
          onSelected: (_) => onDirectionChanged(TradeOrderType.bid),
          label: const Text(_MarketTabContent.bidChipLabel),
        ),
        CtChoiceChip(
          key: TradeScreen.marketRowOfferChipKey(commodityId),
          selected: stagedType == TradeOrderType.offer,
          onSelected: canSelectOffer
              ? (_) => onDirectionChanged(TradeOrderType.offer)
              : null,
          label: const Text(_MarketTabContent.offerChipLabel),
        ),
        _StepperButton(
          buttonKey: TradeScreen.marketRowDecrementKey(commodityId),
          // ignore: avoid_hardcoded_strings_in_widgets
          glyph: '−',
          semanticLabel: _MarketTabContent.decrementSemanticLabel,
          onPressed: canDecrement ? onDecrement : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            quantityText,
            key: TradeScreen.marketRowQuantityTextKey(commodityId),
            style: quantityStyle,
            textAlign: TextAlign.center,
          ),
        ),
        _StepperButton(
          buttonKey: TradeScreen.marketRowIncrementKey(commodityId),
          // ignore: avoid_hardcoded_strings_in_widgets
          glyph: '+',
          semanticLabel: _MarketTabContent.incrementSemanticLabel,
          onPressed: canIncrement ? onIncrement : null,
        ),
      ],
    );
  }
}

/// Compact stepper button used by [_MarketCommodityRowControls]. Uses
/// an `InkWell` so the chrome stays in the editorial-monocle palette
/// (no Material elevated buttons or accent splash colours).
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.buttonKey,
    required this.glyph,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Key buttonKey;
  final String glyph;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle glyphStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
            .copyWith(
              color: onPressed == null
                  ? EditorialMonoclePalette.muted
                  : EditorialMonoclePalette.accent,
            );
    final Color borderColor = onPressed == null
        ? EditorialMonoclePalette.muted
        : EditorialMonoclePalette.accent;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: InkWell(
        key: buttonKey,
        onTap: onPressed,
        child: Container(
          width: 28,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: EditorialMonoclePalette.surface.withValues(alpha: 0.5),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(glyph, style: glyphStyle),
        ),
      ),
    );
  }
}
