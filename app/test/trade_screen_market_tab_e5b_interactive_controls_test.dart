// Widget tests for the Market tab interactive bid/offer/quantity
// controls (Refs #2993 E5b). SPEC/ui/trade-screen.md § Body — Market
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

CommodityId get _timber => CommodityCatalog.timber.id;
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

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab interactive controls (Refs #2993 E5b)', () {
    testWidgets('every tradeable row exposes None / Bid / Offer chips and the '
        '`+` / quantity / `−` stepper widgets keyed per commodity', (
      tester,
    ) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
      );

      for (final Commodity c in CommodityCatalog.all) {
        if (c.category == CommodityCategory.riches || c.id == 'spices') {
          continue;
        }
        final row = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey(c.id),
        );
        expect(row, findsOneWidget);
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowNoneChipKey(c.id),
            ),
          ),
          findsOneWidget,
          reason: 'commodity `${c.id}` row must mount its `None` chip.',
        );
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowBidChipKey(c.id),
            ),
          ),
          findsOneWidget,
          reason: 'commodity `${c.id}` row must mount its `Bid` chip.',
        );
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowOfferChipKey(c.id),
            ),
          ),
          findsOneWidget,
          reason: 'commodity `${c.id}` row must mount its `Offer` chip.',
        );
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowDecrementKey(c.id),
            ),
          ),
          findsOneWidget,
          reason: 'commodity `${c.id}` row must mount its decrement button.',
        );
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowIncrementKey(c.id),
            ),
          ),
          findsOneWidget,
          reason: 'commodity `${c.id}` row must mount its increment button.',
        );
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(
              TradeScreenMarketKeys.marketRowQuantityTextKey(c.id),
            ),
          ),
          findsOneWidget,
          reason: 'commodity `${c.id}` row must mount its quantity readout.',
        );
      }
    });

    testWidgets('tapping `Bid` on an unstaged row stages a TradeOrder with '
        'type=bid, quantity=1, priority=1 in currentOrdersProvider', (
      tester,
    ) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
      );
      expect(_stagedOrder(container, _timber), isNull);

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
      );
      await tester.pump();

      final TradeOrder? staged = _stagedOrder(container, _timber);
      expect(staged, isNotNull);
      expect(staged!.commodityId, _timber);
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
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
      );

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
      );
      await tester.pump();
      // After Bid + one increment: timber bid, quantity=2.
      TradeOrder? staged = _stagedOrder(container, _timber);
      expect(staged, isNotNull);
      expect(staged!.type, TradeOrderType.bid);
      expect(staged.quantity, 2);

      // Toggle to Offer: the prior bid must be replaced by an
      // offer. Quantity is preserved (2) since it tracks the
      // staged direction's quantity.
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowOfferChipKey(_timber)),
      );
      await tester.pump();
      staged = _stagedOrder(container, _timber);
      expect(staged, isNotNull);
      expect(staged!.type, TradeOrderType.offer);
      expect(staged.quantity, 2);

      // Mutual exclusion: list contains at most one staged
      // TradeOrder for the timber commodity.
      final Orders orders = container.read(currentOrdersProvider);
      final List<TradeOrder>? list =
          orders.tradeOrdersByPlayerId[_humanPlayerId];
      expect(list, isNotNull);
      final int timberCount = list!
          .where((TradeOrder o) => o.commodityId == _timber)
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
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
      );
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
      );
      await tester.pump();
      expect(_stagedOrder(container, _timber), isNotNull);

      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowNoneChipKey(_timber)),
      );
      await tester.pump();
      expect(
        _stagedOrder(container, _timber),
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
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
      );
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
      );
      await tester.pump();
      // Initial quantity: 1.
      expect(_stagedOrder(container, _timber)!.quantity, 1);

      // + → 2 → 3 → 4
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
      );
      await tester.pump();
      expect(_stagedOrder(container, _timber)!.quantity, 4);

      // − → 3 → 2 → 1
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)),
      );
      await tester.pump();
      expect(_stagedOrder(container, _timber)!.quantity, 1);

      // Further − is a no-op (clamped at the lower bound of 1).
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)),
      );
      await tester.pump();
      expect(
        _stagedOrder(container, _timber)!.quantity,
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
        final ProviderContainer container = await pumpTradeScreenWithContainer(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_e5b',
            stockpile: tradeableStockpileFilled(99),
          ),
        );
        // No staged direction yet — increment must NOT auto-stage a
        // bid/offer. The +/- buttons only operate on already-staged
        // TradeOrders. The user must pick a direction first.
        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowIncrementKey(_timber)),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(TradeScreenMarketKeys.marketRowDecrementKey(_timber)),
        );
        await tester.pump();
        expect(
          _stagedOrder(container, _timber),
          isNull,
          reason:
              'Refs #2993 E5b: stepper taps without a staged '
              'direction are silent no-ops (the user picks Bid / '
              'Offer first; the stepper then adjusts the staged '
              'TradeOrder.quantity).',
        );
      },
    );

    testWidgets('mutual exclusion across distinct commodities — staging timber '
        'as Bid and fabric as Offer keeps both as a single TradeOrder '
        'each in currentOrdersProvider', (tester) async {
      final ProviderContainer container = await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_e5b',
          stockpile: tradeableStockpileFilled(99),
        ),
      );
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowBidChipKey(_timber)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(TradeScreenMarketKeys.marketRowOfferChipKey(_fabric)),
      );
      await tester.pump();

      expect(_stagedOrder(container, _timber)?.type, TradeOrderType.bid);
      expect(_stagedOrder(container, _fabric)?.type, TradeOrderType.offer);
      final Orders orders = container.read(currentOrdersProvider);
      expect(
        orders.tradeOrdersByPlayerId[_humanPlayerId]?.length,
        2,
        reason:
            'Refs #2993 E5b: the player can stage one TradeOrder '
            'per commodity simultaneously; mutual exclusion is '
            'per-commodity, not per-player.',
      );
    });
  });
}
