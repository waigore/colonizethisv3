// Market-tab cargo-cap release / observe ACs (Refs #4606 Slice D).
// SPEC/ui/trade-screen.md § Cargo indicator. Host:
// trade_screen_market_tab_e5c_cargo_cap_test.dart.
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

Orders _orders(List<TradeOrder> tradeOrders) {
  return Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      _humanPlayerId: tradeOrders,
    },
  );
}

TradeOrder _bid(CommodityId commodityId, int quantity) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.bid,
    quantity: quantity,
    priority: 1,
  );
}

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;

TradeOrder? _stagedOrder(ProviderContainer container, CommodityId commodityId) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null) return null;
  for (final TradeOrder o in list) {
    if (o.commodityId == commodityId) return o;
  }
  return null;
}

int _totalStagedBid(ProviderContainer container) {
  final Orders orders = container.read(currentOrdersProvider);
  final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[_humanPlayerId];
  if (list == null || list.isEmpty) return 0;
  int total = 0;
  for (final TradeOrder o in list) {
    if (o.type == TradeOrderType.bid) total += o.quantity;
  }
  return total;
}

String _cargoIndicatorText(WidgetTester tester) {
  final Text widget = tester.widget<Text>(
    find.byKey(TradeScreenMarketKeys.marketCargoIndicatorKey),
  );
  return widget.data ?? '';
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab cargo actions (Refs #2993 E5c)', () {
    testWidgets('capacity 10 saturated with bid timber 10: tapping `−` on '
        'timber frees one unit of cargo, removes the warning row, and '
        'updates the indicator to "Cargo remaining: 1"', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[_bid(_timber, 10)]),
      );

      expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)),
      );
      await tester.pump();

      expect(_stagedOrder(container, _timber)?.quantity, 9);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 1');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsNothing,
      );
    });
    testWidgets('capacity 10 saturated with bid timber 10: tapping `None` on '
        'timber removes the staged TradeOrder, frees the entire cargo '
        'budget, and removes the warning row', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[_bid(_timber, 10)]),
      );

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowNoneChipKey(_timber)),
      );
      await tester.pump();

      expect(_stagedOrder(container, _timber), isNull);
      expect(_totalStagedBid(container), 0);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 10');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsNothing,
      );
    });
    testWidgets('observe mode (canMutateViaUi == false): the cargo indicator '
        'and warning row stay mounted with live text values; the chip '
        'taps are blocked by the existing IgnorePointer wrapper so '
        'currentOrdersProvider is not mutated', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[_bid(_timber, 6), _bid(_iron, 4)]),
        canMutateViaUi: false,
      );

      expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowNoneChipKey(_timber)),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(
        _stagedOrder(container, _timber)?.quantity,
        6,
        reason: 'Observe mode must not mutate currentOrdersProvider.',
      );
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
    });
  });
}
