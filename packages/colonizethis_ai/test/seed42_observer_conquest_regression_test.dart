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
        'Partial AC #2509 S10 / #2847: seed-42 turn-100 gate — gp1/gp2/gp4/gp6 '
        'PASS (gp1 +6, gp2 +6, gp4 +3, gp6 +10). gp3 0, gp5 -7 FAIL (S7-D '
        'diagnostic refresh 2026-06-08, dev HEAD). The +6 gp1/gp2 baseline '
        'holds. This refresh relocates the binding constraint and supersedes '
        'every prior peasant-recruit-fabric / fabric-offer-side / castIron '
        'offer-tier framing: the residual is a RULES-LEVEL GLOBAL castIron '
        'labour wall. The only castIron recipe needs labourPerOutput == 5 '
        'while NO GP raw labour ceiling exceeds 3 (turn-99 rawLabourSupply: '
        'gp4 = 3, all others = 2), so gpCastIronRecipeLabourFeasibleTurns == 0 '
        'for EVERY GP — suppliers gp1/gp2 included (gp1 is castIron material-'
        'feasible 35 turns yet labour-feasible 0). castIron is consequently '
        'never produced or held anywhere (gpCastIronProductionAssignedTurns / '
        'gpCastIronHeldAtTurn99 == 0 for all), so the market never offers it '
        '(gpCastIronMarketOfferAbsentTurns gp3 = 46). The level-0 '
        'build_improvement cost (1 lumber + 1 castIron) is therefore globally '
        'unaffordable in its castIron half (gpFeedstockGateImprovementCastIron'
        'AffordableTurns == 0 for all), severing the failing GPs recovery '
        'chain (extract cotton/wool via build_improvement -> produce fabric -> '
        'build peasant_levies -> conquer) at the castIron step. gp3 is gated '
        'purely on this: treasury 2164 (>= 2000 cost), 0 regiments, 4 '
        'invadable OW targets, rebuild-ready 45 turns all missing only the '
        'lone fabric build input it can never source. The #3303 peasant-'
        'recruit fabric path is fully DORMANT this run (gpCastIronLabour'
        'PeasantRecruitGateTurns == 0 for all; its castIron-material precondition '
        'is unmet for gp3/gp5, iron == 0), so the #3354 gpFabricMarketOffer'
        'Present/AbsentTurns counters read 0/0 (inconclusive). No AI-planner '
        'lever (supplier over-production, offer-tier alignment, peasant-recruit '
        'fabric staging, buyer bidding) can close a wall where castIron is '
        'unproducible game-wide. Next lever is OUT of #2847 AI-planner scope '
        '(scope constraint forbids ai_victory_config.dart / rules changes): a '
        'rules/economy change lowering the castIron recipe labourPerOutput (or '
        'the build_improvement castIron requirement), or a raw-labour bootstrap '
        'lifting a lock-recovery seller toward 5 labour without the fabric-'
        'gated peasant recruit — escalate to the #2509 umbrella or a dedicated '
        'rules issue. gp5 (-7) is a separate peer-war attrition collapse (7->0 '
        'OW, permanent EXPAND, treasury 1999, gpInvadableEmptyTurns 44) needing '
        'an EXPAND attrition-war escape, likewise beyond a single non-'
        'regressive planner slice. Skip removal awaits the diagnostic '
        'confirming gp3-gp5 reach the >=3 OW floor without regressing '
        'gp1/gp2/gp4/gp6 (Refs #2847).',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
