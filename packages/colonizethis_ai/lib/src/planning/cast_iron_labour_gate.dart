// Lock-recovery castIron labour population-bound gate (Refs #2847).
//
// Pure read-only predicates shared by `planExpandEconomy` and the domain
// orchestrator peasant-recruitment pass. Mirrors the S7-D fork captured in
// PR #3298 / #3300: material-feasible `castIron` turns where effective labour
// is below one run because the raw population ceiling itself is too small
// (all workers fed — not a food-starvation case).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
