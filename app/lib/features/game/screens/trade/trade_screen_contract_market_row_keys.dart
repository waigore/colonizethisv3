/// Per-row widget keys for the trade screen Market tab (Refs #4352).
library;

import 'package:flutter/material.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

abstract final class TradeScreenMarketRowKeys {
  TradeScreenMarketRowKeys._();

  /// Per-row key for a Market tab commodity row.
  static Key marketCommodityRowKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId');

  /// Per-row key for the `None` direction chip on a Market tab row.
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:none');

  /// Per-row key for the `Bid` direction chip on a Market tab row.
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:bid');

  /// Per-row key for the `Offer` direction chip on a Market tab row.
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:offer');

  /// Per-row key for the decrement button of the quantity stepper.
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:decrement');

  /// Per-row key for the increment button of the quantity stepper.
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:increment');

  /// Per-row key for the quantity readout of the stepper.
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:quantity');

  /// Per-row key for the inline sellable-headroom readout.
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:sellable');

  /// Per-row key for the first-right chip on line 1 (Refs #4226).
  static Key marketRowFirstRightChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:firstRightChip');

  /// Per-row key for the leading `ResourceIcon` paint on line 1.
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:resourceIcon');

  /// Per-row key for the trailing treasury-coin glyph on line 1.
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:priceCoin');

  /// Per-row key for the optional last-turn signed coin delta.
  static Key marketRowPriceDeltaKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:priceDelta');
}
