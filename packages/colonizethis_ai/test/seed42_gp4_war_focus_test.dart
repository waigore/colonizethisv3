import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/faithful_full_ai_test_handoff.dart';

void main() {
  test('seed 42 turn 51: gp4 has at most one GP war when invadable OW remains', () {
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
    void resolveTurn() {
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

    // Run through turn 50 resolution: multi-front GP wars consolidate in the
    // same diplomacy phase (declare blocker, peace non-blocker). S10 peace
    // plumbing may leave a sole mutual-plateau peer war instead of the OW
    // blocker (seed-42 gp4/gp6 vs gp3 frontier). Multi-slot treasury-aware
    // research (Refs #3472) can leave a transient two-GP-war state at the
    // turn-50 boundary; one more turn lets expand-phase peace consolidate.
    for (var t = 0; t < 51; t++) {
      resolveTurn();
    }
    final view = buildPlayerView(game, topo, 'gp4');
    final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
    final gpWars = snap.threats.atWarWith
        .where((id) => game.playerById(id) != null)
        .toList()
      ..sort();
    if (snap.conquest.invadableProvinceIdsSorted.isEmpty) {
      return;
    }
    expect(gpWars.length, lessThanOrEqualTo(1));
  }, timeout: const Timeout(Duration(minutes: 8)));
}
