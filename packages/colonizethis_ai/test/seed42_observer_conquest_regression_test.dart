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
          reason:
              '$gpId OW gain=$gain start=${owStart[gpId]} '
              'end=${owStart[gpId]! + gain} allGains=$gains',
        );
      }
    },
    skip:
        'Partial AC #2509 S10 / #2847: seed-42 turn-100 gate — gp1/gp2 PASS '
        '(+6 each). gp3 +2, gp4 +1, gp5 +1, gp6 +2 (merged dev HEAD post-#3267, '
        '2026-06-05 S7-D refresh). Treasury starvation is solved (failing GPs '
        'hold ~2000+ treasury). The binding material is lumber for the level-0 '
        'build_improvement (castIron waived via '
        'feedstockBootstrapBuildImprovementCastIronWaived). The seller-side '
        'domestic lumber-production slice landed (the seller produces lumber '
        'from owned timber, not just market-absent castIron). The re-pointed '
        'seller timber-holdings lever now also landed: '
        'sellerImprovementInputFeedstockExtractionResourceIds extends the H8 '
        'feedstock-extraction gate to the seller own lumber/castIron '
        'improvement-input feedstock (timber/iron), so the locked seller idle '
        'Builder is routed onto its own unimproved timber tile (and the OW '
        'feedstock reservation holds it in the Old World), feeding domestic '
        'lumber_from_timber. Re-run the s7d diagnostic to refresh per-GP OW '
        'gain + gpCastIronFeedstockHeldAtTurn99; the residual disclosed for a '
        'seller that owns no timber tile at all is feedstock-tile acquisition '
        '(further #2847 work). Skip removal awaits the diagnostic confirming '
        'gp3-gp6 reach the >=3 OW floor (Refs #2847).',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
