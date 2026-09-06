// Helpers for Trade Market tab E5b interactive control tests (Refs #4734 Slice G).

import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String kE5bHumanPlayerId = kTradeTestHumanPlayerId;

CommodityId get kE5bTimber => CommodityCatalog.timber.id;
CommodityId get kE5bFabric => CommodityCatalog.fabric.id;

TradeOrder? e5bStagedOrder(
  ProviderContainer container,
  CommodityId commodityId,
) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[kE5bHumanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

Future<ProviderContainer> pumpE5bFilledTradeScreen(WidgetTester tester) {
  return pumpTradeScreenWithContainer(
    tester,
    game: buildTradeTestGame(
      id: 'test_trade_screen_e5b',
      stockpile: tradeableStockpileFilled(99),
    ),
  );
}

Future<void> tapE5bKey(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await tester.pump();
}
