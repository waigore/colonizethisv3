// Seed-42 turn-1 TreasuryPlanner + market resolution wall-clock budget pin
// (Refs #2994 F10). SPEC/ai/treasury-planner.md
// § "Seed-42 trade-enabled wall-clock budget (Refs #2994 F10)".
//
// F1–F8 ship the per-planner TreasuryPlanner behaviour; F9 pins
// `generateOrdersForGameFullAI` turn-1 trade-order emission on a real
// seed-42 starting state. F10 closes the timing gap: the production
// Full AI + trusted-resolve pipeline (including the World Market
// phase) must clear `kTurnProcessingWallClockBudgetMs` (15 000 ms)
// on seed-42 turn 1, AND the timed envelope must actually exercise
// the trade-orders code path (`tradeOrdersByPlayerId` non-empty).
//
// A silently disabled TreasuryPlanner integration or a runaway
// market-resolution regression would otherwise pass either the
// `defaultConfig` budget pin
// (`full_ai_first_turn_wall_clock_budget_test.dart`, Refs #2507) or
// the seed-42 turn-1 emission pin
// (`seed42_observer_treasury_planner_trade_emission_test.dart`, F9)
// in isolation. F10 keeps both signals tied to one assertion so a
// regression on either surface fails this test rather than slipping
// past CI on a partial signal.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  suppressLogsForTests();

  group('seed 42 turn 1 trade-enabled wall-clock budget (Refs #2994 F10)', () {
    test(
      'generateOrdersForGameFullAI emits TradeOrders and the AI + resolve '
      'span clears kTurnProcessingWallClockBudgetMs',
      () {
        final init = runInitGame(
          config: GameSetupConfig(seed: 42),
          options: const InitGameOptions(
            cellSize: 24,
            renderPng: false,
            skipFillLakes: false,
          ),
        );
        final topology = init.combinedTopology;
        final tileMapByRegion = init.tileMapByRegion;
        final game = init.game.copyWith(
          aiControlByGpId: {for (final p in init.game.players) p.id: true},
        );

        final total = Stopwatch()..start();
        final fullAiSw = Stopwatch()..start();
        final fullAi = generateOrdersForGameFullAI(
          game,
          topology,
          tileMapByRegion: tileMapByRegion,
        );
        fullAiSw.stop();

        final mergedOrders = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final defaultAssignmentsByPlayerId =
            fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );

        final resolveSw = Stopwatch()..start();
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topology,
          orders: mergedOrders,
          tileMapByRegion: tileMapByRegion,
          defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
        );
        resolveSw.stop();
        total.stop();

        requireTurnResolutionComplete(result);

        final tradeOrderCount = fullAi.orders.tradeOrdersByPlayerId.values
            .fold<int>(0, (sum, list) => sum + list.length);
        final fullAiMs = fullAiSw.elapsedMilliseconds;
        final resolveMs = resolveSw.elapsedMilliseconds;
        final totalMs = total.elapsedMilliseconds;

        final reason =
            'total_ms=$totalMs full_ai_ms=$fullAiMs resolve_ms=$resolveMs '
            'trade_orders=$tradeOrderCount '
            'budget_ms=$kTurnProcessingWallClockBudgetMs';

        // AC F10.1: the timed envelope must exercise the trade-orders
        // code path — a silently disabled TreasuryPlanner integration
        // would otherwise let a slow path pass this budget on a
        // partial signal.
        expect(
          tradeOrderCount,
          greaterThan(0),
          reason:
              'Refs #2994 F10 AC-1: seed-42 turn-1 generateOrdersForGameFullAI '
              'must surface at least one trade order across all AI Great '
              'Powers so the timed envelope actually covers the World Market '
              'code path. $reason',
        );

        // AC F10.2: combined AI + resolve span clears the 15 s budget.
        expect(
          totalMs,
          lessThanOrEqualTo(kTurnProcessingWallClockBudgetMs),
          reason:
              'Refs #2994 F10 AC-2: seed-42 turn-1 trade-enabled processing '
              'exceeded budget. $reason',
        );
      },
      timeout: Timeout.none,
    );
  });
}
