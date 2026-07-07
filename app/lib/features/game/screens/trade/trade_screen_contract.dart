part of 'trade_screen.dart';

/// Stable widget keys, copy literals, and Market/Deal Book contract helpers
/// for [TradeScreen]. Aggregates [_TradeScreenMarketContract] and
/// [_TradeScreenDealBookContract] so the public `TradeScreen.*` static API
/// surface used by widget tests stays unchanged (Refs #3878).
abstract final class _TradeScreenContract {
  _TradeScreenContract._();

  static const String topBarBackLabel =
      _TradeScreenMarketContract.topBarBackLabel;
  static const String topBarTitle = _TradeScreenMarketContract.topBarTitle;
  static const String topBarIconAsset =
      _TradeScreenMarketContract.topBarIconAsset;
  static const Key topBarKey = _TradeScreenMarketContract.topBarKey;
  static const Key tabsBodyKey = _TradeScreenMarketContract.tabsBodyKey;
  static const Key marketTabBodyKey =
      _TradeScreenMarketContract.marketTabBodyKey;
  static const Key marketCommodityListKey =
      _TradeScreenMarketContract.marketCommodityListKey;
  static const Key marketSectionFoodKey =
      _TradeScreenMarketContract.marketSectionFoodKey;
  static const Key marketSectionRawMaterialsKey =
      _TradeScreenMarketContract.marketSectionRawMaterialsKey;
  static const Key marketSectionManufacturedKey =
      _TradeScreenMarketContract.marketSectionManufacturedKey;
  static Key marketCommodityRowKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketCommodityRowKey(commodityId);
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowNoneChipKey(commodityId);
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowBidChipKey(commodityId);
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowOfferChipKey(commodityId);
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowDecrementKey(commodityId);
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowIncrementKey(commodityId);
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowQuantityTextKey(commodityId);
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowSellableReadoutKey(commodityId);
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowResourceIconKey(commodityId);
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      _TradeScreenMarketContract.marketRowPriceCoinIconKey(commodityId);
  static const double marketRowResourceIconSize =
      _TradeScreenMarketContract.marketRowResourceIconSize;
  static const double marketRowPriceCoinIconSize =
      _TradeScreenMarketContract.marketRowPriceCoinIconSize;
  static const double marketRowPriceColumnWidth =
      _TradeScreenMarketContract.marketRowPriceColumnWidth;
  static const double marketRowPriceColumnInnerGap =
      _TradeScreenMarketContract.marketRowPriceColumnInnerGap;
  @visibleForTesting
  static ResourceRules? get marketPriceResourceRulesOverride =>
      _TradeScreenMarketContract.marketPriceResourceRulesOverride;
  @visibleForTesting
  static set marketPriceResourceRulesOverride(ResourceRules? value) =>
      _TradeScreenMarketContract.marketPriceResourceRulesOverride = value;
  static const String marketRowPriceCoinAssetPath =
      _TradeScreenMarketContract.marketRowPriceCoinAssetPath;
  static const int marketRowQuantityMin =
      _TradeScreenMarketContract.marketRowQuantityMin;
  static const int marketRowQuantityDefault =
      _TradeScreenMarketContract.marketRowQuantityDefault;
  static const int marketRowDefaultPriority =
      _TradeScreenMarketContract.marketRowDefaultPriority;
  static const String marketRowQuantityIdleGlyph =
      _TradeScreenMarketContract.marketRowQuantityIdleGlyph;
  static const Key marketCargoIndicatorKey =
      _TradeScreenMarketContract.marketCargoIndicatorKey;
  static const Key marketCargoWarningKey =
      _TradeScreenMarketContract.marketCargoWarningKey;
  static const String cargoIndicatorPrefix =
      _TradeScreenMarketContract.cargoIndicatorPrefix;
  static const String cargoLimitWarningText =
      _TradeScreenMarketContract.cargoLimitWarningText;
  static const String marketTabLabel =
      _TradeScreenMarketContract.marketTabLabel;

  static const Key dealBookTabBodyKey =
      _TradeScreenDealBookContract.dealBookTabBodyKey;
  static const Key dealBookContentKey =
      _TradeScreenDealBookContract.dealBookContentKey;
  static const String dealBookSideBids =
      _TradeScreenDealBookContract.dealBookSideBids;
  static const String dealBookSideOffers =
      _TradeScreenDealBookContract.dealBookSideOffers;
  static const Key dealBookBidsPanelKey =
      _TradeScreenDealBookContract.dealBookBidsPanelKey;
  static const Key dealBookOffersPanelKey =
      _TradeScreenDealBookContract.dealBookOffersPanelKey;
  static const Key dealBookBidsTotalsKey =
      _TradeScreenDealBookContract.dealBookBidsTotalsKey;
  static const Key dealBookOffersTotalsKey =
      _TradeScreenDealBookContract.dealBookOffersTotalsKey;
  static const Key dealBookBidsEmptyKey =
      _TradeScreenDealBookContract.dealBookBidsEmptyKey;
  static const Key dealBookOffersEmptyKey =
      _TradeScreenDealBookContract.dealBookOffersEmptyKey;
  static Key dealBookFilledRowKey(String side, int index) =>
      _TradeScreenDealBookContract.dealBookFilledRowKey(side, index);
  static Key dealBookUnfilledRowKey(String side, int index) =>
      _TradeScreenDealBookContract.dealBookUnfilledRowKey(side, index);
  static const double dealBookTwoPanelMinWidth =
      _TradeScreenDealBookContract.dealBookTwoPanelMinWidth;
  static const String dealBookBidsPanelTitle =
      _TradeScreenDealBookContract.dealBookBidsPanelTitle;
  static const String dealBookOffersPanelTitle =
      _TradeScreenDealBookContract.dealBookOffersPanelTitle;
  static const String dealBookFilledHeading =
      _TradeScreenDealBookContract.dealBookFilledHeading;
  static const String dealBookUnfilledHeading =
      _TradeScreenDealBookContract.dealBookUnfilledHeading;
  static const String dealBookBidsEmptyText =
      _TradeScreenDealBookContract.dealBookBidsEmptyText;
  static const String dealBookOffersEmptyText =
      _TradeScreenDealBookContract.dealBookOffersEmptyText;
  static const String dealBookTotalSpentLabel =
      _TradeScreenDealBookContract.dealBookTotalSpentLabel;
  static const String dealBookTotalReceivedLabel =
      _TradeScreenDealBookContract.dealBookTotalReceivedLabel;
  static String formatFilledDealUnitPrice(double pricePerUnit) =>
      _TradeScreenDealBookContract.formatFilledDealUnitPrice(pricePerUnit);
  static const String dealBookFilledEmptyText =
      _TradeScreenDealBookContract.dealBookFilledEmptyText;
  static const String dealBookUnfilledEmptyText =
      _TradeScreenDealBookContract.dealBookUnfilledEmptyText;
  static const String dealBookTabLabel =
      _TradeScreenDealBookContract.dealBookTabLabel;
}
