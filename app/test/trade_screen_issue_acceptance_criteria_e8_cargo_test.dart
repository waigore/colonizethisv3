// Issue-AC-mapped widget tests for `TradeScreen` (`#2993` E8).
// SPEC/ui/trade-screen.md.
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_e8_test_helpers.dart';
import 'trade_screen_e8_market_helpers.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() => tradeE8InitRouteHostHive(suiteId: 'trade_screen_e8_cargo'));

  group('AC #5 — Cross-commodity cargo cap: capacity 10 with attempted bids '
      'totalling 12 across commodities clamps the indicator to 0, caps the '
      'offending stepper, and mounts the warning (#2993 E8 (e))', () {
    testWidgets('Given tradeCargoCapacity == 10, staging Bid timber qty 6 then '
        'staging Bid iron qty 4 saturates the cargo (indicator: '
        '"Cargo remaining: 0", warning mounted). A subsequent attempt to '
        'add 2 more units (the 12th unit of cross-commodity bids) by '
        'either toggling a third commodity to Bid or incrementing an '
        'existing bid is rejected — the staged bid total never exceeds '
        '10 and the warning row stays mounted.', (tester) async {
      final ProviderContainer container = await tradeE8PumpMarket(
        tester,
        treasury: 100000,
        tradeCargoCapacityOverride: 10,
        initialOrders: tradeE8OrdersWith(<TradeOrder>[
          tradeE8Bid(kTradeE8Timber, 6),
          tradeE8Bid(kTradeE8Iron, 4),
        ]),
      );

      expectTradeE8CargoSaturated(tester);

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kTradeE8Timber)),
      );
      await tester.pump();
      expect(tradeE8StagedOrder(container, kTradeE8Timber)?.quantity, 6);

      await tradeE8TapBid(tester, kTradeE8Grain);
      expect(tradeE8StagedOrder(container, kTradeE8Grain), isNull);

      final Orders orders = container.read(currentOrdersProvider);
      final int totalBidUnits =
          orders.tradeOrdersByPlayerId[kTradeE8HumanPlayerId]
              ?.where((TradeOrder o) => o.type == TradeOrderType.bid)
              .fold<int>(0, (sum, o) => sum + o.quantity) ??
          0;
      expect(totalBidUnits, 10);
      expectTradeE8CargoSaturated(tester);
    });

    testWidgets(
      'Toggle clamp: with timber 9 + offer fabric 5 (cargo remaining 1), '
      'tapping `Bid` on fabric clamps the new staged quantity to the '
      'remaining cargo (1, not the prior offer\'s 5)',
      (tester) async {
        final ProviderContainer container = await tradeE8PumpMarket(
          tester,
          treasury: 100000,
          tradeCargoCapacityOverride: 10,
          overtureStates: const <OvertureState>[
            OvertureState(
              gpId: kTradeE8HumanPlayerId,
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
          initialOrders: tradeE8OrdersWith(<TradeOrder>[
            tradeE8Bid(kTradeE8Timber, 9),
            tradeE8Offer(kTradeE8Fabric, 5),
          ]),
        );

        await tradeE8TapBid(tester, kTradeE8Fabric);

        final TradeOrder? fabric = tradeE8StagedOrder(
          container,
          kTradeE8Fabric,
        );
        expect(fabric?.type, TradeOrderType.bid);
        expect(fabric?.quantity, 1);
        expectTradeE8CargoSaturated(tester);
      },
    );
  });

  group('AC #6 — Observe mode disables bid/offer controls and surfaces the '
      'Observe-mode indicator (#2993 E8 (f))', () {
    testWidgets('Global observe mode (shellPanelsNotDefined == true): the body '
        'short-circuits to ObserveModeNotDefinedPanel(title: "Trade"); '
        'no Market or Deal Book tab bodies and no bid/offer chips or '
        'stepper buttons are mounted, but the dark CtTopBar chrome '
        'still paints', (tester) async {
      await tradeE8OpenTradeFromRouteHost(tester, globalObserve: true);
      expectTradeE8ObserveModeBlocksMarket(tester);
    });

    testWidgets('Per-GP observe variant (canMutateViaUi == false, not global '
        'observe): the Market tab body remains mounted (read-only data '
        'still renders) but the IgnorePointer wrapper blocks taps; '
        'currentOrdersProvider is not mutated when the player tries '
        'to stage a Bid', (tester) async {
      final ProviderContainer container = await tradeE8PumpMarket(
        tester,
        canMutateViaUi: false,
      );

      expect(
        find.byKey(TradeScreenMarketKeys.marketTabBodyKey),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(kTradeE8Timber)),
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(kTradeE8Timber)),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(tradeE8StagedOrder(container, kTradeE8Timber), isNull);
    });
  });
}
