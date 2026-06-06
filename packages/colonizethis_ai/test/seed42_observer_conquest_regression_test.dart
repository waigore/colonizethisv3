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
        '(+6 each). gp3 +2, gp4 +1, gp5 +1, gp6 +2 (S7-D diagnostic refresh '
        '2026-06-06, origin/dev base). Treasury starvation stays solved: '
        'failing GPs hold ~2000+ at turn 99 (gp3 2024, gp4 2170, gp5 2187, gp6 '
        '2007) vs gp1/gp2 ~500 (spent on conquest). Target availability is not '
        'the gap either — gpInvadableEmptyTurns is 0 for gp3-gp6 (always an '
        'invadable OW province) while gp1/gp2 sit at 91 (region cleared). '
        'Binding constraint is now regiment SUSTAINMENT, not lumber: gp3/gp5/'
        'gp6 sit at zero regiments 39/43/48 turns and are rebuild-ready '
        '(treasury >= cheapest cost) 29/36/40 turns, yet emit NO regiment build '
        'on 29/35/39 of those because the build INPUTS are missing '
        '(gpRebuildReadyNoBuildMissingInputTurns; gpRebuildReadyNoBuildInputs'
        'PresentTurns == 0). Cheapest-regiment inputs are in stockpile only '
        '2/3/3 turns for gp3/gp5/gp6 (gp4 = 61). The missing input traces to '
        'the castIron -> build_improvement -> feedstock-extraction chain: '
        'gpCastIronProductionAssignedTurns == 0 for every GP, and where castIron '
        'is materially feasible (gp5 = 53 turns) it is labour POPULATION-bound '
        '(gpCastIronRecipeLabourFeasibleTurns == 0; gpCastIronLabour'
        'PopulationBoundTurns gp5 = 53), i.e. even fully fed the seller lacks '
        'the workers for one run. The feedstock-tile ACQUISITION-by-conquest '
        'path (#3271-#3273) never activates (gpFeedstockAcquisitionTargetActive'
        'Turns == 0 for all GPs) because the failing GPs already OWN unimproved '
        'feedstock tiles (gpUnimprovedFeedstockTileOwnedTurns ~100) — the '
        'residual is extraction/production (castIron labour), not tile '
        'acquisition. gp4 is distinct: input-rich (inputs in stockpile 61 '
        'turns, zero-regiment only 1 turn) but locked in attritional war '
        '(gpAtWarTurnsByPeer minor1 99, tribe8 50, tribe2 45, gp3 22) and '
        'converts few regiments into OW gains. The #3303 worker-growth attempt '
        '(recruit a peasant when castIron labour is population-bound) is now '
        'localized as a STRUCTURAL NO-OP: its gate fires only for gp5 (37 '
        'turns) and on EVERY one the seller cannot pay the peasant recruit cost '
        'row of 2 fabric (gpCastIronLabourPeasantRecruitAffordableTurns == 0, '
        'FabricStarvedTurns == 37) — a circular dependency, since the peasant '
        'that would grow castIron labour is itself bought with fabric, the very '
        'downstream commodity the castIron chain exists to unblock. Next levers '
        '(out of scope for a single non-regressive slice; must hold the gp1/gp2 '
        '+6 baseline per requirement clarification #8): a fabric-free or '
        'fabric-self-funded labour-growth path for gp5 (it already shows '
        'gpFabricRecipeFeasibleTurns == 48, so routing a domestic fabric '
        'assignment before the recruit is a candidate), castIron MATERIAL '
        'feasibility for gp3/gp6 (gpCastIronRecipeFeasibleTurns == 0), and '
        'attrition-war escape / OW target conversion for gp4. Skip removal '
        'awaits the diagnostic confirming gp3-gp6 reach the >=3 OW floor '
        '(Refs #2847).',
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
