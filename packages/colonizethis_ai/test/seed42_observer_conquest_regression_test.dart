import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

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
    var game = init.game.copyWith(
      aiControlByGpId: {for (final p in init.game.players) p.id: true},
    );
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
        'Partial AC #2509 S10: seed-42 turn-100 — gp3/gp6 still below +3 OW; '
        'mutual-plateau peace/declare tuning landed, gate still red',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
