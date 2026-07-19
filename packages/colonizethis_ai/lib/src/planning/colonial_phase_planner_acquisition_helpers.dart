/// Colonial acquisition target-finder helpers (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'colonial_phase_planner_acquisition.dart'
    show AcquisitionMethod, ColonialAcquisitionTarget;
import 'expand_phase_planner_economy.dart' show cheapestRegimentBuildTreasuryCost;
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;

/// True when [personalityId] resolves to a personality whose
/// `warLikelihood` strictly exceeds its `allianceTendency` per
/// `personalityThresholds` in `ai_personality_config.dart` — the
/// militaristic-leader bias defined in
/// `SPEC/ai/phase-planner-architecture.md` § Personality bias.
///
/// Returns `false` when [personalityId] is `null`, unknown, or
/// resolves to a personality whose thresholds are equal or
/// alliance-leaning (`warLikelihood <= allianceTendency`). The
/// resolution uses [personalityLookupKeyForAi] so leader-key aliases
/// (e.g. `france_leader` → `napoleon`) map to canonical thresholds
/// before the comparison, matching the rest of `colonizethis_ai`.
///
/// Pure: depends only on the static `personalityThresholds` map in
/// `colonizethis_data` and the input string, so the comparison is
/// deterministic for fixed inputs (Refs #2509 Must-have #7).
bool acquisitionPersonalityPrefersWarOverAlliance(String? personalityId) {
  if (personalityId == null) return false;
  final thresholds = getThresholdsForLeader(personalityId);
  return thresholds.warLikelihood > thresholds.allianceTendency;
}

/// Shared search inputs for the three colonial acquisition target finders
/// (Refs #3822 Phase 3).
final class AcquisitionSearchContext {
  const AcquisitionSearchContext({
    required this.game,
    required this.snapshot,
    required this.invadable,
    required this.provinceOwner,
    required this.treasury,
    required this.ownColonyTribeIds,
  });

  final Game game;
  final AIWorldSnapshot snapshot;
  final List<String> invadable;
  final Map<String, String> provinceOwner;
  final int treasury;
  final Set<String> ownColonyTribeIds;
}

/// Iterates [invadable] in distance order and returns the first
/// [AcquisitionMethod.joinEmpire] candidate satisfying the four
/// Join-Empire gates (non-GP owner, overture stage `nap`, relation
/// score ≥ Friendly, treasury ≥ `joinEmpireCostForMinorOrTribe`).
ColonialAcquisitionTarget? acquisitionFindJoinEmpireTarget(
  AcquisitionSearchContext ctx,
) {
  for (final provinceId in ctx.invadable) {
    final ownerId = ctx.provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (ctx.game.playerById(ownerId) != null) continue;
    if (ctx.ownColonyTribeIds.contains(ownerId)) continue;

    final overture = getOverture(ctx.game, ctx.snapshot.playerId, ownerId);
    if (overture == null) continue;
    if (overture.stage != OvertureStage.nap) continue;

    final relation = getRelation(ctx.game, ctx.snapshot.playerId, ownerId);
    if (relation == null || relation.score < relationScoreMinFriendly) {
      continue;
    }

    final cost = joinEmpireCostForMinorOrTribe(ctx.game, ownerId);
    if (ctx.treasury < cost) continue;

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.joinEmpire,
    );
  }
  return null;
}

