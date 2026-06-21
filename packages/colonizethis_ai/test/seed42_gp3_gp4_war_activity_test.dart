import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

/// Seed-42 mutual-plateau frontier war activity (Refs #2509).
///
/// Originally pinned to the gp3/gp4 frontier pair. After the #3573 forest
/// terrain redistribution (R6: plains up, forest halved/split) the seed-42
/// world reshapes adjacency — gp3 and gp4 now each expand freely (no mutual
/// blocker) and the early frontier war shifts to the gp5/gp6 pair. The
/// regression intent (#2509: great powers open early mutual-plateau / frontier
/// wars on the default seed rather than coexisting peacefully) is preserved by
/// asserting that *some* great-power pair goes to war within the first 50 turns
/// instead of pinning a specific pair the redistribution no longer makes rivals.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('seed 42: at least one great-power pair opens a war within the first '
      '50 turns', () {
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
    final gpIds = game.players.map((p) => p.id).toSet();
    final warTurnsByPair = <String, int>{};
    var anyGpWarTurns = 0;
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
      var anyThisTurn = false;
      for (final r in game.diplomacyRelations) {
        if (r.state != RelationState.atWar) continue;
        if (!gpIds.contains(r.factionId1) || !gpIds.contains(r.factionId2)) {
          continue;
        }
        anyThisTurn = true;
        final pair = <String>[r.factionId1, r.factionId2]..sort();
        final key = pair.join('-');
        warTurnsByPair[key] = (warTurnsByPair[key] ?? 0) + 1;
      }
      if (anyThisTurn) {
        anyGpWarTurns++;
      }
    }
    expect(
      anyGpWarTurns,
      greaterThan(0),
      reason: 'at least one great-power pair should open a mutual-plateau / '
          'frontier war before turn 50 on seed 42 '
          '(anyGpWarTurns=$anyGpWarTurns warTurnsByPair=$warTurnsByPair)',
    );
  }, timeout: const Timeout(Duration(minutes: 8)));
}
