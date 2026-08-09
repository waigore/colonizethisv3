// Widget tests for the Market tab cross-commodity cargo-remaining
// indicator + per-stepper cap + warning row (Refs #2993 E5c).
// SPEC/ui/trade-screen.md § Cargo indicator + per-stepper cap +
// warning.
//
// Exercises the durable contract for the E5c cargo telemetry and cap:
//
//  * The cargo indicator (`marketCargoIndicatorKey`) is always
//    mounted in the Market tab body and renders `Cargo remaining: X`
//    where `X = max(0, tradeCargoCapacity − totalStagedBidQuantity)`.
//  * `tradeCargoCapacity` comes from `cargoHoldsForHomeFleet` and
//    falls back to `defaultCargoHoldsStub = 24` when the player has
//    no home fleet.
//  * Offers do not consume cargo (per #2988 § Cargo Constraint Model).
//  * The warning row (`marketCargoWarningKey`) is only mounted when
//    `remainingCargo == 0` AND `totalStagedBidQuantity > 0`; absent
//    otherwise.
//  * Bid increments are blocked when the cross-commodity bid total
//    would exceed `tradeCargoCapacity`; the staged TradeOrder.quantity
//    stays at its prior value and the indicator + warning state stays
//    consistent.
//  * Toggling a row to `Bid` is clamped: the staged quantity =
//    min(desiredQuantity, maxAllowedBidQuantity); the cross-commodity
//    bid total never exceeds `tradeCargoCapacity`.
//  * Toggling a row to `Bid` is a silent no-op when
//    `maxAllowedBidQuantity <= 0` (cargo budget already saturated by
//    other commodities).
//  * Decrement and `None` free cargo: the indicator updates and the
//    warning row is removed when the cap is no longer saturated.
//  * Observe-mode (`canMutateViaUi == false`): the cargo indicator and
//    warning still mount with live text values; the chip / stepper
//    taps are blocked by the existing `IgnorePointer` wrapper.

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

  group('TradeScreen Market tab cargo indicator + cap + warning '
      '(Refs #2993 E5c)', () {
    testWidgets('no home fleet and no staged orders → indicator reads '
        '"Cargo remaining: 24" (defaultCargoHoldsStub) and the '
        'warning row is absent', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(id: 'test_trade_screen_e5c', treasury: 100000),
      );

      expect(find.byKey(TradeScreenMarketKeys.marketCargoIndicatorKey), findsOneWidget);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 24');
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);
    });

    testWidgets('staged offers do not consume cargo → indicator stays at the '
        'full capacity and the warning row is absent', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(id: 'test_trade_screen_e5c', treasury: 100000),
        initialOrders: _orders(<TradeOrder>[
          _offer(_fabric, 7),
          _offer(_timber, 3),
        ]),
      );

      expect(_cargoIndicatorText(tester), 'Cargo remaining: 24');
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);
    });

    testWidgets(
      'staged bids totalling 7 (timber 4 + iron 3) under capacity 24 → '
      'indicator reads "Cargo remaining: 17" and no warning is shown',
      (tester) async {
        await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_e5c',
            treasury: 100000,
          ),
          initialOrders: _orders(<TradeOrder>[
            _bid(_timber, 4),
            _bid(_iron, 3),
          ]),
        );

        expect(_cargoIndicatorText(tester), 'Cargo remaining: 17');
        expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);
      },
    );

    testWidgets('capacity 10 with bids totalling 10 → indicator reads '
        '"Cargo remaining: 0" AND the warning row is mounted with '
        'the canonical copy', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5c',
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
        ),
        initialOrders: _orders(<TradeOrder>[_bid(_timber, 6), _bid(_iron, 4)]),
      );

      expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);
      expect(find.text(TradeScreenMarketKeys.cargoLimitWarningText), findsOneWidget);
    });

    testWidgets(
      'capacity 10 with bid timber 6 (cargo remaining 4): incrementing '
      'timber `+` four times brings staged quantity to 10 then the '
      'fifth `+` tap is a silent no-op (cross-commodity total clamped '
      'at 10) and the warning row mounts at saturation',
      (tester) async {
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_e5c',
            treasury: 100000,
            tradeCargoCapacityOverride: 10,
          ),
          initialOrders: _orders(<TradeOrder>[_bid(_timber, 6)]),
        );

        expect(_cargoIndicatorText(tester), 'Cargo remaining: 4');
        expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);

        for (int i = 0; i < 4; i++) {
          await tester.tap(
            find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
          );
          await tester.pump();
        }
        expect(_stagedOrder(container, _timber)?.quantity, 10);
        expect(_totalStagedBid(container), 10);
        expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
        expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);

        // 5th increment is blocked by the cross-commodity cap.
        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
        );
        await tester.pump();
        expect(
          _stagedOrder(container, _timber)?.quantity,
          10,
          reason:
              'Refs #2993 E5c: bid increment blocked when '
              'cross-commodity bid total saturates tradeCargoCapacity.',
        );
        expect(_totalStagedBid(container), 10);
      },
    );

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

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_grain)));
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
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);
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

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_fabric)));
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

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_fabric)));
      await tester.pump();

      final TradeOrder? fabric = _stagedOrder(container, _fabric);
      expect(fabric?.type, TradeOrderType.bid);
      expect(fabric?.quantity, 8);
      expect(_totalStagedBid(container), 8);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 2');
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);
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

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_fabric)));
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
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);
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
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)));
      await tester.pump();

      expect(_stagedOrder(container, _timber)?.quantity, 9);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 1');
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);
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

      await tester.tap(find.byKey(TradeScreenMarketKeys.marketRowNoneChipKey(_timber)));
      await tester.pump();

      expect(_stagedOrder(container, _timber), isNull);
      expect(_totalStagedBid(container), 0);
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 10');
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsNothing);
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
      expect(find.byKey(TradeScreenMarketKeys.marketCargoWarningKey), findsOneWidget);

      // Attempting to tap the increment / None chip is swallowed by
      // IgnorePointer (`warnIfMissed: false` silences the expected
      // hit-test warning that surfaces when the wrapper absorbs
      // the pointer event).
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
