// Lock-recovery castIron labour population-bound gate (Refs #2847).
//
// Pure read-only predicates shared by `planExpandEconomy` and the domain
// orchestrator peasant-recruitment pass. Mirrors the S7-D fork captured in
// PR #3298 / #3300: material-feasible `castIron` turns where effective labour
// is below one run because the raw population ceiling itself is too small
// (all workers fed — not a food-starvation case).

import 'ai_commodity_ids.dart';
import 'planning_imports.dart';
import 'recipe_scoring.dart' show feasibleRuns;

const String kCastIronCommodityId = 'castIron';

/// True when [playerId] is a below-quota zero-NW lock-recovery seller that
/// still needs domestically produced [kCastIronCommodityId], holds enough
/// feedstock for one `castIron_from_timber_iron_coal` run, yet cannot assign
/// that run because even fully-fed workers supply less labour than
/// [ProductionRecipesCatalog.castIronFromTimberIronCoal.labourPerOutput].
///
/// Scoped to sellers the H8 castIron chain already routes (`regimentCount ==
/// 0`, below OW quota, zero NW provinces) so healthy +6 baseline GPs holding
/// regiments never receive the recruitment boost. Pure and deterministic.
bool isCastIronLabourPopulationBoundForLockRecoverySeller({
  required Game game,
  required String playerId,
}) {
  final stageable = selfLockRecoverySellerStageableImprovementInputs(
    game,
    playerId,
  );
  if (!stageable.contains(kCastIronCommodityId)) return false;

  final player = game.playerById(playerId);
  if (player == null) return false;

  final recipe = ProductionRecipesCatalog.castIronFromTimberIronCoal;
  final materialFeasible = recipe.inputQuantities.entries.every(
    (e) => player.stockpile.quantityOf(e.key) >= e.value,
  );
  if (!materialFeasible) return false;

  final effectiveLabour = effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
    regimentCountsById: regimentTypeCountsForPlayer(game.worldState, playerId),
    shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
  );
  if (feasibleRuns(
        recipe: recipe,
        stockpile: player.stockpile,
        remainingLabour: effectiveLabour,
      ) >
      0) {
    return false;
  }

  final rawLabour = player.workerPool.labourSupplyPerTurn;
  return rawLabour < recipe.labourPerOutput && effectiveLabour == rawLabour;
}

/// Total `fabric` held in the stockpiles of every great power **other than**
/// [playerId] this turn — the gross world-market `fabric` supply a
/// fabric-starved lock-recovery seller could, in principle, buy the 2-`fabric`
/// peasant-recruit cost from.
///
/// The peasant recruit is the only raw-population-growth row in
/// [WorkerActionEconomyCatalog] (apprentice/journeyman/master each *consume* an
/// existing peasant rather than grow the population) and it costs 2 `fabric`. A
/// below-quota zero-NW zero-regiment lock-recovery seller cannot produce that
/// `fabric` itself — `fabric_from_*` carries `labourPerOutput == 2`, above the
/// seller's effective labour of 1 (the #3317 circular-labour deadlock) — so the
/// only remaining lever to grow raw labour is to *buy* the `fabric`. This sums
/// the `fabric` other great powers hold as a gross-availability proxy: a value
/// of 0 means no counterparty holds any `fabric` to sell, closing the market
/// door too and leaving a rules-level bootstrap as the only remaining
/// raw-population-growth lever. It is a holdings proxy, not a full world-market
/// offer/match simulation. Pure read-only over `game.players`; no game-state
/// mutation.
int otherGreatPowerFabricHeld(Game game, String playerId) {
  var total = 0;
  for (final player in game.players) {
    if (player.id == playerId) continue;
    total += player.stockpile.quantityOf(kAiCommodityIds.fabric);
  }
  return total;
}

/// True when [stockpile] holds less than the peasant
/// [RecruitWorkerOrder] `fabric` material cost
/// ([WorkerActionEconomyCatalog.peasant] = 2) while the castIron-labour
/// peasant-recruitment path is active.
///
/// Regiment build only requires 1 `fabric`, so a seller holding exactly one
/// unit is not short for [RegimentEconomyCatalog.peasantLevies] yet still
/// cannot pay the 2-`fabric` peasant recruit row — the #3303 circular-fabric
/// lock the S7-D diagnostic localized for gp5 (Refs #2847).
bool isCastIronLabourPeasantRecruitFabricShort(Stockpile stockpile) {
  final required =
      WorkerActionEconomyCatalog.peasant.materialCosts[kAiCommodityIds.fabric] ??
      0;
  if (required <= 0) return false;
  return stockpile.quantityOf(kAiCommodityIds.fabric) < required;
}

/// True when [playerId] is a below-quota zero-NW lock-recovery seller in the
/// castIron-labour peasant-recruit fabric market path: population-bound for
/// domestic `castIron` production and short the 2-`fabric` peasant recruit
/// cost. Unlike the zero-regiment rebuild bootstrap, this predicate does **not**
/// require `regimentCount == 0` — a seller holding regiments can still need
/// market `fabric` to grow raw labour (Refs #2847 § labour-infeasible fabric
/// market path).
bool isCastIronLabourPeasantRecruitFabricMarketPathActive({
  required Game game,
  required String playerId,
  required Stockpile projected,
}) {
  if (!isCastIronLabourPopulationBoundForLockRecoverySeller(
    game: game,
    playerId: playerId,
  )) {
    return false;
  }
  return isCastIronLabourPeasantRecruitFabricShort(projected);
}

/// True when at least one `fabric_from_*` recipe is materially feasible for
/// [playerId] yet **no** such recipe can run one full output given the GP's
/// effective labour (`labourPerOutput` exceeds remaining labour). On seed 42
/// the failing lock-recovery sellers hold `wool` / `cotton` on many turns but
/// `fabric_from_*` needs `labourPerOutput == 2` while effective labour is `1`
/// — domestic conversion is dead and the peasant-recruit path must buy `fabric`
/// from the world market instead (Refs #2847 § #3317 circular-labour deadlock).
bool isDomesticFabricProductionLabourInfeasible({
  required Game game,
  required String playerId,
}) {
  final player = game.playerById(playerId);
  if (player == null) return false;

  final effectiveLabour = effectiveLabourForWorkers(
    workers: player.workerPool,
    stockpile: player.stockpile,
    regimentCountsById: regimentTypeCountsForPlayer(game.worldState, playerId),
    shipCountsById: shipTypeCountsForPlayer(game.worldState, playerId),
  );
  final fabricId = kAiCommodityIds.fabric;
  var anyMaterialFeasible = false;
  for (final recipe in ProductionRecipesCatalog.producing(fabricId)) {
    final materialFeasible = recipe.inputQuantities.entries.every(
      (e) => player.stockpile.quantityOf(e.key) >= e.value,
    );
    if (!materialFeasible) continue;
    anyMaterialFeasible = true;
    if (feasibleRuns(
          recipe: recipe,
          stockpile: player.stockpile,
          remainingLabour: effectiveLabour,
        ) >
        0) {
      return false;
    }
  }
  return anyMaterialFeasible;
}
