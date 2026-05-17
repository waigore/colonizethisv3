import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// First turn of default-config Full AI + trusted resolve (Refs #2507).
void main() {
  suppressLogsForTests();

  group('full AI first turn wall-clock budget (Refs #2507)', () {
    test(
      'turn 1 AI + resolution stays within kTurnProcessingWallClockBudgetMs',
      () {
        final init = runInitGame(
          config: GameSetupConfig.defaultConfig,
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

        final fullAiMs = fullAiSw.elapsedMilliseconds;
        final resolveMs = resolveSw.elapsedMilliseconds;
        final totalMs = total.elapsedMilliseconds;

        expect(
          totalMs,
          lessThanOrEqualTo(kTurnProcessingWallClockBudgetMs),
          reason:
              'turn 1 processing exceeded budget: total_ms=$totalMs '
              'full_ai_ms=$fullAiMs resolve_ms=$resolveMs '
              'budget_ms=$kTurnProcessingWallClockBudgetMs',
        );
      },
      timeout: Timeout.none,
    );
  });
}
