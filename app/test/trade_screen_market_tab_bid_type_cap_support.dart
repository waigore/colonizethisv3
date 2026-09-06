// Helpers for Trade Market tab bid-type cap widget tests (Refs #4734 Slice G).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String kBidTypeCapHumanPlayerId = kTradeTestHumanPlayerId;

const CommodityId kBidTypeCapTimber = 'timber';
const CommodityId kBidTypeCapIron = 'iron';
const CommodityId kBidTypeCapGrain = 'grain';

Orders bidTypeCapOrders(List<TradeOrder> tradeOrders) {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      kBidTypeCapHumanPlayerId: tradeOrders,
    },
  );
}

TradeOrder bidTypeCapBid(CommodityId commodityId, int quantity) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: 1,
  );
}

TradeOrder? bidTypeCapStagedOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list =
      orders.tradeOrdersByPlayerId[kBidTypeCapHumanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

String bidTypeCapIndicatorText(WidgetTester tester) {
  final Text widget = tester.widget<Text>(
    find.byKey(TradeScreenMarketKeys.marketBidGoodsIndicatorKey),
  );
  return widget.data!;
}

Finder bidTypeCapBidChip(CommodityId commodityId) {
  return find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(commodityId));
}
