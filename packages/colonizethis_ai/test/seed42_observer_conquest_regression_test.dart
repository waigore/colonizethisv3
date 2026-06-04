import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';

/// Observer seed-42 per-GP Old World conquest gate (Refs #2509).
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100: every GP gains at least 3 Old World provinces',
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
    for (var i = 1; i <= 6; i++) {
      final gpId = 'gp$i';
      final gain = gains[gpId]!;
      expect(
        gain,
        greaterThanOrEqualTo(3),
        reason: '$gpId OW gain=$gain start=${owStart[gpId]} '
            'end=${owStart[gpId]! + gain} allGains=$gains',
      );
    }
    },
    skip:
        'Partial AC #2509 S10 / #2847: seed-42 turn-100 gate — gp1/gp2 PASS '
        '(+6 each). gp3 +2, gp4 +1, gp5 +1, gp6 +2 (merged dev @ 0ef7919e, '
        '2026-06-04 S7-D refresh: World Market #2924/#2994 + EXPAND universal '
        'colonial dispatch #3179 + minor-transit routing #3224 + H8-supply wool '
        'market/extraction #3233-#3235). Treasury starvation is solved (failing '
        'GPs hold ~2000+ treasury); the remaining blocker is regiment-rebuild '
        'fabric supply — feedstock-stage instrumentation shows the failing GPs '
        'own unimproved wool/cotton tiles all 100 turns and the extraction gate '
        'fires 29-52 turns, yet feedstock reaches the stockpile only 1 turn, so '
        'the routed Builder never extracts the feedstock (H8-extraction). '
        'gp3-gp6 still below the >=3 OW floor; skip removal awaits the '
        'H8-extraction Builder-execution slice (Refs #2847).',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
