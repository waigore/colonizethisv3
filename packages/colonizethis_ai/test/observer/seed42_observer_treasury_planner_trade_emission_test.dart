import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'seed42_observer_treasury_planner_trade_emission_support.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  suppressLogsForTests();

  group(
    'seed 42 turn 1 TreasuryPlanner trade-order emission (Refs #2994 F9)',
    () {
      test('generateOrdersForGameFullAI emits TradeOrders for at least one Great '
          'Power and every emitted order satisfies the F1–F5 invariants', () {
        final init = runInitGame(
          config: GameSetupConfig(seed: 42),
          options: const InitGameOptions(
            cellSize: 24,
            renderPng: false,
            skipFillLakes: false,
          ),
        );
        final game = init.game.copyWith(
          aiControlByGpId: {for (final p in init.game.players) p.id: true},
        );
        final topology = init.combinedTopology;
        final tileMapByRegion = init.tileMapByRegion;

        final result = generateOrdersForGameFullAI(
          game,
          topology,
          tileMapByRegion: tileMapByRegion,
        );

        final rows = buildSeed42TreasuryTradeEmissionTrace(
          game: game,
          result: result,
          topology: topology,
        );
        final traceTable = rows.map((r) => r.formatRow()).join('\n');
        final reason =
            'seed-42 turn-1 per-GP trade-emission trace:\n'
            '$traceTable';

        // AC F9.1: at least one Great Power emits at least one TradeOrder.
        final aggregatedCount = result.orders.tradeOrdersByPlayerId.values
            .fold<int>(0, (sum, list) => sum + list.length);
        expect(
          aggregatedCount,
          greaterThan(0),
          reason:
              'Refs #2994 F9 AC-1: generateOrdersForGameFullAI must surface '
              'at least one trade order across all AI Great Powers on the '
              'seed-42 turn-1 starting state. $reason',
        );

        // AC F9.2: every emitted TradeOrder satisfies the F1–F5 invariants.
        for (final gpId in kSeed42TreasuryTradeEmissionGreatPowerIds) {
          final orders =
              result.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
          for (var i = 0; i < orders.length; i++) {
            final order = orders[i];
            expect(
              order.quantity,
              greaterThan(0),
              reason:
                  'Refs #2994 F9 AC-2 (quantity > 0): $gpId trade order #$i '
                  'has non-positive quantity ${order.quantity}. $reason',
            );
            expect(
              kSeed42TreasuryTradeEmissionAllowedPriorities.contains(order.priority),
              isTrue,
              reason:
                  'Refs #2994 F9 AC-2 (priority tier): $gpId trade order #$i '
                  'has priority ${order.priority} outside the planner-allowed '
                  'set $kSeed42TreasuryTradeEmissionAllowedPriorities. $reason',
            );
            expect(
              richesCommodityIds.contains(order.commodityId),
              isFalse,
              reason:
                  'Refs #2994 F9 AC-2 (riches exclusion): $gpId trade order '
                  '#$i targets riches commodity ${order.commodityId}, but the '
                  'TreasuryPlanner skips ids in richesCommodityIds. $reason',
            );
            expect(
              order.type == TradeOrderType.bid ||
                  order.type == TradeOrderType.offer,
              isTrue,
              reason:
                  'Refs #2994 F9 AC-2 (type domain): $gpId trade order #$i '
                  'has type ${order.type} outside '
                  '{TradeOrderType.bid, TradeOrderType.offer}. $reason',
            );
          }
        }
      }, timeout: const Timeout(Duration(minutes: 5)));

      test(
        'generateOrdersForGameFullAI is deterministic on seed-42 turn 1: two '
        'runs produce identical tradeOrdersByPlayerId',
        () {
          final init = runInitGame(
            config: GameSetupConfig(seed: 42),
            options: const InitGameOptions(
              cellSize: 24,
              renderPng: false,
              skipFillLakes: false,
            ),
          );
          final game = init.game.copyWith(
            aiControlByGpId: {for (final p in init.game.players) p.id: true},
          );
          final topology = init.combinedTopology;
          final tileMapByRegion = init.tileMapByRegion;

          final r1 = generateOrdersForGameFullAI(
            game,
            topology,
            tileMapByRegion: tileMapByRegion,
          );
          final r2 = generateOrdersForGameFullAI(
            game,
            topology,
            tileMapByRegion: tileMapByRegion,
          );

          // Compare per-player to surface which GP diverged on failure.
          final allGpIds = <String>{
            ...r1.orders.tradeOrdersByPlayerId.keys,
            ...r2.orders.tradeOrdersByPlayerId.keys,
          };
          for (final gpId in allGpIds) {
            final a =
                r1.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
            final b =
                r2.orders.tradeOrdersByPlayerId[gpId] ?? const <TradeOrder>[];
            expect(
              a,
              b,
              reason:
                  'Refs #2994 F9 AC-3 (determinism): seed-42 turn-1 trade '
                  'orders for $gpId differ between two consecutive '
                  'generateOrdersForGameFullAI invocations. '
                  'run1=$a run2=$b',
            );
          }
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );
    },
  );
}
