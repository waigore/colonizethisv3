import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

void main() {
  test(
    'gp3 invadable at turn 20 seed 42',
    () {
      CtLogger.level = Level.off;
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
      for (var t = 0; t < 20; t++) {
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
        game =
            (validateOrdersAndResolveTurnFromTrustedOrders(
                      game: fullAi.game,
                      topology: topo,
                      orders: merged,
                      tileMapByRegion: tileMap,
                      defaultAssignmentsByPlayerId: assignments,
                    )
                    as TurnResolutionComplete)
                .game;
      }
      final view = buildPlayerView(game, topo, 'gp3');
      final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
      final owners = getProvinceOwnerMap(game);
      final minorInvadable = snap.conquest.invadableProvinceIdsSorted
          .where((pid) => game.minorNations.any((m) => m.id == owners[pid]))
          .toList();
      expect(
        minorInvadable.length,
        greaterThan(0),
        reason: 'gp3 should have minor targets',
      );
    },
    skip:
        'Refs #2509: seed-42 turn-20 gp3 invadable minors not stable after '
        'sole-GP peace merge; covered by colonial_pressure unit tests',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
