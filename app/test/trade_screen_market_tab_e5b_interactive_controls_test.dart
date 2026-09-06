// Widget tests for the Market tab interactive bid/offer/quantity
// controls (Refs #2993 E5b). SPEC/ui/trade-screen.md § Body — Market

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_market_tab_e5b_support.dart';

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab interactive controls (Refs #2993 E5b)', () {
    testWidgets('every tradeable row exposes None / Bid / Offer chips and the '
        '`+` / quantity / `−` stepper widgets keyed per commodity', (
      tester,
    ) async {
      await pumpE5bFilledTradeScreen(tester);

      for (final Commodity c in CommodityCatalog.all) {
        if (c.category == CommodityCategory.riches || c.id == 'spices') {
          continue;
        }
        final Finder row = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(c.id),
        );
        expect(row, findsOneWidget);
        final List<(Key, String)> keyedControls = <(Key, String)>[
          (TradeScreenMarketKeys.marketRowNoneChipKey(c.id), '`None` chip'),
          (TradeScreenMarketKeys.marketRowBidChipKey(c.id), '`Bid` chip'),
          (TradeScreenMarketKeys.marketRowOfferChipKey(c.id), '`Offer` chip'),
          (
            TradeScreenMarketKeys.marketRowDecrementKey(c.id),
            'decrement button',
          ),
          (
            TradeScreenMarketKeys.marketRowIncrementKey(c.id),
            'increment button',
          ),
          (
            TradeScreenMarketKeys.marketRowQuantityTextKey(c.id),
            'quantity readout',
          ),
        ];
        for (final (Key key, String label) in keyedControls) {
          expect(
            find.descendant(of: row, matching: find.byKey(key)),
            findsOneWidget,
            reason: 'commodity `${c.id}` row must mount its $label.',
          );
        }
      }
    });

    testWidgets('tapping `Bid` on an unstaged row stages a TradeOrder with '
        'type=bid, quantity=1, priority=1 in currentOrdersProvider', (
      tester,
    ) async {
      final ProviderContainer container = await pumpE5bFilledTradeScreen(tester);
      expect(e5bStagedOrder(container, kE5bTimber), isNull);

      await tapE5bKey(tester, TradeScreenMarketKeys.marketRowBidChipKey(kE5bTimber));

      final TradeOrder? staged = e5bStagedOrder(container, kE5bTimber);
      expect(staged, isNotNull);
      expect(staged!.commodityId, kE5bTimber);
      expect(staged.type, TradeOrderType.bid);
      expect(
        staged.quantity,
        TradeScreenMarketKeys.marketRowQuantityDefault,
        reason:
            'Refs #2993 E5b: a freshly toggled Bid stages '
            'quantity=1 (the stepper minimum). Subsequent + taps '
            'increment from there.',
      );
      expect(
        staged.priority,
        TradeScreenMarketKeys.marketRowDefaultPriority,
        reason:
            'Refs #2993 E5b: priority defaults to 1 until the '
            'priority dropdown ships in a follow-up slice.',
      );
    });

    testWidgets('tapping `Offer` on a row that already has a staged bid '
        'REPLACES the prior bid (mutual exclusion: at most one staged '
        'TradeOrder per commodity)', (tester) async {
      final ProviderContainer container = await pumpE5bFilledTradeScreen(tester);

      await tapE5bKey(tester, TradeScreenMarketKeys.marketRowBidChipKey(kE5bTimber));
      await tapE5bKey(
        tester,
        TradeScreenMarketKeys.marketRowIncrementKey(kE5bTimber),
      );
      TradeOrder? staged = e5bStagedOrder(container, kE5bTimber);
      expect(staged, isNotNull);
      expect(staged!.type, TradeOrderType.bid);
      expect(staged.quantity, 2);

      await tapE5bKey(
        tester,
        TradeScreenMarketKeys.marketRowOfferChipKey(kE5bTimber),
      );
      staged = e5bStagedOrder(container, kE5bTimber);
      expect(staged, isNotNull);
      expect(staged!.type, TradeOrderType.offer);
      expect(staged.quantity, 2);

      final Orders orders = container.read(currentOrdersProvider);
      final List<TradeOrder>? list =
          orders.tradeOrdersByPlayerId[kE5bHumanPlayerId];
      expect(list, isNotNull);
      final int timberCount = list!
          .where((TradeOrder o) => o.commodityId == kE5bTimber)
          .length;
      expect(
        timberCount,
        1,
        reason:
            'Refs #2993 E5b mutual exclusion: tradeOrdersByPlayerId '
            'must contain at most one TradeOrder per (player, '
            'commodityId) pair.',
      );
    });

    testWidgets('tapping `None` on a row with a staged direction removes the '
        'TradeOrder for the commodity from currentOrdersProvider', (
      tester,
    ) async {
      final ProviderContainer container = await pumpE5bFilledTradeScreen(tester);
      await tapE5bKey(tester, TradeScreenMarketKeys.marketRowBidChipKey(kE5bTimber));
      expect(e5bStagedOrder(container, kE5bTimber), isNotNull);

      await tapE5bKey(
        tester,
        TradeScreenMarketKeys.marketRowNoneChipKey(kE5bTimber),
      );
      expect(
        e5bStagedOrder(container, kE5bTimber),
        isNull,
        reason:
            'Refs #2993 E5b: tapping the None chip removes the '
            'staged TradeOrder for the row\'s commodity.',
      );
    });

    testWidgets('`+` increments quantity by 1 and `−` decrements by 1 (clamped '
        'at marketRowQuantityMin = 1 when a direction is staged)', (
      tester,
    ) async {
      final ProviderContainer container = await pumpE5bFilledTradeScreen(tester);
      await tapE5bKey(tester, TradeScreenMarketKeys.marketRowBidChipKey(kE5bTimber));
      expect(e5bStagedOrder(container, kE5bTimber)!.quantity, 1);

      for (int i = 0; i < 3; i++) {
        await tapE5bKey(
          tester,
          TradeScreenMarketKeys.marketRowIncrementKey(kE5bTimber),
        );
      }
      expect(e5bStagedOrder(container, kE5bTimber)!.quantity, 4);

      for (int i = 0; i < 3; i++) {
        await tapE5bKey(
          tester,
          TradeScreenMarketKeys.marketRowDecrementKey(kE5bTimber),
        );
      }
      expect(e5bStagedOrder(container, kE5bTimber)!.quantity, 1);

      await tapE5bKey(
        tester,
        TradeScreenMarketKeys.marketRowDecrementKey(kE5bTimber),
      );
      expect(
        e5bStagedOrder(container, kE5bTimber)!.quantity,
        TradeScreenMarketKeys.marketRowQuantityMin,
        reason:
            'Refs #2993 E5b: the per-row stepper clamps at '
            '`marketRowQuantityMin = 1` while a direction is '
            'staged (going below 1 is equivalent to None and is '
            'reached via the None chip, not the decrement button).',
      );
    });

    testWidgets(
      'increment / decrement buttons are no-ops while no direction is '
      'staged (the `−` and `+` taps must not create a TradeOrder)',
      (tester) async {
        final ProviderContainer container = await pumpE5bFilledTradeScreen(tester);
        await tapE5bKey(
          tester,
          TradeScreenMarketKeys.marketRowIncrementKey(kE5bTimber),
        );
        await tapE5bKey(
          tester,
          TradeScreenMarketKeys.marketRowDecrementKey(kE5bTimber),
        );
        expect(
          e5bStagedOrder(container, kE5bTimber),
          isNull,
          reason:
              'Refs #2993 E5b: stepper taps without a staged '
              'direction are silent no-ops (the user picks Bid / '
              'Offer first; the stepper then adjusts the staged '
              'TradeOrder.quantity).',
        );
      },
    );
  });
}
