// Widget tests for the Market tab cross-commodity cargo-remaining
// indicator + per-stepper cap + warning row (Refs #2993 E5c).
// SPEC/ui/trade-screen.md § Cargo indicator + per-stepper cap +
//  * Offers do not consume cargo (per #2988 § Cargo Constraint Model).
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

      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoIndicatorKey),
        findsOneWidget,
      );
      expect(_cargoIndicatorText(tester), 'Cargo remaining: 24');
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsNothing,
      );
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
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsNothing,
      );
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
        expect(
          find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
          findsNothing,
        );
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
      expect(
        find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
        findsOneWidget,
      );
      expect(
        find.text(TradeScreenMarketKeys.cargoLimitWarningText),
        findsOneWidget,
      );
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
        expect(
          find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
          findsNothing,
        );

        for (int i = 0; i < 4; i++) {
          await tester.tap(
            find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
          );
          await tester.pump();
        }
        expect(_stagedOrder(container, _timber)?.quantity, 10);
        expect(_totalStagedBid(container), 10);
        expect(_cargoIndicatorText(tester), 'Cargo remaining: 0');
        expect(
          find.byKey(TradeScreenMarketKeys.marketCargoWarningKey),
          findsOneWidget,
        );

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
    // Remaining cargo-action ACs: trade_screen_market_tab_e5c_cargo_cap_actions_test.dart
  });
}
