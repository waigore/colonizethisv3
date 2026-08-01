/// Public Market-tab (and shared chrome) keys/literals for the trade screen.
/// Row-level literals live in [TradeScreenMarketRowKeys] (private).
/// Tests and Market UI parts use this type directly (Refs #4035 trade API collapse).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../config/app_constants.dart';
import '../../../../config/constants.dart';
import '../../../../widgets/game_feature_screen_top_bar.dart';

abstract final class TradeScreenMarketKeys {
  TradeScreenMarketKeys._();

  /// Localized back-button label rendered immediately after the chevron on
  /// the dark-theme `CtTopBar`. SPEC requires the literal `"Map"` so the
  /// affordance reads `"← Map"`.
  static const String topBarBackLabel = GameFeatureScreenTopBar.backLabel;

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Trade"` (Cinzel display font is configured at the theme
  /// level).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Trade';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 × 18 px trade icon).
  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_trade.png';

  /// Stable widget key for the trade top bar — lets widget tests pin the
  /// dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('tradeScreenTopBar');

  /// Stable widget key for the two-tab body root (Market + Deal Book).
  /// Replaces the prior `placeholderBodyKey` from the E1+E2+E3 scaffold —
  /// the tab strip is the durable structure the follow-up Market /
  /// Deal-Book slices build on, so this key remains stable when the
  /// per-tab bodies are wired to live `WorldMarketState` data in #2993
  /// E5+E6.
  static const Key tabsBodyKey = ValueKey<String>('tradeScreenTabsBody');

  /// Stable widget key for the Market tab body. Pin point for widget
  /// tests asserting the Market tab body is present in the tab strip's
  /// `IndexedStack` (visible when the Market tab is selected, which is
  /// the default). The same key spans the placeholder, the read-only
  /// commodity table introduced by Refs #2993 E5a, and the live
  /// interactive controls planned for follow-up E5 slices.
  static const Key marketTabBodyKey =
      ValueKey<String>('tradeScreenMarketTabBody');

  /// Stable widget key for the scrollable commodity list inside the
  /// Market tab body (Refs #2993 E5a). Lets widget tests reach the
  /// `ListView` that hosts the per-commodity rows without coupling to
  /// the row identities themselves.
  static const Key marketCommodityListKey =
      ValueKey<String>('tradeScreenMarketCommodityList');

  /// Content width at which Market commodity rows render in a two-column
  /// row-major grid with compact two-line rows (Refs #4227). Matches
  /// [kNarrowBreakpoint] and [TradeScreenDealBookKeys.dealBookTwoPanelMinWidth].
  static const double marketTwoColumnMinWidth = kNarrowBreakpoint;

  /// Horizontal gap between the two Market commodity columns on wide
  /// layouts (Refs #4227). Matches Deal Book inter-panel gap.
  static const double marketGridColumnGap = 12;

  /// Vertical gap between Market commodity grid rows within a section on
  /// wide layouts (Refs #4227).
  static const double marketGridRowGap = 6;

  /// Stable widget key for the `Food` category section header inside
  /// the Market tab commodity list (Refs `#3093` § Layout & grouping
  /// — sectioned grouping slice). Pin point for widget tests asserting
  /// the Food section label is mounted at the top of the list with
  /// the food commodities beneath it. The widget at this key is a
  /// `CtSectionLabel` whose visible text resolves from
  /// `l10n.production_food` (English fallback `Food`) so the trade
  /// screen reuses the existing Production-panel l10n surface.
  static const Key marketSectionFoodKey =
      ValueKey<String>('tradeScreenMarketSection:food');

  /// Stable widget key for the `Raw Materials` category section header
  /// inside the Market tab commodity list (Refs `#3093` § Layout &
  /// grouping — sectioned grouping slice). Visible text resolves from
  /// `l10n.production_rawMaterials` (English fallback `Raw Materials`).
  static const Key marketSectionRawMaterialsKey =
      ValueKey<String>('tradeScreenMarketSection:rawMaterials');

  /// Stable widget key for the `Manufactured` category section header
  /// inside the Market tab commodity list (Refs `#3093` § Layout &
  /// grouping — sectioned grouping slice). Visible text resolves from
  /// `l10n.production_manufactured` (English fallback `Manufactured`).
  static const Key marketSectionManufacturedKey =
      ValueKey<String>('tradeScreenMarketSection:manufactured');

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

  /// Per-row key for the first-right chip on line 1 (Refs #4226).
  static Key marketRowFirstRightChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:firstRightChip');

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

  /// Stable widget key for the distinct-commodity bid-type indicator
  /// rendered above the cargo indicator (Refs #4170). Renders
  /// `Bid goods: U of C` where `U` is the count of distinct staged
  /// `TradeOrderType.bid` commodities and `C` is
  /// `worldMarketBidTypeCap(game, playerId)`.
  static const Key marketBidGoodsIndicatorKey =
      ValueKey<String>('tradeScreenMarketBidGoodsIndicator');

  /// Stable widget key for the bid-type saturation warning row rendered
  /// below the bid-goods indicator when `U >= C` and `C > 0` (Refs
  /// #4170). Absent otherwise.
  static const Key marketBidTypeWarningKey =
      ValueKey<String>('tradeScreenMarketBidTypeWarning');

  /// Stable widget key for the bid-goods limit inline-help [CtIconAction]
  /// (Refs #4186).
  static const Key marketBidGoodsTooltipKey =
      ValueKey<String>('tradeScreenMarketBidGoodsTooltip');

