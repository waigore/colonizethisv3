import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../support/world_market_test_support.dart';
import '../support/turn_phase_test_harness.dart';

/// Market-turn-summary game-event emission for phase 13 (Refs #4270).
void main() {
  group(
    'worldMarketTurnPhaseHandler — market summary event emission (Refs #4270)',
    () {
      test('GP buyer fill emits MarketTurnSummaryEvent with spent total', () {
        final events = <GameEvent>[];
        final game = gameWithTwoGps(
          sellerStockpile: const Stockpile().applyDelta('timber', 10),
          sellerTreasury: 0,
          buyerTreasury: 1000,
          marketPrices: const {'timber': 30},
        );
        final config = worldMarketPhaseConfig(
          orders: gpGpTimberTradeOrders(offerQuantity: 5, bidQuantity: 5),
        ).copyWith(
          eventSink: TurnEventSink(onGameEvent: events.add),
        );

        runTurnPhaseHandler(
          handler: worldMarketTurnPhaseHandler,
          game: game,
          config: config,
        );

        final summaries = events.whereType<MarketTurnSummaryEvent>().toList();
        expect(summaries, hasLength(2));
        final buyerSummary = summaries.firstWhere((e) => e.playerId == 'gpBuyer');
        final sellerSummary =
            summaries.firstWhere((e) => e.playerId == 'gpSeller');
        expect(buyerSummary.totalSpent, 150);
        expect(buyerSummary.totalReceived, 0);
        expect(buyerSummary.carryForwardOrderCount, 0);
        expect(sellerSummary.totalSpent, 0);
        expect(sellerSummary.totalReceived, 150);
        expect(sellerSummary.carryForwardOrderCount, 0);
      });

      test(
        'partial fill emits carry-forward count without overstating spent total',
        () {
          final events = <GameEvent>[];
          final game = gameWithTwoGps(
            sellerStockpile: const Stockpile().applyDelta('timber', 3),
            sellerTreasury: 0,
            buyerTreasury: 1000,
            marketPrices: const {'timber': 30},
          );
          final config = worldMarketPhaseConfig(
            orders: gpGpTimberTradeOrders(offerQuantity: 3, bidQuantity: 10),
          ).copyWith(
            eventSink: TurnEventSink(onGameEvent: events.add),
          );

          runTurnPhaseHandler(
            handler: worldMarketTurnPhaseHandler,
            game: game,
            config: config,
          );

          final buyerSummary = events
              .whereType<MarketTurnSummaryEvent>()
              .singleWhere((e) => e.playerId == 'gpBuyer');
          expect(buyerSummary.totalSpent, 90);
          expect(buyerSummary.carryForwardOrderCount, 1);
        },
      );

      test('idle market turn emits no market summary event', () {
        final events = <GameEvent>[];
        final game = gameWithTwoGps(
          sellerStockpile: Stockpile.empty,
          sellerTreasury: 0,
          buyerTreasury: 0,
          marketPrices: const {'timber': 30},
        );
        final config = worldMarketPhaseConfig(
          orders: const Orders(),
        ).copyWith(
          eventSink: TurnEventSink(onGameEvent: events.add),
        );

        runTurnPhaseHandler(
          handler: worldMarketTurnPhaseHandler,
          game: game,
          config: config,
        );

        expect(events.whereType<MarketTurnSummaryEvent>(), isEmpty);
      });
    },
  );
}
