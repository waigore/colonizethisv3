part of 'trade_screen.dart';

/// Market-tab chrome widget keys and copy literals for [TradeScreen].
/// Row-level contract literals live in [_TradeScreenMarketRowContract]
/// (`trade_screen_contract_market_rows.dart`). Library part of the trade
/// screen contract split (Refs #3878).
abstract final class _TradeScreenMarketContract {
  _TradeScreenMarketContract._();

  /// Localized back-button label rendered immediately after the chevron on
  /// the dark-theme `CtTopBar`. SPEC requires the literal `"Map"` so the
  /// affordance reads `"← Map"`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

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

  static Key marketCommodityRowKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketCommodityRowKey(commodityId);
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowNoneChipKey(commodityId);
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowBidChipKey(commodityId);
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowOfferChipKey(commodityId);
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowDecrementKey(commodityId);
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowIncrementKey(commodityId);
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowQuantityTextKey(commodityId);
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowSellableReadoutKey(commodityId);
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowResourceIconKey(commodityId);
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      _TradeScreenMarketRowContract.marketRowPriceCoinIconKey(commodityId);
  static const double marketRowResourceIconSize =
      _TradeScreenMarketRowContract.marketRowResourceIconSize;
  static const double marketRowPriceCoinIconSize =
      _TradeScreenMarketRowContract.marketRowPriceCoinIconSize;
  static const double marketRowPriceColumnWidth =
      _TradeScreenMarketRowContract.marketRowPriceColumnWidth;
  static const double marketRowPriceColumnInnerGap =
      _TradeScreenMarketRowContract.marketRowPriceColumnInnerGap;
  @visibleForTesting
  static ResourceRules? get marketPriceResourceRulesOverride =>
      _TradeScreenMarketRowContract.marketPriceResourceRulesOverride;
  @visibleForTesting
  static set marketPriceResourceRulesOverride(ResourceRules? value) =>
      _TradeScreenMarketRowContract.marketPriceResourceRulesOverride = value;
  static const String marketRowPriceCoinAssetPath =
      _TradeScreenMarketRowContract.marketRowPriceCoinAssetPath;
  static const int marketRowQuantityMin =
      _TradeScreenMarketRowContract.marketRowQuantityMin;
  static const int marketRowQuantityDefault =
      _TradeScreenMarketRowContract.marketRowQuantityDefault;
  static const int marketRowDefaultPriority =
      _TradeScreenMarketRowContract.marketRowDefaultPriority;
  static const String marketRowQuantityIdleGlyph =
      _TradeScreenMarketRowContract.marketRowQuantityIdleGlyph;

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

  /// Tab label for the Market tab (default selection). SPEC §
  /// Layout / wireframe pins the literal `"Market"` so widget tests can
  /// drive the tab via `find.text` without coupling to localization
  /// before the trade screen joins the l10n catalog.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String marketTabLabel = 'Market';
}
