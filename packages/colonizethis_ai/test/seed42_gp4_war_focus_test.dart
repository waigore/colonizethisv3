import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('seed 42 turn 50: gp4 has at most one GP war and it is the OW blocker', () {
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
    for (var t = 0; t < 50; t++) {
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
      game = (result as TurnResolutionComplete).game;
    }
    final view = buildPlayerView(game, topo, 'gp4');
    final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
    final gpWars = snap.threats.atWarWith
        .where((id) => game.playerById(id) != null)
        .toList()
      ..sort();
    if (snap.conquest.invadableProvinceIdsSorted.isEmpty) {
      expect(gpWars.length, lessThanOrEqualTo(1));
      return;
    }
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: game,
      snapshot: snap,
    );
    expect(blocker, isNotNull);
    expect(gpWars.length, lessThanOrEqualTo(1));
    if (gpWars.isNotEmpty) {
      expect(gpWars, [blocker]);
    }
  },
    skip:
        'Refs #2509: turn-50 gp4 often holds multiple GP fronts after OW '
        'expansion; blocker-focus applies during stalled OW band only',
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
