/// Public Market-tab (and shared chrome) keys/literals for the trade screen.
/// Row-level literals live in [TradeScreenMarketRowKeys] (private).
/// Tests and Market UI parts use this type directly (Refs #4035 trade API collapse).
/// Split into sibling modules; this file is the stable facade (Refs #4352).
library;

import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_contract_market_chrome.dart';
import 'trade_screen_contract_market_header_copy.dart';
import 'trade_screen_contract_market_layout.dart';
import 'trade_screen_contract_market_row_keys.dart';
import 'trade_screen_contract_market_row_sizes.dart';

abstract final class TradeScreenMarketKeys {
  TradeScreenMarketKeys._();

  static const String topBarBackLabel =
      TradeScreenMarketChromeKeys.topBarBackLabel;

  static const String topBarTitle = TradeScreenMarketChromeKeys.topBarTitle;

  static const String topBarIconAsset =
      TradeScreenMarketChromeKeys.topBarIconAsset;

  static const Key topBarKey = TradeScreenMarketChromeKeys.topBarKey;

  static const Key tabsBodyKey = TradeScreenMarketChromeKeys.tabsBodyKey;

  static const Key marketTabBodyKey =
      TradeScreenMarketChromeKeys.marketTabBodyKey;

  static const Key marketCommodityListKey =
      TradeScreenMarketChromeKeys.marketCommodityListKey;

  static const double marketTwoColumnMinWidth =
      TradeScreenMarketLayoutKeys.marketTwoColumnMinWidth;

  static const double marketGridColumnGap =
      TradeScreenMarketLayoutKeys.marketGridColumnGap;

  static const double marketGridRowGap =
      TradeScreenMarketLayoutKeys.marketGridRowGap;

  static const Key marketSectionFoodKey =
      TradeScreenMarketLayoutKeys.marketSectionFoodKey;

  static const Key marketSectionRawMaterialsKey =
      TradeScreenMarketLayoutKeys.marketSectionRawMaterialsKey;

  static const Key marketSectionManufacturedKey =
      TradeScreenMarketLayoutKeys.marketSectionManufacturedKey;

  static Key marketCommodityRowKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketCommodityRowKey(commodityId);

  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowNoneChipKey(commodityId);

  static Key marketRowBidChipKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowBidChipKey(commodityId);

  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowOfferChipKey(commodityId);

  static Key marketRowDecrementKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowDecrementKey(commodityId);

  static Key marketRowIncrementKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowIncrementKey(commodityId);

  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowQuantityTextKey(commodityId);

  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowSellableReadoutKey(commodityId);

  static Key marketRowFirstRightChipKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowFirstRightChipKey(commodityId);

  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowResourceIconKey(commodityId);

  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowPriceCoinIconKey(commodityId);

  static Key marketRowPriceDeltaKey(CommodityId commodityId) =>
      TradeScreenMarketRowKeys.marketRowPriceDeltaKey(commodityId);

  static const double marketRowResourceIconSize =
      TradeScreenMarketRowSizes.marketRowResourceIconSize;

  static const double marketRowPriceCoinIconSize =
      TradeScreenMarketRowSizes.marketRowPriceCoinIconSize;

  static const double marketRowPriceColumnWidth =
      TradeScreenMarketRowSizes.marketRowPriceColumnWidth;

  static const double marketRowPriceColumnInnerGap =
      TradeScreenMarketRowSizes.marketRowPriceColumnInnerGap;

  @visibleForTesting
  static ResourceRules? marketPriceResourceRulesOverride;

  static const String marketRowPriceCoinAssetPath =
      TradeScreenMarketRowSizes.marketRowPriceCoinAssetPath;

  static const int marketRowQuantityMin =
      TradeScreenMarketRowSizes.marketRowQuantityMin;

  static const int marketRowQuantityDefault =
      TradeScreenMarketRowSizes.marketRowQuantityDefault;

  static const int marketRowDefaultPriority =
      TradeScreenMarketRowSizes.marketRowDefaultPriority;

  static const String marketRowQuantityIdleGlyph =
      TradeScreenMarketRowSizes.marketRowQuantityIdleGlyph;

  static const Key marketBidGoodsIndicatorKey =
      TradeScreenMarketHeaderCopy.marketBidGoodsIndicatorKey;

  static const Key marketBidTypeWarningKey =
      TradeScreenMarketHeaderCopy.marketBidTypeWarningKey;

  static const Key marketBidGoodsTooltipKey =
      TradeScreenMarketHeaderCopy.marketBidGoodsTooltipKey;

  static const Key marketBidTypeCapGoldenKey =
      TradeScreenMarketHeaderCopy.marketBidTypeCapGoldenKey;

  static const Key marketBidBudgetIndicatorKey =
      TradeScreenMarketHeaderCopy.marketBidBudgetIndicatorKey;

  static const Key marketBidBudgetWarningKey =
      TradeScreenMarketHeaderCopy.marketBidBudgetWarningKey;

  static const Key marketBidBudgetTooltipKey =
      TradeScreenMarketHeaderCopy.marketBidBudgetTooltipKey;

  static const Key marketCargoIndicatorKey =
      TradeScreenMarketHeaderCopy.marketCargoIndicatorKey;

  static const Key marketCargoWarningKey =
      TradeScreenMarketHeaderCopy.marketCargoWarningKey;

  static const Key marketCargoTooltipKey =
      TradeScreenMarketHeaderCopy.marketCargoTooltipKey;

  static const String bidGoodsIndicatorPrefix =
      TradeScreenMarketHeaderCopy.bidGoodsIndicatorPrefix;

  static const String bidTypeLimitWarningText =
      TradeScreenMarketHeaderCopy.bidTypeLimitWarningText;

  static const String bidTypeLimitTooltipCopyCap3 =
      TradeScreenMarketHeaderCopy.bidTypeLimitTooltipCopyCap3;

  static const String bidTypeLimitTooltipCopyCap6 =
      TradeScreenMarketHeaderCopy.bidTypeLimitTooltipCopyCap6;

  static String bidTypeLimitTooltipForCap(int cap) =>
      TradeScreenMarketHeaderCopy.bidTypeLimitTooltipForCap(cap);

  static const String cargoLimitTooltipCopy =
      TradeScreenMarketHeaderCopy.cargoLimitTooltipCopy;

  static const String bidChipBidTypeCapSemanticLabel =
      TradeScreenMarketHeaderCopy.bidChipBidTypeCapSemanticLabel;

  static const String cargoIndicatorPrefix =
      TradeScreenMarketHeaderCopy.cargoIndicatorPrefix;

  static const String cargoLimitWarningText =
      TradeScreenMarketHeaderCopy.cargoLimitWarningText;

  static const String bidBudgetIndicatorPrefix =
      TradeScreenMarketHeaderCopy.bidBudgetIndicatorPrefix;

  static const String bidBudgetLimitWarningText =
      TradeScreenMarketHeaderCopy.bidBudgetLimitWarningText;

  static const String bidBudgetLimitTooltipCopy =
      TradeScreenMarketHeaderCopy.bidBudgetLimitTooltipCopy;

  static const String marketTabLabel =
      TradeScreenMarketChromeKeys.marketTabLabel;
}
