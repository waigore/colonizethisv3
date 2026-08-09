// Late-turn Full AI wall-clock budget with connectivity-aware civilian work
// (Refs #4176 AC-F5).
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import '../support/seed42_observer_campaign.dart';

const int kConnectivityDevBudgetProbeTurn = 60;

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  suppressLogsForTests();

  group('connectivity dev late-turn wall-clock budget (Refs #4176 AC-F5)', () {
    test(
      'seed 42 turn $kConnectivityDevBudgetProbeTurn Full AI + resolve stays '
      'within kTurnProcessingWallClockBudgetMs',
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
        final campaign = runSeed42ObserverCampaign(
          turns: kConnectivityDevBudgetProbeTurn - 1,
        );
        final game = campaign.finalGame;

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
              'turn $kConnectivityDevBudgetProbeTurn processing exceeded budget: '
              'total_ms=$totalMs full_ai_ms=$fullAiMs resolve_ms=$resolveMs '
              'budget_ms=$kTurnProcessingWallClockBudgetMs',
        );
      },
      timeout: Timeout.none,
    );
  });
}