/// Iterates [invadable] in distance order and returns the
/// [AcquisitionMethod.purchaseLand] candidate whose owner has the
/// **highest relation score** among all owners satisfying the Method 2
/// gates (idle Merchant, embassy with owner, not at war, per-tile
/// resource + treasury gates).
///
/// Overseas-profit-aware selection (Refs #3758 R7 / S6;
/// `SPEC/ai/phase-planner-architecture.md` § Overseas-profit-aware
/// purchase-land target selection): buying land on a tribe/minor tile
/// earns an ongoing overseas profit share `(relationScore / 100) × 0.40`
/// (`SPEC/game/world-market.md` § Overseas profit), so a higher-relation
/// owner yields a strictly larger share for the same future sales. The
/// arm therefore prefers the highest-relation eligible owner rather than
/// the first in iteration order. Ties (equal highest relation score) fall
/// back to the [invadable] iteration order via a **strict** `>`
/// comparison that keeps the earliest-encountered owner, preserving the
/// legacy first-match deterministic tiebreak (Refs #2509 Must-have #7).
/// A missing relation row contributes [relationScoreNeutral] (50),
/// matching the score-default convention used elsewhere in the planners.
ColonialAcquisitionTarget? acquisitionFindPurchaseLandTarget(
  AcquisitionSearchContext ctx,
) {
  if (!acquisitionHasIdleMerchant(ctx.game.worldState, ctx.snapshot.playerId)) {
    return null;
  }
  final prospected =
      ctx.game.worldState.playerProspectedTiles[ctx.snapshot.playerId] ??
      const <String>{};
  final purchasedByTile = ctx.game.worldState.purchasedTilesByTileKey;

  String? bestOwnerId;
  num bestScore = 0;
  for (final provinceId in ctx.invadable) {
    final ownerId = ctx.provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (ctx.game.playerById(ownerId) != null) continue;
    if (ctx.ownColonyTribeIds.contains(ownerId)) continue;

    final relation = getRelation(ctx.game, ctx.snapshot.playerId, ownerId);
    if (relation != null && relation.atWar) continue;

    final overture = getOverture(ctx.game, ctx.snapshot.playerId, ownerId);
    if (overture == null || !overture.hasEmbassy) continue;

    if (!acquisitionProvinceHasValidPurchaseLandTile(
      world: ctx.game.worldState,
      provinceId: provinceId,
      treasury: ctx.treasury,
      prospected: prospected,
      purchasedByTile: purchasedByTile,
    )) {
      continue;
    }

    final num relationScore = relation?.score ?? relationScoreNeutral;
    if (bestOwnerId == null || relationScore > bestScore) {
      bestOwnerId = ownerId;
      bestScore = relationScore;
    }
  }

  if (bestOwnerId == null) return null;
  return ColonialAcquisitionTarget(
    targetFactionId: bestOwnerId,
    method: AcquisitionMethod.purchaseLand,
  );
}

/// Iterates [invadable] in distance order and returns the first
/// [AcquisitionMethod.declareWar] candidate satisfying the outer
/// gates (regiments ≥ 1, treasury ≥ cheapest regiment cost) and the
/// per-province gates (non-GP owner, not already at war).
ColonialAcquisitionTarget? acquisitionFindDeclareWarTarget(
  AcquisitionSearchContext ctx, {
  required bool waiveTreasuryGate,
}) {
  if (regimentCountForPlayer(ctx.game, ctx.snapshot.playerId) <= 0) {
    return null;
  }
  if (!waiveTreasuryGate &&
      ctx.treasury < cheapestRegimentBuildTreasuryCost()) {
    return null;
  }

  for (final provinceId in ctx.invadable) {
    final ownerId = ctx.provinceOwner[provinceId];
    if (ownerId == null) continue;
    if (ctx.game.playerById(ownerId) != null) continue;
    if (ctx.ownColonyTribeIds.contains(ownerId)) continue;

    final relation = getRelation(ctx.game, ctx.snapshot.playerId, ownerId);
    if (relation != null && relation.atWar) continue;

    return ColonialAcquisitionTarget(
      targetFactionId: ownerId,
      method: AcquisitionMethod.declareWar,
    );
  }
  return null;
}

/// Tribe ids that are already [playerId]'s own colony
/// (`ColonyState.colonyOfGpId == playerId`).
///
/// Colony tribes stay in the game and keep owning NW provinces after Tribe
/// Join Empire resolves, so they remain in the invadable list. The acquisition
/// arms exclude these owners so the planner never re-targets its own colony
/// (Refs #3758 R4 / S3; SPEC/ai/phase-planner-architecture.md § Own-colony
/// exclusion; SPEC/game/diplomacy.md § GP–Tribe Join Empire → colony). Colonies
/// of a different GP are intentionally not excluded.
Set<String> acquisitionOwnColonyTribeIds(Game game, String playerId) => <String>{
  for (final colony in game.colonyStates)
    if (colony.colonyOfGpId == playerId) colony.tribeId,
};

