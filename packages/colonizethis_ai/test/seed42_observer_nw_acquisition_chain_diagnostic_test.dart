import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/faithful_full_ai_test_handoff.dart';

/// Seed-42 Path E NW-acquisition **chain** diagnostic (Refs #2924).
///
/// The #2924 primary Path F (World Market) AC now closes on seed 42:
/// gp3–gp6 each cross `cheapestRegimentBuildTreasuryCost()` from
/// legitimate world-market seller credits (pinned by
/// `seed42_observer_world_market_lock_recovery_regression_test.dart`).
/// The issue's **secondary** Path E work — the owner-directed
/// "conquer/purchase NW provinces with riches first" steady-income
/// chain — remains open: gp3–gp6 gain **zero** NW provinces across the
/// 100-turn campaign despite the `newWorldAcquisition == 0.60`
/// resource-need override floor.
///
/// `seed42_observer_nw_lock_recovery_declare_war_regression_test.dart`
/// already pins the **upstream** link (each failing GP emits at least
/// one tribal `declareWar`). What is *not* captured anywhere is **where
/// the chain breaks downstream of the declare-war**: do the failing GPs
/// actually emit the prerequisite work that turns the 0.60 floor into
/// NW province gains — naval/transport/Merchant builds, NW-bound army
/// moves, beachhead naval missions, or `purchase_land` work orders?
///
/// This diagnostic runs the faithful Full-AI seed-42 100-turn campaign
/// and records, per failing GP (gp3–gp6), the per-turn counts of every
/// NW-acquisition-supporting order family the secondary AC enumerates,
/// plus the terminal NW ownership / treasury / regiment snapshot, so the
/// next Path E tuning slice can see the exact failing link (and confirm
/// whether the residual block is the companion home-army-mobility issue
/// #2925 rather than missing AI emission). It mirrors the established
/// `ISSUE2924_STEP0_JSON` / `C0_DIAGNOSTIC_JSON` instrumentation
/// precedent and changes **no** production code or SPEC.
///
/// The test asserts only (a) the 100-turn run completes each turn and
/// (b) the already-true upstream anchor (each failing GP emits ≥1 tribal
/// `declareWar`). It deliberately does **not** pin any downstream
/// build / move / NW-gain count, so the planner can be tuned freely in a
/// follow-up slice without churn here.
///
/// ## How to refresh
///
/// Skipped by default (long-running, ~3 minutes on the project reference
/// host). Run manually with:
///
/// ```
/// (cd packages/colonizethis_ai && dart test \
///     test/seed42_observer_nw_acquisition_chain_diagnostic_test.dart \
///     --run-skipped)
/// ```
///
/// and copy the `ISSUE2924_PATHE_JSON_BEGIN` / `ISSUE2924_PATHE_JSON_END`
/// delimited block into a fresh comment on issue #2924 when the Path E
/// chain surface shifts after a tuning slice lands.
void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  const failingGpIds = ['gp3', 'gp4', 'gp5', 'gp6'];
  const turns = 100;

  test(
    'seed 42: Path E NW-acquisition chain per-GP order-family trace '
    '(Refs #2924)',
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

      final allGpIds = [for (var i = 1; i <= 6; i++) 'gp$i'];

      int nwCountOwnedBy(Game g, String gpId) => g
          .worldState
          .newWorld
          .provinces
          .where((p) => p.ownerId == gpId)
          .length;

      final nwStart = <String, int>{
        for (final gpId in allGpIds) gpId: nwCountOwnedBy(game, gpId),
      };

      // Per-failing-GP rollups across the campaign (counted from the
      // merged orders the AI actively emits each turn).
      final tribalDeclareWars = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final buildsTotal = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final buildsMilitary = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final buildsNwSpawn = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final buildsByType = <String, Map<String, int>>{
        for (final gpId in failingGpIds) gpId: <String, int>{},
      };
      final armyMovesTotal = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final armyMovesToNw = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final navalMovesTotal = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final navalMissionsTotal = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final navalBeachheadMissions = <String, int>{
        for (final gpId in failingGpIds) gpId: 0,
      };
      final workOrdersByTarget = <String, Map<String, int>>{
        for (final gpId in failingGpIds) gpId: <String, int>{},
      };

      for (var t = 0; t < turns; t++) {
        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );
        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );

        for (final gpId in failingGpIds) {
          for (final order
              in merged.diplomaticOrdersByPlayerId[gpId] ?? const []) {
            if (order.type == DiplomaticOrderType.declareWar &&
                !order.targetFactionId.startsWith('gp')) {
              tribalDeclareWars[gpId] = tribalDeclareWars[gpId]! + 1;
            }
          }
          for (final order
              in merged.buildUnitOrdersByPlayerId[gpId] ?? const []) {
            buildsTotal[gpId] = buildsTotal[gpId]! + 1;
            if (order.isMilitary) {
              buildsMilitary[gpId] = buildsMilitary[gpId]! + 1;
            }
            if (order.spawnProvinceId.startsWith('newWorld')) {
              buildsNwSpawn[gpId] = buildsNwSpawn[gpId]! + 1;
            }
            final byType = buildsByType[gpId]!;
            byType[order.unitType] = (byType[order.unitType] ?? 0) + 1;
          }
          for (final order
              in merged.armyMoveOrdersByPlayerId[gpId] ?? const []) {
            armyMovesTotal[gpId] = armyMovesTotal[gpId]! + 1;
            if (order.destinationProvinceId.startsWith('newWorld')) {
              armyMovesToNw[gpId] = armyMovesToNw[gpId]! + 1;
            }
          }
          navalMovesTotal[gpId] = navalMovesTotal[gpId]! +
              (merged.navalMoveOrdersByPlayerId[gpId]?.length ?? 0);
          for (final order
              in merged.navalMissionOrdersByPlayerId[gpId] ?? const []) {
            navalMissionsTotal[gpId] = navalMissionsTotal[gpId]! + 1;
            if (order.mission.toLowerCase().contains('beachhead')) {
              navalBeachheadMissions[gpId] =
                  navalBeachheadMissions[gpId]! + 1;
            }
          }
          for (final order
              in merged.workOrdersByPlayerId[gpId] ?? const []) {
            final byTarget = workOrdersByTarget[gpId]!;
            byTarget[order.target] = (byTarget[order.target] ?? 0) + 1;
          }
        }

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

      final cheapestRegimentCost = cheapestRegimentBuildTreasuryCost();
      final nwEnd = <String, int>{
        for (final gpId in allGpIds) gpId: nwCountOwnedBy(game, gpId),
      };
      final nwGain = <String, int>{
        for (final gpId in allGpIds) gpId: nwEnd[gpId]! - nwStart[gpId]!,
      };
      final terminalSnapshot = <String, Map<String, Object?>>{
        for (final gpId in failingGpIds)
          gpId: <String, Object?>{
            'treasury': game.playerById(gpId)?.treasury,
            'regimentCount': regimentCountForPlayer(game, gpId),
            'nwProvincesOwned': nwEnd[gpId],
          },
      };

      final diagnostic = <String, Object?>{
        'issue': 2924,
        'subtask': 'Path E NW-acquisition chain',
        'seed': 42,
        'turns': turns,
        'cheapestRegimentBuildTreasuryCost': cheapestRegimentCost,
        'gpNwOwnedStart': nwStart,
        'gpNwOwnedEnd': nwEnd,
        'gpNwGain': nwGain,
        'failingGpChain': {
          for (final gpId in failingGpIds)
            gpId: <String, Object?>{
              'tribalDeclareWars': tribalDeclareWars[gpId],
              'buildsTotal': buildsTotal[gpId],
              'buildsMilitary': buildsMilitary[gpId],
              'buildsNwSpawn': buildsNwSpawn[gpId],
              'buildsByType': buildsByType[gpId],
              'armyMovesTotal': armyMovesTotal[gpId],
              'armyMovesToNw': armyMovesToNw[gpId],
              'navalMovesTotal': navalMovesTotal[gpId],
              'navalMissionsTotal': navalMissionsTotal[gpId],
              'navalBeachheadMissions': navalBeachheadMissions[gpId],
              'workOrdersByTarget': workOrdersByTarget[gpId],
            },
        },
        'gpTerminalSnapshot': terminalSnapshot,
      };

      // Re-enable info-level logging so the structured diagnostic JSON
      // surfaces in stdout via the package logger (the simulation above
      // intentionally ran with logging off to suppress planner noise).
      // Routing through `aiLogger` keeps this test compliant with the
      // disallowed-AST `avoid_print_suppression` rule while preserving
      // greppable BEGIN/END markers for issue-comment transcription.
      CtLogger.level = Level.info;
      final log = aiLogger('path-e-nw-chain-diagnostic');
      log.i('ISSUE2924_PATHE_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('ISSUE2924_PATHE_JSON_END');

      // Upstream anchor: the declare-war link is known to fire (pinned by
      // the dedicated declare-war regression). Re-asserting it here keeps
      // this diagnostic a meaningful regression for the entry of the chain
      // while leaving every downstream count unpinned for free tuning.
      for (final gpId in failingGpIds) {
        expect(
          tribalDeclareWars[gpId]!,
          greaterThan(0),
          reason:
              'Refs #2924 Path E: $gpId must emit at least one tribal '
              'declareWar under the lock-recovery override '
              '(count=${tribalDeclareWars[gpId]}).',
        );
      }
    },
    skip:
        'Refs #2924: long-running seed-42 Path E NW-acquisition chain '
        'diagnostic (~3 min). Captured findings live in the Path E '
        'diagnostic note on issue #2924 / the implementing PR. Re-run '
        'with `dart test --run-skipped` when the chain surface shifts '
        'after a tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
