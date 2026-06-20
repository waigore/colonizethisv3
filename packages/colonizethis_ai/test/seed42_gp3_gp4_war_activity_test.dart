import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

/// Seed-42 gp3/gp4 mutual-plateau frontier activity (Refs #2509).
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test('seed 42: gp3 and gp4 are at war for part of the first 50 turns', () {
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
    var warTurns = 0;
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
      final atWar = game.diplomacyRelations.any(
        (r) =>
            r.state == RelationState.atWar &&
            ((r.factionId1 == 'gp3' && r.factionId2 == 'gp4') ||
                (r.factionId1 == 'gp4' && r.factionId2 == 'gp3')),
      );
      if (atWar) {
        warTurns++;
      }
    }
    final gp3Ow = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == 'gp3')
        .length;
    final gp4Ow = game.worldState.oldWorld.provinces
        .where((p) => p.ownerId == 'gp4')
        .length;
    expect(
      warTurns,
      greaterThan(0),
      reason: 'gp3/gp4 should open a mutual-plateau blocker war before turn 50 '
          '(warTurns=$warTurns gp3Ow=$gp3Ow gp4Ow=$gp4Ow)',
    );
  }, timeout: const Timeout(Duration(minutes: 8)));
}
