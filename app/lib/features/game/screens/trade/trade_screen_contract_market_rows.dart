part of 'trade_screen.dart';

/// Per-row Market-tab keys/literals (private implementation detail of
/// [TradeScreenMarketKeys]; not imported by tests). Refs #4035.
abstract final class _TradeScreenMarketRowKeys {
  _TradeScreenMarketRowKeys._();

  /// Per-row key for a Market tab commodity row. Deterministic so widget
  /// tests can pin a specific commodity (e.g. `timber`) without relying
  /// on text matching.
  static Key marketCommodityRowKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId');

  /// Per-row key for the `None` direction chip on a Market tab row
  /// (Refs #2993 E5b). Tapping the chip removes any staged trade order
  /// for the commodity from `currentOrdersProvider`.
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:none');

  /// Per-row key for the `Bid` direction chip on a Market tab row
  /// (Refs #2993 E5b). Tapping the chip stages a `TradeOrderType.bid`
  /// for the commodity (replacing any prior offer for that commodity).
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:bid');

  /// Per-row key for the `Offer` direction chip on a Market tab row
  /// (Refs #2993 E5b). Tapping the chip stages a `TradeOrderType.offer`
  /// for the commodity (replacing any prior bid for that commodity).
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:offer');

  /// Per-row key for the decrement button of the quantity stepper on a
  /// Market tab row (Refs #2993 E5b). Disabled when there is no staged
  /// trade order for the commodity or when its quantity is at the lower
  /// bound (`marketRowQuantityMin`).
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:decrement');

  /// Per-row key for the increment button of the quantity stepper on a
  /// Market tab row (Refs #2993 E5b). Increments the staged trade order
  /// quantity by 1.
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:increment');

  /// Per-row key for the quantity readout (`Text`) of the stepper on a
  /// Market tab row (Refs #2993 E5b). Shows the staged
  /// `TradeOrder.quantity` (or `marketRowQuantityIdleGlyph` when no
  /// trade order is staged for the commodity).
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:quantity');

  /// Per-row key for the inline sellable-headroom readout rendered as
  /// `(N)` immediately after the commodity name on line 1 of the row.
  /// `N` is the per-commodity offer cap minus the row's already-staged
  /// offer quantity, sourced from
  /// `sellableHeadroomByCommodityId` (Refs #3093 — sellable clamp
  /// slice). Pin point for widget tests asserting the readout reflects
  /// the player's stockpile / staged-offer state without coupling to
  /// text-matching on the parent name line.
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:sellable');

  /// Per-row key for the leading `ResourceIcon` paint on line 1 of the
  /// Market row, immediately before the commodity display name (Refs
  /// `#3093` — row-icons slice). Mounted exactly once per row. When the
  /// commodity has no `ResourceIcon` asset (catalog gap), the icon
  /// widget still mounts under this key but paints an empty
  /// `SizedBox(marketRowResourceIconSize × marketRowResourceIconSize)`
  /// fallback per [`ResourceIcon.build`].
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:resourceIcon');

  /// Per-row key for the trailing treasury-coin glyph rendered
  /// immediately before the integer price text on line 1 of the Market
  /// row (Refs `#3093` — row-icons slice). Always mounted regardless of
  /// whether the row resolves to an integer price or the em-dash
  /// fallback so the coin acts as a visual currency cue rather than a
  /// price-availability flag.
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:priceCoin');

  /// Logical-pixel side length of the leading `ResourceIcon` paint on
  /// each Market row (Refs `#3093` — row-icons slice). 20 dp matches
  /// the Production panel's `CtResourceCell.leadingIconSize` so the
  /// Trade row's commodity glyph reads the same physical size as its
  /// Production-panel counterpart.
  static const double marketRowResourceIconSize = 20;

  /// Logical-pixel side length of the trailing treasury-coin glyph
  /// rendered next to the integer price on each Market row (Refs
  /// `#3093` — row-icons slice). 14 dp keeps the coin visually
  /// subordinate to the 20 dp `ResourceIcon` so the row reads
  /// `[ResourceIcon 20] Name (N) … [Coin 14] 30`.
  static const double marketRowPriceCoinIconSize = 14;

  /// Fixed width of the trailing market-price column (coin + price text)
  /// on Market row line 1 (Refs `#3487`). The same width on every row so
  /// the right edge of the price digits shares a vertical column across
  /// the commodity list. Sized to fit [marketRowPriceCoinIconSize] +
  /// [marketRowPriceColumnInnerGap] + three-digit catalog default prices
  /// (e.g. manufactured `steel` at `170`) at [titleSmall] without clipping.
  static const double marketRowPriceColumnWidth = 64;

  /// Horizontal gap between the treasury-coin glyph and the price text
  /// inside the trailing market-price column (Refs `#3487`).
  static const double marketRowPriceColumnInnerGap = 4;

  /// When non-null, overrides [ResourceRules.defaultRules] for Market tab
  /// price formatting only. Widget tests set this to exercise the em-dash
  /// fallback path without a catalog default (Refs `#3487` AC4).
  @visibleForTesting
  static ResourceRules? marketPriceResourceRulesOverride;

  /// Asset path of the treasury-coin glyph rendered next to each
  /// Market row's integer price (Refs `#3093` — row-icons slice). Same
  /// asset family as the game tab bar treasury chip
  /// (`GameTabBar._iconSize == 18`) so the coin visually anchors money
  /// across screens without re-issuing a different art asset.
  static const String marketRowPriceCoinAssetPath =
      '${kAppIconAssetPrefix}ui_icon_treasury_coin.png';

  /// Lower bound for the per-row quantity stepper when a trade order is
  /// staged. Setting the stepper below 1 is equivalent to choosing
  /// `None`, which removes the order — so the stepper is clamped at 1
  /// while a direction is selected.
  static const int marketRowQuantityMin = 1;

  /// Default starting quantity when the player first selects `Bid` or
  /// `Offer` on a row that has no staged trade order. Always 1 (the
  /// stepper minimum); the player increments from there. The
  /// per-commodity / cargo cap clamps the upper bound in #2993 E5c.
  static const int marketRowQuantityDefault = 1;

  /// Default `TradeOrder.priority` assigned when the player first
  /// stages a `Bid` or `Offer` on a row. The interactive priority
  /// dropdown is deferred to a follow-up slice; until the
  /// `kMaxTradePriority` API surface is wired (#2989), the row uses the
  /// highest tier (priority 1) so staged orders are stable.
  // ignore: avoid-non-null-assertion
  static const int marketRowDefaultPriority = 1;

  /// Glyph rendered in the per-row quantity readout when no trade order
  /// is staged for a commodity (`None` direction). Mirrors the price
  /// em-dash so the visual language is consistent across the row.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String marketRowQuantityIdleGlyph = '—';
}