/// Iteration order over NW invadable provinces for
/// [planColonialAcquisition], honoring the spec's adjacency-distance
/// requirement (Refs #2509 § COLONIAL phase planner §
/// planColonialAcquisition -- "sorted by adjacency distance to owned
/// territory").
///
/// Returns [ColonialSummary.invadableNewWorldProvinceIdsByDistance]
/// when the snapshot was built with a [MapTopology] (the normal
/// production path; the perception-snapshot builder populates the
/// distance-sorted field via
/// [reachableNonOwnedProvinceDistancesViaSeas]). Falls back to the
/// lex-sorted [ColonialSummary.invadableNewWorldProvinceIdsSorted]
/// for synthetic fixtures that build snapshots without a topology
/// (today: the COLONIAL acquisition unit tests). The fallback
/// preserves backward-compatible behavior for the legacy pin set
/// (sort-by-province-id tiebreaks) while production play uses the
/// distance-sorted iteration the spec mandates.
///
/// The function never throws or returns null: if the snapshot has
/// neither field populated (e.g. an outer COLONIAL guard already
/// short-circuited to an empty invadable set upstream), it returns
/// the empty list and the caller's outer-guard short-circuits as
/// today.
List<String> acquisitionIterationOrder(ColonialSummary colonial) {
  if (colonial.invadableNewWorldProvinceIdsByDistance.isNotEmpty) {
    return colonial.invadableNewWorldProvinceIdsByDistance;
  }
  return colonial.invadableNewWorldProvinceIdsSorted;
}

/// True when [playerId] owns at least one [kUnitTypeMerchant] unit
/// with [UnitStatus.idle] in either region. Region of the Merchant is
/// not constrained — the orchestrator and resolver handle staging
/// movement on follow-up turns (mirrors the Builder selection
/// convention in [planColonialCivilian]).
bool acquisitionHasIdleMerchant(WorldState world, String playerId) {
  for (final unit in allUnitsFromWorld(world)) {
    if (unit.ownerId == playerId &&
        unit.type == kUnitTypeMerchant &&
        unit.status == UnitStatus.idle) {
      return true;
    }
  }
  return false;
}

/// True when [provinceId] contains at least one tile satisfying every
/// per-tile gate from `precheckPurchaseLand`:
///
///   - non-empty resource id in [WorldState.resourceByTileKey];
///   - not present in [purchasedByTile] (no other GP has bought it,
///     and the active player has not already purchased it either);
///   - mineral resource ids ([kMineralResourceIds]) require the tile
///     to be in [prospected] (the active player's prospected-tile
///     set);
///   - [purchaseLandCost] for the resource must be within [treasury].
///
/// Iteration over [WorldState.resourceByTileKey] is bounded by the
/// total number of tiles with a resource entry (much smaller than the
/// global tile count); per-tile checks are O(1). The function returns
/// the existence answer only — picking a specific tile for the
/// `purchase_land` work order is the orchestrator's job (the planner
/// contract returns the *target faction* and the *method*, not the
/// exact tile, mirroring the [AcquisitionMethod.joinEmpire] return
/// shape).
bool acquisitionProvinceHasValidPurchaseLandTile({
  required WorldState world,
  required String provinceId,
  required int treasury,
  required Set<String> prospected,
  required Map<String, String> purchasedByTile,
}) {
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    if (Unit.provinceIdFromTileKey(tileKey) != provinceId) continue;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (purchasedByTile.containsKey(tileKey)) continue;
    if (kMineralResourceIds.contains(resourceId) &&
        !prospected.contains(tileKey)) {
      continue;
    }
    if (treasury < purchaseLandCost(resourceId)) continue;
    return true;
  }
  return false;
}
