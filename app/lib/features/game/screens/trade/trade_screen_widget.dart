part of 'trade_screen.dart';

/// Full-screen World Market trade screen.
///
/// Dark editorial-monocle chrome per `SPEC/ui/trade-screen.md` § Top bar: a
/// `CtTopBar` carrying the `Map` back affordance, the 18 × 18 pixel-art
/// trade icon, and the literal title `Trade`. The body is a two-tab
/// `CtTabStrip` (Market + Deal Book). The Market tab renders a
/// read-only commodity table sourced from `game.worldMarketState`
/// (Refs #2993 E5a); the Deal Book tab keeps the placeholder copy until
/// the per-player ledger work for Refs #2993 E6 lands.
class TradeScreen extends ConsumerWidget {
  const TradeScreen({
    super.key,
    required this.game,
    required this.player,
    this.initialTabIndex = 0,
  }) : assert(
          initialTabIndex >= 0 && initialTabIndex < 2,
          'initialTabIndex must be 0 (Market) or 1 (Deal Book) for TradeScreen',
        );

  /// Initially-selected tab index for the body's `CtTabStrip`. Defaults
  /// to `0` so the dark-theme E4 contract (Market tab visible on first
  /// mount) is preserved for the production route. Story builders /
  /// widget tests opt into the Deal Book tab (`1`) without simulating a
  /// label tap; the underlying `CtTabStrip.initialTabIndex` is the only
  /// surface that propagates the override.
  final int initialTabIndex;

  /// SPEC/ui/trade-screen.md — [UiScreenIds.tradeScreen].
  static const screenId = UiScreenIds.tradeScreen;

