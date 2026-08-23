// Remaining Market-tab cargo-cap ACs (Refs #4606 Slice D).
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

TradeOrder _offer(CommodityId commodityId, int quantity) {
  return TradeOrder(
    commodityId: commodityId,
    type: TradeOrderType.offer,
    quantity: quantity,
    priority: 1,
  );
}

CommodityId get _timber => CommodityCatalog.timber.id;
CommodityId get _iron => CommodityCatalog.iron.id;
CommodityId get _fabric => CommodityCatalog.fabric.id;
CommodityId get _grain => CommodityCatalog.grain.id;

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
    testWidgets('capacity 10 with cargo saturated (timber 6 + iron 4): tapping '
        '`Bid` on a fresh commodity (grain) is a silent no-op — no '
        'TradeOrder for grain is staged and the cross-commodity bid '
        'total stays at 10', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[_bid(_timber, 6), _bid(_iron, 4)]),
      );

      expect(_stagedOrder(container, _grain), isNull);

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_grain)),
      );
      await tester.pump();

      expect(
        _stagedOrder(container, _grain),
        isNull,
        reason:
            'Refs #2993 E5c: Bid toggle is a no-op when '
            'maxAllowedBidQuantity <= 0.',
      );
      expect(_totalStagedBid(container), 10);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsOneWidget,
      );
    });
    testWidgets('capacity 10 with cargo saturated and a staged offer: tapping '
        '`Bid` on the offer row is also blocked (the prior offer '
        'survives because the toggle is rejected)', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[
          _bid(_timber, 6),
          _bid(_iron, 4),
          _offer(_fabric, 5),
        ]),
      );

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_fabric)),
      );
      await tester.pump();

      final TradeOrder? fabric = _stagedOrder(container, _fabric);
      expect(
        fabric?.type,
        TradeOrderType.offer,
        reason:
            'Refs #2993 E5c: bid toggle is rejected when '
            'maxAllowedBidQuantity <= 0; the prior offer stays.',
      );
      expect(fabric?.quantity, 5);
      expect(_totalStagedBid(container), 10);
    });
    testWidgets('capacity 10 with offer fabric 8 (cargo remaining 10): tapping '
        '`Bid` on fabric preserves the prior quantity (8 ≤ 10) and '
        'reduces cargo remaining to 2', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[_offer(_fabric, 8)]),
      );

      expect(_cargoIndicatorText(tester), 'Cargo remaining: 10');

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_fabric)),
      );
      await tester.pump();

      final TradeOrder? fabric = _stagedOrder(container, _fabric);
      expect(fabric?.type, TradeOrderType.bid);
      expect(fabric?.quantity, 8);
      expect(_totalStagedBid(container), 8);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 2');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsNothing,
      );
    });
    testWidgets('capacity 10 with bid timber 9 (cargo remaining 1) AND offer '
        'fabric 5: tapping `Bid` on fabric clamps the new staged '
        'quantity to the remaining cargo (1, not the prior 5)', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
          overtureStates: const <OvertureState>[
            OvertureState(
              gpId: _humanPlayerId,
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
        ),
        initialOrders: _orders(<TradeOrder>[
          _bid(_timber, 9),
          _offer(_fabric, 5),
        ]),
      );

      expect(_cargoIndicatorText(tester), 'Cargo remaining: 1');

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_fabric)),
      );
      await tester.pump();

      final TradeOrder? fabric = _stagedOrder(container, _fabric);
      expect(fabric?.type, TradeOrderType.bid);
      expect(
        fabric?.quantity,
        1,
        reason:
            'Refs #2993 E5c: bid toggle clamps quantity to '
            'maxAllowedBidQuantity (remainingCargo + priorBidContribution).',
      );
      expect(_totalStagedBid(container), 10);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsOneWidget,
      );
    });
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