  /// [RepaintBoundary] key for widget golden captures of the Market
  /// header strip (bid-goods indicator, warnings, cargo telemetry —
  /// Refs #4170).
  static const Key marketBidTypeCapGoldenKey =
      ValueKey<String>('tradeScreenMarketBidTypeCapGolden');

  /// Stable widget key for the treasury bid-budget indicator rendered in
  /// the Market header strip (Refs #4186). Renders `Bid budget: R of B`
  /// where `B` is `treasuryAvailableForBidsByPlayer` and `R` is
  /// `max(0, B − stagedBidTotalSpendByPlayer)`.
  static const Key marketBidBudgetIndicatorKey =
      ValueKey<String>('tradeScreenMarketBidBudgetIndicator');

  /// Stable widget key for the treasury bid-budget saturation warning row
  /// (Refs #4186). Mounted when `R == 0` and (`S > 0` or `B == 0`).
  static const Key marketBidBudgetWarningKey =
      ValueKey<String>('tradeScreenMarketBidBudgetWarning');

  /// Stable widget key for the treasury bid-budget limit inline-help
  /// [CtIconAction] (Refs #4186).
  static const Key marketBidBudgetTooltipKey =
      ValueKey<String>('tradeScreenMarketBidBudgetTooltip');

  /// Stable widget key for the cross-commodity cargo indicator header
  /// rendered above the Market tab commodity list (Refs #2993 E5c).
  /// The widget at this key renders `Cargo remaining: X` where
  /// `X = max(0, tradeCargoCapacity − totalStagedBidQuantity)`.
  static const Key marketCargoIndicatorKey =
      ValueKey<String>('tradeScreenMarketCargoIndicator');

  /// Stable widget key for the cargo-limit warning row rendered below
  /// the cargo indicator (Refs #2993 E5c). Only mounted when
  /// `remainingCargo == 0` AND `totalStagedBidQuantity > 0`; absent
  /// otherwise so widget tests can `expect(find.byKey(...), findsNothing)`
  /// in the steady non-saturated state.
  static const Key marketCargoWarningKey =
      ValueKey<String>('tradeScreenMarketCargoWarning');

  /// Stable widget key for the cargo limit inline-help [CtIconAction]
  /// (Refs #4186).
  static const Key marketCargoTooltipKey =
      ValueKey<String>('tradeScreenMarketCargoTooltip');

  /// Bid-goods indicator prefix (Refs #4170). Renders as
  /// `Bid goods: U of C` where offers never increment `U`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidGoodsIndicatorPrefix = 'Bid goods:';

  /// Bid-type saturation warning copy (Refs #4170, #4186).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidTypeLimitWarningText =
      'Bid commodity limit reached — remove a bid, or research Trade Fairs '
      'to raise your limit.';

  /// Inline tooltip for bid-goods cap `3` (Refs #4186).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidTypeLimitTooltipCopyCap3 =
      'You may bid on up to three distinct commodities each turn; research '
      'Trade Fairs to raise the limit to six.';

  /// Inline tooltip for bid-goods cap `6` (Refs #4186).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidTypeLimitTooltipCopyCap6 =
      'Trade Fairs lets you bid on up to six distinct commodities each turn.';

  /// Returns the bid-goods inline tooltip for [cap] per
  /// `worldMarketBidTypeCap` semantics (Refs #4186).
  static String bidTypeLimitTooltipForCap(int cap) {
    if (cap >= 6) return bidTypeLimitTooltipCopyCap6;
    return bidTypeLimitTooltipCopyCap3;
  }

  /// Inline tooltip for the cargo remaining limit (Refs #4186).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoLimitTooltipCopy =
      'Staged bids share your trade cargo capacity and cannot exceed your '
      'remaining cargo this turn.';

  /// Semantic label for a disabled Bid chip when the bid-type cap is
  /// saturated on a fresh commodity (Refs #4170).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidChipBidTypeCapSemanticLabel =
      'Bid disabled — commodity limit reached';

  /// Localized cargo indicator prefix. SPEC/ui/trade-screen.md §
  /// Cargo indicator pins the literal `"Cargo remaining:"` so widget
  /// tests can drive the indicator via `find.text` without coupling to
  /// the localization catalog before the trade screen is l10n-ised.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoIndicatorPrefix = 'Cargo remaining:';

  /// Cargo-limit warning copy rendered below the cargo indicator when
  /// the staged cross-commodity bid total saturates the player's
  /// `tradeCargoCapacity` (Refs #2993 E5c).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoLimitWarningText =
      'Cargo limit reached — increase your fleet capacity or reduce bids.';

  /// Bid-budget indicator prefix (Refs #4186). Renders as
  /// `Bid budget: R of B` where `R` is remaining treasury headroom for
  /// bids and `B` is the total bid budget this turn.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidBudgetIndicatorPrefix = 'Bid budget:';

  /// Treasury bid-budget saturation warning copy (Refs #4186).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidBudgetLimitWarningText =
      'Treasury bid limit reached — free gold or reduce other spending '
      'before bidding more.';

  /// Inline tooltip for the treasury bid-budget limit (Refs #4186).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidBudgetLimitTooltipCopy =
      'Bids spend from treasury after other staged orders; expected income '
      'does not increase this budget.';

  /// Tab label for the Market tab (default selection). SPEC §
  /// Layout / wireframe pins the literal `"Market"` so widget tests can
  /// drive the tab via `find.text` without coupling to localization
  /// before the trade screen joins the l10n catalog.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String marketTabLabel = 'Market';
}