  static const String topBarBackLabel = _TradeScreenContract.topBarBackLabel;
  static const String topBarTitle = _TradeScreenContract.topBarTitle;
  static const String topBarIconAsset = _TradeScreenContract.topBarIconAsset;
  static const Key topBarKey = _TradeScreenContract.topBarKey;
  static const Key tabsBodyKey = _TradeScreenContract.tabsBodyKey;
  static const Key marketTabBodyKey = _TradeScreenContract.marketTabBodyKey;
  static const Key marketCommodityListKey =
      _TradeScreenContract.marketCommodityListKey;
  static const Key marketSectionFoodKey =
      _TradeScreenContract.marketSectionFoodKey;
  static const Key marketSectionRawMaterialsKey =
      _TradeScreenContract.marketSectionRawMaterialsKey;
  static const Key marketSectionManufacturedKey =
      _TradeScreenContract.marketSectionManufacturedKey;
  static Key marketCommodityRowKey(CommodityId commodityId) =>
      _TradeScreenContract.marketCommodityRowKey(commodityId);
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowNoneChipKey(commodityId);
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowBidChipKey(commodityId);
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowOfferChipKey(commodityId);
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowDecrementKey(commodityId);
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowIncrementKey(commodityId);
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowQuantityTextKey(commodityId);
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowSellableReadoutKey(commodityId);
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowResourceIconKey(commodityId);
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowPriceCoinIconKey(commodityId);
  static const double marketRowResourceIconSize =
      _TradeScreenContract.marketRowResourceIconSize;
  static const double marketRowPriceCoinIconSize =
      _TradeScreenContract.marketRowPriceCoinIconSize;
  static const double marketRowPriceColumnWidth =
      _TradeScreenContract.marketRowPriceColumnWidth;
  static const double marketRowPriceColumnInnerGap =
      _TradeScreenContract.marketRowPriceColumnInnerGap;
  @visibleForTesting
  static ResourceRules? get marketPriceResourceRulesOverride =>
      _TradeScreenContract.marketPriceResourceRulesOverride;
  @visibleForTesting
  static set marketPriceResourceRulesOverride(ResourceRules? value) =>
      _TradeScreenContract.marketPriceResourceRulesOverride = value;
  static const String marketRowPriceCoinAssetPath =
      _TradeScreenContract.marketRowPriceCoinAssetPath;
  static const int marketRowQuantityMin =
      _TradeScreenContract.marketRowQuantityMin;
  static const int marketRowQuantityDefault =
      _TradeScreenContract.marketRowQuantityDefault;
  static const int marketRowDefaultPriority =
      _TradeScreenContract.marketRowDefaultPriority;
  static const String marketRowQuantityIdleGlyph =
      _TradeScreenContract.marketRowQuantityIdleGlyph;
  static const Key marketCargoIndicatorKey =
      _TradeScreenContract.marketCargoIndicatorKey;
  static const Key marketCargoWarningKey =
      _TradeScreenContract.marketCargoWarningKey;
  static const String cargoIndicatorPrefix =
      _TradeScreenContract.cargoIndicatorPrefix;
  static const String cargoLimitWarningText =
      _TradeScreenContract.cargoLimitWarningText;
  static const Key dealBookTabBodyKey = _TradeScreenContract.dealBookTabBodyKey;
  static const Key dealBookContentKey = _TradeScreenContract.dealBookContentKey;
  static const String dealBookSideBids = _TradeScreenContract.dealBookSideBids;
  static const String dealBookSideOffers =
      _TradeScreenContract.dealBookSideOffers;
  static const Key dealBookBidsPanelKey =
      _TradeScreenContract.dealBookBidsPanelKey;
  static const Key dealBookOffersPanelKey =
      _TradeScreenContract.dealBookOffersPanelKey;
  static const Key dealBookBidsTotalsKey =
      _TradeScreenContract.dealBookBidsTotalsKey;
  static const Key dealBookOffersTotalsKey =
      _TradeScreenContract.dealBookOffersTotalsKey;
  static const Key dealBookBidsEmptyKey =
      _TradeScreenContract.dealBookBidsEmptyKey;
  static const Key dealBookOffersEmptyKey =
      _TradeScreenContract.dealBookOffersEmptyKey;
  static Key dealBookFilledRowKey(String side, int index) =>
      _TradeScreenContract.dealBookFilledRowKey(side, index);
  static Key dealBookUnfilledRowKey(String side, int index) =>
      _TradeScreenContract.dealBookUnfilledRowKey(side, index);
  static const double dealBookTwoPanelMinWidth =
      _TradeScreenContract.dealBookTwoPanelMinWidth;
  static const String dealBookBidsPanelTitle =
      _TradeScreenContract.dealBookBidsPanelTitle;
  static const String dealBookOffersPanelTitle =
      _TradeScreenContract.dealBookOffersPanelTitle;
  static const String dealBookFilledHeading =
      _TradeScreenContract.dealBookFilledHeading;
  static const String dealBookUnfilledHeading =
      _TradeScreenContract.dealBookUnfilledHeading;
  static const String dealBookBidsEmptyText =
      _TradeScreenContract.dealBookBidsEmptyText;
  static const String dealBookOffersEmptyText =
      _TradeScreenContract.dealBookOffersEmptyText;
  static const String dealBookTotalSpentLabel =
      _TradeScreenContract.dealBookTotalSpentLabel;
  static const String dealBookTotalReceivedLabel =
      _TradeScreenContract.dealBookTotalReceivedLabel;
  static String formatFilledDealUnitPrice(double pricePerUnit) =>
      _TradeScreenContract.formatFilledDealUnitPrice(pricePerUnit);
  static const String dealBookFilledEmptyText =
      _TradeScreenContract.dealBookFilledEmptyText;
  static const String dealBookUnfilledEmptyText =
      _TradeScreenContract.dealBookUnfilledEmptyText;
  static const String marketTabLabel = _TradeScreenContract.marketTabLabel;
  static const String dealBookTabLabel = _TradeScreenContract.dealBookTabLabel;

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: GameFeatureScreenTopBar.build(
        key: topBarKey,
        title: topBarTitle,
        iconAsset: topBarIconAsset,
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        final shell = shellRef.read(shellPlayerContextProvider);
        // ignore: avoid_hardcoded_strings_in_widgets
        final sentinel = observeNotDefinedSentinel(shell, 'Trade');
        if (sentinel != null) return sentinel;
        final bool canEdit = shell.canMutateViaUi;
        return _TradeScreenTabsBody(
          key: tabsBodyKey,
          game: displayGame,
          playerId: player.id,
          canEdit: canEdit,
          initialTabIndex: initialTabIndex,
        );
      },
    );
  }
}
