/// Treasury debits the AI (and any caller) can expect a player to pay
/// **before** phase 13 (World Market) on the current turn.
///
/// Sums the per-order treasury costs of the three order types that
/// resolve before the world-market phase and reduce `player.treasury`:
///
/// * `ResearchOrder`        — phase 7, `treasuryCostForFunding(level)`.
/// * `RecruitWorkerOrder`   — phase 12 worker-pool sub-phase,
///   `WorkerActionEconomyCatalog.forTier(...).treasuryCost`.
/// * `BuildUnitOrder`       — phase 12 unit-build sub-phase,
///   `RegimentEconomyCatalog`/`ShipEconomyCatalog` `buildTreasuryCost`.
///
/// Pending `WorkOrder` material costs do **not** debit treasury today
/// (stockpile only) and are excluded. Any future phase-pre-13 treasury
/// sink must be added here in the same change that introduces it.
///
/// The helper is **pure** and deterministic for fixed inputs, allocates
/// at most `O(orders for one player)` work, and never logs on the hot
/// path. It is safe to call from AI planning (`runTreasuryPlanner`),
/// validator / UI surfaces that need a treasury-budget projection, and
/// the resolver-prep path under the 15-second turn-resolution budget
/// (`.cursor/rules/colonizethis-turn-resolution-budget.mdc`).
///
/// SPEC source of truth: `SPEC/ai/treasury-planner.md` § Treasury-budget-aware
/// bid sizing (Refs #3122) and `SPEC/program/turn-resolution-phases.md`
/// § Phase sequence.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart' show GamePlayerLookup;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'research_rules.dart';

/// Total treasury debits expected for [playerId] on the current turn
/// from the pre-phase-13 order types listed in the library docs.
///
/// Returns `0` when [playerId] does not resolve to a player or when no
/// in-scope orders are staged for that player.
///
/// Affordability gating mirrors the live resolver: an order whose
/// sequential `canAfford*` check fails (insufficient treasury,
/// materials, workers, or tech) is **skipped** so the projection
/// matches what the resolver actually deducts. Order processing
/// happens in the same resolver order (recruit → build → research) so
/// running treasury / stockpile state stays consistent with phase 12
/// worker-pool-before-builds resolution.
int pendingTreasuryCostsForTurn(
  Game game,
  String playerId,
  Orders currentOrders,
) {
  final player = game.playerById(playerId);
  if (player == null) return 0;

  final recruits = currentOrders.recruitWorkerOrdersByPlayerId[playerId];
  final builds = currentOrders.buildUnitOrdersByPlayerId[playerId];
  final researches = currentOrders.researchOrdersByPlayerId[playerId];
  final hasRecruits = recruits != null && recruits.isNotEmpty;
  final hasBuilds = builds != null && builds.isNotEmpty;
  final hasResearches = researches != null && researches.isNotEmpty;
  if (!hasRecruits && !hasBuilds && !hasResearches) return 0;

  var workers = player.workerPool;
  var stockpile = player.stockpile;
  var treasury = player.treasury;
  var spent = 0;

  if (hasRecruits) {
    for (final order in recruits) {
      final check = canAffordRecruitWorker(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) continue;
      final after = applyRecruitWorkerCostDeduction(
        order,
        workers,
        stockpile,
        treasury,
      );
      spent += treasury - after.treasury;
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
  }

  if (hasBuilds) {
    for (final order in builds) {
      final check = ProjectedCostEngine.canAffordBuildOrder(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) continue;
      final after = ProjectedCostEngine.applyBuildOrderCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      spent += treasury - after.treasury;
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
  }

  if (hasResearches) {
    for (final order in researches) {
      if (order.techId.isEmpty) continue;
      final cost = treasuryCostForFunding(order.funding);
      if (cost <= 0) continue;
      if (treasury < cost) continue;
      spent += cost;
      treasury -= cost;
    }
  }

  return spent;
}
