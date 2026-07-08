// S7-D feedstock extraction / castIron-labour measurement probes
// (Refs #2847 / #3941). Split from `seed42_s7d_feedstock_helpers.dart`.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart'
    show AIWorldSnapshot;
import 'package:colonizethis_ai/src/planning/army_conquest_prep.dart'
    show regimentCountForPlayer;
import 'package:colonizethis_ai/src/planning/cast_iron_labour_gate.dart'
    show isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/planning_imports.dart'
    show ownsFeedstockResourceTile;
import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'supply_probes.dart';

/// Per-turn castIron-labour stage-localization measurement for one GP (Refs
/// #2847). Pure read-only over `(game, playerId)`: bundles the boolean flags
/// the S7-D diagnostic increments each turn so the caller only applies counter
/// bumps. Mirrors the inline measurement it replaced exactly —
///
///   * `peasantRecruitGate` / `peasantRecruitAffordable` —
///     [castIronLabourPeasantRecruitProbe] (the #3303 boost localization).
///   * `holdsFabricFeedstock` — any [fabricFeedstockIds] held in the stockpile.
///   * `fabricRecipeFeasible` — any [fabricRecipes] materially runnable.
///   * `fabricRecipeLabourFeasible` — any [fabricRecipes] runnable against the
///     seller's full effective labour too
///     ([stockpileAndLabourAffordAnyProductionRecipe]). Always a subset of
///     `fabricRecipeFeasible`. A near-zero count here while
///     `fabricRecipeFeasible` is high localizes the unbuilt peasant-recruit
///     `fabric` to **labour starvation of the fabric recipe itself**
///     (`fabric_from_*` carries `labourPerOutput == 2`, above a lock-recovery
///     seller's effective labour of 1), i.e. the #3303/#3315 peasant-recruit
///     boost is a circular deadlock: growing castIron labour needs a peasant,
///     the peasant needs `fabric`, and `fabric` itself needs labour the seller
///     does not have — so the lever cannot be domestic `fabric` and must grow
///     raw population by a non-`fabric` path.
///   * `castIronMaterialFeasible` — any [castIronRecipes] materially runnable
///     ([stockpileAffordsAnyProductionRecipe]); the labour / food / tile flags
///     below are only meaningful (non-false) when this holds.
///   * `castIronLabourFeasible` — material-feasible **and** labour-feasible
///     ([stockpileAndLabourAffordAnyProductionRecipe]).
///   * `castIronLabourFoodStarved` / `castIronLabourPopulationBound` — the
///     material-feasible-but-labour-infeasible fork keyed on
///     [castIronMinLabourPerOutput] vs [playerRawLabourSupply] (fully-fed
///     ceiling would fund a run vs ceiling itself below one run); both false
///     when [castIronMinLabourPerOutput] is not positive.
///   * `castIronOwnsFeedstockTile` — owns a castIron feedstock tile at any
///     level ([ownsFeedstockResourceTileAnyLevel]).
///
/// All flags are false for an unknown player. No game-state mutation.
({
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
seed42S7dCastIronLabourTurnMeasure({
  required Game game,
  required String playerId,
  required Set<String> fabricFeedstockIds,
  required List<ProductionRecipe> fabricRecipes,
  required List<ProductionRecipe> castIronRecipes,
  required Set<String> castIronFeedstockIds,
  required int castIronMinLabourPerOutput,
}) {
  const none = (
    peasantRecruitGate: false,
    peasantRecruitAffordable: false,
    holdsFabricFeedstock: false,
    fabricRecipeFeasible: false,
    fabricRecipeLabourFeasible: false,
    castIronMaterialFeasible: false,
    castIronLabourFeasible: false,
    castIronLabourFoodStarved: false,
    castIronLabourPopulationBound: false,
    castIronOwnsFeedstockTile: false,
  );
  final player = game.playerById(playerId);
  if (player == null) return none;
  final recruit = castIronLabourPeasantRecruitProbe(game, playerId);
  final holdsFabricFeedstock = fabricFeedstockIds.any(
    (id) => player.stockpile.quantityOf(id) > 0,
  );
  final fabricRecipeFeasible = fabricRecipes.any(
    (recipe) => recipe.inputQuantities.entries.every(
      (e) => player.stockpile.quantityOf(e.key) >= e.value,
    ),
  );
  // Labour-aware fabric feasibility (Refs #2847 § S7-D fabric circular-labour
  // localization). A subset of `fabricRecipeFeasible`: a fabric run needs both
  // its feedstock on hand AND `labourPerOutput` effective labour. Skipped when
  // the cheaper material check already failed.
  final fabricRecipeLabourFeasible =
      fabricRecipeFeasible &&
      stockpileAndLabourAffordAnyProductionRecipe(
        game,
        playerId,
        fabricRecipes,
      );
  final castIronMaterialFeasible = stockpileAffordsAnyProductionRecipe(
    player.stockpile,
    castIronRecipes,
  );
  var castIronLabourFeasible = false;
  var foodStarved = false;
  var populationBound = false;
  var ownsTile = false;
  if (castIronMaterialFeasible) {
    castIronLabourFeasible = stockpileAndLabourAffordAnyProductionRecipe(
      game,
      playerId,
      castIronRecipes,
    );
    if (!castIronLabourFeasible && castIronMinLabourPerOutput > 0) {
      if (playerRawLabourSupply(game, playerId) >= castIronMinLabourPerOutput) {
        foodStarved = true;
      } else {
        populationBound = true;
      }
    }
    ownsTile = ownsFeedstockResourceTileAnyLevel(
      game,
      playerId,
      castIronFeedstockIds,
    );
  }
  return (
    peasantRecruitGate: recruit.gateActive,
    peasantRecruitAffordable: recruit.affordable,
    holdsFabricFeedstock: holdsFabricFeedstock,
    fabricRecipeFeasible: fabricRecipeFeasible,
    fabricRecipeLabourFeasible: fabricRecipeLabourFeasible,
    castIronMaterialFeasible: castIronMaterialFeasible,
    castIronLabourFeasible: castIronLabourFeasible,
    castIronLabourFoodStarved: foodStarved,
    castIronLabourPopulationBound: populationBound,
    castIronOwnsFeedstockTile: ownsTile,
  );
}

/// Builds the per-GP turn-99 snapshot field map cached for the S7-D
/// diagnostic rollup (Refs #2847). Pure read-only construction over
/// `(game, playerId, snap)`: the conquest/colonial/threat snapshot fields, the
/// treasury and regiment trajectory, the cheapest-regiment treasury floor, and
/// the castIron labour-starvation corroboration trio (effective food-fed
/// labour, raw fully-fed ceiling, and [foodCommodityIds] on hand at the
/// terminal turn). Extracted to keep the diagnostic test file at or below the
/// repo non-comment line limit; no game-state mutation.
Map<String, Object?> seed42S7dTurn99SnapshotFields({
  required Game game,
  required String playerId,
  required AIWorldSnapshot snap,
  required Set<String> foodCommodityIds,
}) {
  final player = game.playerById(playerId);
  return <String, Object?>{
    'oldWorldProvincesOwned': snap.conquest.oldWorldProvincesOwned,
    'invadableProvinceCount': snap.conquest.invadableProvinceIdsSorted.length,
    'nwInvadableCount': snap.colonial.invadableNewWorldProvinceIdsSorted.length,
    'atWarWith': snap.threats.atWarWith.toList()..sort(),
    'adjacentOwnerFactionIdsSorted':
        snap.conquest.adjacentOwnerFactionIdsSorted,
    'treasury': player?.treasury,
    'regimentCount': regimentCountForPlayer(game, playerId),
    'cheapestRegimentBuildTreasuryCost': cheapestRegimentBuildTreasuryCost(),
    'effectiveLabour': playerEffectiveLabour(game, playerId),
    'rawLabourSupply': playerRawLabourSupply(game, playerId),
    'foodOnHand': playerFoodOnHand(game, playerId, foodCommodityIds),
  };
}

/// Read-only probe for the #3303 castIron-labour peasant-recruit boost
/// localization (Refs #2847). Returns whether the boost's distinguishing gate
/// predicate `isCastIronLabourPopulationBoundForLockRecoverySeller` holds for
/// [playerId] this turn, and — when it does — whether the seller can actually
/// pay the peasant `RecruitWorkerOrder` cost row
/// (`WorkerActionEconomyCatalog.peasant`, which costs 2 `fabric`) via
/// `canAffordRecruitWorker`.
///
/// The `affordable == false` branch (gate active yet cost unpayable) isolates
/// the suspected circular dependency that renders the #3303 boost a structural
/// no-op: recruiting the peasant that would grow castIron labour itself needs
/// `fabric`, the very downstream commodity the castIron chain exists to
/// unblock. `affordable` is `false` when the gate is inactive. Pure read-only
/// over `(game, playerId)`; no game-state mutation.
({bool gateActive, bool affordable}) castIronLabourPeasantRecruitProbe(
  Game game,
  String playerId,
) {
  if (!isCastIronLabourPopulationBoundForLockRecoverySeller(
    game: game,
    playerId: playerId,
  )) {
    return (gateActive: false, affordable: false);
  }
  final player = game.playerById(playerId);
  if (player == null) return (gateActive: true, affordable: false);
  final affordable = canAffordRecruitWorker(
    player,
    const RecruitWorkerOrder(targetTier: WorkerTier.peasant),
    player.workerPool,
    player.stockpile,
    player.treasury,
  ).canAfford;
  return (gateActive: true, affordable: affordable);
}

/// True iff [playerId] owns at least one province tile hosting one of
/// [feedstockIds] at **any** improvement level (improved or unimproved).
///
/// This is the tile-ownership precondition the lock-recovery-seller castIron
/// staging gate (`full_ai_civilian_work_selection_feedstock.dart` §
/// `selfLockRecoverySellerStageableImprovementInputs` →
/// [ownsFeedstockResourceTile]) applies before it stages a domestic `castIron`
/// run: a below-quota zero-NW zero-regiment seller only stages `castIron` when
/// it still owns a `timber` / `iron` feedstock tile to extract from. The
/// existing [ownsUnimprovedFeedstockResourceTile] /
/// [ownsImprovedFeedstockResourceTile] probes split by improvement level; this
/// any-level probe delegates to the production symbol via [planning_imports].
///
/// Used by the H8 castIron production-allocation localization (Refs #2847): on
/// the castIron material-feasible turns, a flat-zero count here while the seller
/// **holds** `timber` / `iron` commodities localizes the unfired staging gate to
/// **tile ownership** (the seller accumulated the feedstock by trade / past
/// extraction but no longer owns a resource tile, so the staging gate stays
/// shut), re-pointing the next behaviour slice to broaden the gate to fire on
/// held feedstock; a non-zero count instead clears tile ownership as the cause.
/// Read-only scan over owned provinces.
bool ownsFeedstockResourceTileAnyLevel(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) => ownsFeedstockResourceTile(game, playerId, feedstockIds);

bool hasValidBuildImprovementOnUnimprovedFeedstockTile(
  Game game,
  MapTopology topology,
  String playerId,
  Set<String> feedstockIds, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork != null) continue;
    final valid = getValidWorkOrderTileKeys(
      game,
      topology,
      playerId,
      unit.id,
      kWorkTargetBuildImprovement,
      const Orders(),
      tileMapByRegion: tileMapByRegion,
    );
    for (final tileKey in valid) {
      final resourceId = ws.resourceByTileKey[tileKey];
      if (resourceId == null || !feedstockIds.contains(resourceId)) continue;
      if (ws.tileState.improvementLevel(tileKey) < 1) return true;
    }
  }
  return false;
}

/// Applies the per-turn castIron-labour stage-localization counter bumps for one
/// GP from a [seed42S7dCastIronLabourTurnMeasure] result [ci] (Refs #2847).
///
/// Mirrors the inline counter cascade it replaced exactly: the #3303
/// peasant-recruit gate / affordability split (adding fabric-starved GPs to
/// [fabricStarvedThisTurn] and forking the market-fabric-starved vs
/// market-fabric-unoffered sub-causes off `game`), the fabric feedstock /
/// recipe feasibility counters, and the castIron material / labour-fork /
/// owns-feedstock-tile counters. Extracted to keep the diagnostic test file at
/// or below the repo non-comment line limit
/// (`repo.dart_file_non_comment_line_size`); read-only over `game` except the
