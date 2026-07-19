// S7-D lock-recovery diagnostic castIron-labour counters (Refs #2847 / #3941 / #4079 Slice D).
// Split from the former monolithic lock_recovery_probes.dart.

import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show otherGreatPowerFabricHeld;
import 'package:colonizethis_ai/src/planning/treasury_planner.dart'
    show otherGreatPowerOfferableFabricHeld;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'supply_probes.dart';

/// True iff [playerId] owns at least one idle Builder for which the work-order
/// engine **accepts** a `build_improvement` on an owned unimproved feedstock
/// tile (a member of [feedstockIds]) — i.e. `getValidWorkOrderTileKeys` (the
/// same validator chain `suggestWorkOrders` runs) actually emits a candidate
/// the Full-AI civilian selection could route the Builder onto this turn.
///
/// This is the decisive split for the H8-extraction missing-candidate
/// hypothesis (Refs #2847): with an idle Builder present
/// (`gpFeedstockGateIdleBuilderPresentTurns` == gate-active turns) and an
/// unimproved feedstock tile owned (`gpUnimprovedFeedstockTileOwnedTurns` ==
/// 100) yet `gpFeedstockGateImprovedTileOwnedTurns` == 0, a near-zero count
/// here confirms the work-order validator suppresses the candidate before any
/// selection boost applies (the #3234 boost only biases a candidate that
/// exists); a high count would instead re-point the break downstream to the
/// selection / orchestrator / phase-filter stage. Read-only —
/// `getValidWorkOrderTileKeys` does not mutate game state.
void recordSeed42S7dCastIronLabourCounters({
  required Game game,
  required String gpId,
  required ({
    bool peasantRecruitGate,
    bool peasantRecruitAffordable,
    bool holdsFabricFeedstock,
    bool fabricRecipeFeasible,
    bool fabricRecipeLabourFeasible,
    bool castIronMaterialFeasible,
    bool castIronLabourFeasible,
    bool castIronLabourFoodStarved,
    bool castIronLabourPopulationBound,
    bool castIronOwnsFeedstockTile,
  })
  ci,
  required Set<String> fabricStarvedThisTurn,
  required Map<String, int> castIronLabourPeasantRecruitGateTurns,
  required Map<String, int> castIronLabourPeasantRecruitAffordableTurns,
  required Map<String, int> castIronLabourPeasantRecruitFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricStarvedTurns,
  required Map<String, int>
  castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
  required Map<String, int> feedstockInStockpileTurns,
  required Map<String, int> fabricRecipeFeasibleTurns,
  required Map<String, int> fabricRecipeLabourFeasibleTurns,
  required Map<String, int> castIronRecipeFeasibleTurns,
  required Map<String, int> castIronRecipeLabourFeasibleTurns,
  required Map<String, int> castIronLabourFoodStarvedTurns,
  required Map<String, int> castIronLabourPopulationBoundTurns,
  required Map<String, int> castIronFeasibleOwnsFeedstockTileTurns,
}) {
  if (ci.peasantRecruitGate) {
    bumpCounter(castIronLabourPeasantRecruitGateTurns, gpId);
    if (ci.peasantRecruitAffordable) {
      bumpCounter(castIronLabourPeasantRecruitAffordableTurns, gpId);
    } else {
      bumpCounter(castIronLabourPeasantRecruitFabricStarvedTurns, gpId);
      fabricStarvedThisTurn.add(gpId);
      recordSeed42S7dPeasantRecruitFabricMarketSubCause(
        game: game,
        gpId: gpId,
        marketFabricStarvedTurns:
            castIronLabourPeasantRecruitMarketFabricStarvedTurns,
        marketFabricUnofferedTurns:
            castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
      );
    }
  }
  if (ci.holdsFabricFeedstock) {
    bumpCounter(feedstockInStockpileTurns, gpId);
  }
  if (ci.fabricRecipeFeasible) {
    bumpCounter(fabricRecipeFeasibleTurns, gpId);
    if (ci.fabricRecipeLabourFeasible) {
      bumpCounter(fabricRecipeLabourFeasibleTurns, gpId);
    }
  }
  if (ci.castIronMaterialFeasible) {
    bumpCounter(castIronRecipeFeasibleTurns, gpId);
    // Split the material-feasible turns by the planner's labour gate and by the
    // staging gate's tile-ownership precondition.
    recordSeed42S7dCastIronLabourFork(
      gpId: gpId,
      castIronLabourFeasible: ci.castIronLabourFeasible,
      castIronLabourFoodStarved: ci.castIronLabourFoodStarved,
      castIronLabourPopulationBound: ci.castIronLabourPopulationBound,
      castIronRecipeLabourFeasibleTurns: castIronRecipeLabourFeasibleTurns,
      castIronLabourFoodStarvedTurns: castIronLabourFoodStarvedTurns,
      castIronLabourPopulationBoundTurns: castIronLabourPopulationBoundTurns,
    );
    if (ci.castIronOwnsFeedstockTile) {
      bumpCounter(castIronFeasibleOwnsFeedstockTileTurns, gpId);
    }
  }
}

/// Records the peasant-recruit fabric-starved market sub-cause split for [gpId]
/// (Refs #2847 § S7-D market-fabric localization).
///
/// Of the fabric-starved recruit turns, bumps [marketFabricStarvedTurns] when no
/// other great power holds any `fabric` to sell (the recruit `fabric` can be
/// neither produced nor bought), else bumps [marketFabricUnofferedTurns] when
/// holders exist but every one withholds its `fabric` via the regiment-rebuild
/// offer-retention carve-out (the market door is closed at the offer/retention
/// layer, not at holdings). Read-only over `game` except the counter bumps.
void recordSeed42S7dPeasantRecruitFabricMarketSubCause({
  required Game game,
  required String gpId,
  required Map<String, int> marketFabricStarvedTurns,
  required Map<String, int> marketFabricUnofferedTurns,
}) {
  if (otherGreatPowerFabricHeld(game, gpId) <= 0) {
    bumpCounter(marketFabricStarvedTurns, gpId);
    return;
  }
  if (otherGreatPowerOfferableFabricHeld(game, gpId) <= 0) {
    bumpCounter(marketFabricUnofferedTurns, gpId);
  }
}

/// Records the castIron material-feasible labour fork for [gpId] (Refs #2847
/// § S7-D).
///
/// On a material-feasible turn, bumps exactly one of the three labour-stage
/// counters following the planner's labour-gate precedence: labour-feasible,
/// else food-starved, else population-bound. A material-feasible turn that is
/// none of these (e.g. another labour gate) bumps no labour-stage counter.
void recordSeed42S7dCastIronLabourFork({
  required String gpId,
  required bool castIronLabourFeasible,
  required bool castIronLabourFoodStarved,
  required bool castIronLabourPopulationBound,
  required Map<String, int> castIronRecipeLabourFeasibleTurns,
  required Map<String, int> castIronLabourFoodStarvedTurns,
  required Map<String, int> castIronLabourPopulationBoundTurns,
}) {
  if (castIronLabourFeasible) {
    bumpCounter(castIronRecipeLabourFeasibleTurns, gpId);
    return;
  }
  if (castIronLabourFoodStarved) {
    bumpCounter(castIronLabourFoodStarvedTurns, gpId);
    return;
  }
  if (castIronLabourPopulationBound) {
    bumpCounter(castIronLabourPopulationBoundTurns, gpId);
  }
}
