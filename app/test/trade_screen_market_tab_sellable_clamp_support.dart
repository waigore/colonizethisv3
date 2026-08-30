// Helpers for Trade Market tab sellable-clamp widget tests (Refs #4582).

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String kSellableClampHumanPlayerId = kTradeTestHumanPlayerId;

CommodityId get kSellableClampTimber => CommodityCatalog.timber.id;
CommodityId get kSellableClampIron => CommodityCatalog.iron.id;

TradeOrder? stagedSellableClampOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list =
      orders.tradeOrdersByPlayerId[kSellableClampHumanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

Orders sellableClampTradeOrders(TradeOrder order) => Orders(
  tradeOrdersByPlayerId: {
    kSellableClampHumanPlayerId: [order],
  },
);

TradeOrder sellableClampTimberTrade({
  TradeOrderType type = TradeOrderType.offer,
  required int quantity,
}) => TradeOrder(
  commodityId: kSellableClampTimber,
  type: type,
  quantity: quantity,
  priority: 1,
);

void expectSellableClampReadout(
  WidgetTester tester,
  CommodityId commodityId,
  String expected, {
  String? reason,
}) {
  expect(
    tester
        .widget<Text>(
          find.byKey(
            TradeScreenMarketKeys.marketRowSellableReadoutKey(commodityId),
          ),
        )
        .data,
    // ignore: avoid_hardcoded_strings_in_widgets
    expected,
    reason: reason,
  );
}

Future<void> tapSellableClampKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
}
