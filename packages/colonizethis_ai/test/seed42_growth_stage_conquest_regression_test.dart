import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';

/// Growth-stage planner seed-42 conquest gate (Refs #3371 AC7).
///
/// Runs with `growthStagePlannerEnabled: true` (H8 reactive boosts off).
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 with growth-stage planner: per-GP OW conquest baselines',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = applyFaithfulFullAiTestHandoff(init.game);
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;
      final owStart = <String, int>{};
      for (var i = 1; i <= 6; i++) {
        final gpId = 'gp$i';
        owStart[gpId] = game.worldState.oldWorld.provinces
            .where((p) => p.ownerId == gpId)
            .length;
      }
      for (var t = 0; t < 100; t++) {
        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
          growthStagePlannerEnabled: true,
        );
        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        game = (result as TurnResolutionComplete).game;
      }
      final gains = <String, int>{};
      for (var i = 1; i <= 6; i++) {
        final gpId = 'gp$i';
        final end = game.worldState.oldWorld.provinces
            .where((p) => p.ownerId == gpId)
            .length;
        gains[gpId] = end - owStart[gpId]!;
      }

      const baselines = <String, int>{
        'gp1': 6,
        'gp2': 6,
        'gp4': 3,
        'gp6': 10,
        'gp3': 3,
        'gp5': 3,
      };
      for (final entry in baselines.entries) {
        expect(
          gains[entry.key],
          greaterThanOrEqualTo(entry.value),
          reason:
              '${entry.key} OW gain=${gains[entry.key]} '
              'required>=${entry.value} allGains=$gains',
        );
      }
    },
    skip:
        'Refs #3371 AC7: growth-stage calibration pending — run with '
        'growthStagePlannerEnabled=true after constant tuning. H8 boosts are '
        'disabled in this path; baseline parity vs legacy seed-42 is not yet '
        'verified on dev HEAD.',
  );
}
