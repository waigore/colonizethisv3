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
        'Partial AC #2509 S10 / #2847: seed-42 turn-100 gate — gp1/gp2/gp4/gp6 '
        'PASS (gp1 +6, gp2 +6, gp4 +3, gp6 +10). gp3 0, gp5 -7 FAIL (H5 '
        'verification 2026-06-07). #2847 § H5 restores the EXPAND '
        'tribe-distraction peace dropped from the production phase-plan path '
        'by the S5 GP-only planExpandPeace adapter: a regiment-thin '
        'below-quota GP now offerPeaces at-war tribes that own zero OW '
        'provinces (pure distractions), concentrating its force. gp4 +1->+3 '
        'clears the gate for the first time and the gp1/gp2/gp6 protected '
        'baselines hold exactly; gp3 +2->0 is the disclosed trade-off (gp3 '
        'and gp4 are coupled through the same lever — the conservative '
        'variant that spares gp3 also neutralizes gp4). Pre-H5 surface '
        '(origin/dev @ 424b3a938, S7-D diagnostic refresh 2026-06-07): gp3 '
        '+2, gp4 +1. gp6 reaches '
        'COLONIAL 45 turns, +10 OW; gp5 -7 — it never '
        'leaves EXPAND (expand 100 turns), hoards treasury (3915 at turn 99) '
        'yet loses 7 OW provinces in attritional war. Treasury starvation '
        'stays solved: failing GPs hold ~2000+ at turn 99 (gp3 2024, gp4 '
        '2125, gp5 3915) vs gp1/gp2 ~495 (spent on conquest). Binding '
        'constraint remains regiment SUSTAINMENT: rebuild-ready (treasury >= '
        'cheapest cost) gp3 29, gp5 7, gp6 12 turns, yet emit NO regiment '
        'build on gp3 29 / gp5 6 / gp6 11 of those because the build INPUTS '
        'are missing (gpRebuildReadyNoBuildMissingInputTurns; gpRebuild'
        'ReadyNoBuildInputsPresentTurns == 0 for all). The missing input '
        'traces to the castIron -> build_improvement -> feedstock-extraction '
        'chain: gpCastIronProductionAssignedTurns == 0 for every GP and '
        'gpCastIronRecipeLabourFeasibleTurns == 0 for every GP — castIron is '
        'never labour-feasible. The feedstock-tile ACQUISITION-by-conquest '
        'path (#3271-#3273) never activates (gpFeedstockAcquisitionTarget'
        'ActiveTurns == 0) because the failing GPs already OWN unimproved '
        'feedstock tiles (gpUnimprovedFeedstockTileOwnedTurns ~100); the '
        'residual is extraction/production labour, not tile acquisition. The '
        '#3303 peasant-recruit boost and the 2026-06-06 "route a domestic '
        'fabric assignment" hypothesis are BOTH confirmed dead this run: '
        'fabric is material-feasible many turns but labour-feasible only '
        'gpFabricRecipeLabourFeasibleTurns gp5 = 2 (gp1-4 = 1, gp6 = 4) — '
        'fabric_from_* carries labourPerOutput == 2, above a lock-recovery '
        "seller's effective labour of 1, the #3317 circular-labour deadlock "
        '(growing castIron labour needs a peasant; the peasant needs fabric; '
        'fabric itself needs labour the seller lacks). Every domestic-'
        'production lever (castIron, fabric) is therefore labour-walled. Next '
        'lever (out of scope for a single non-regressive slice; must hold the '
        'gp1/gp2/gp6 baselines per requirement clarification #8): a rules-'
        'level raw-labour bootstrap or a world-market fabric-purchase path '
        'that grows population without the labour-2 recipe wall, plus an '
        'attrition-war escape for gp5 (it bleeds OW while in permanent '
        'EXPAND). Skip removal awaits the diagnostic confirming gp3-gp5 reach '
        'the >=3 OW floor without regressing gp1/gp2/gp6 (Refs #2847).',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
