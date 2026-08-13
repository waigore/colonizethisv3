/// Colonial acquisition target-finder helpers (Refs #4079 Slice C).
library;

import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'colonial_phase_planner_acquisition.dart'
    show AcquisitionMethod, ColonialAcquisitionTarget;
import 'expand_phase_planner_economy.dart' show cheapestRegimentBuildTreasuryCost;
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'colonial_phase_planner_acquisition_gates.dart';

export 'colonial_phase_planner_acquisition_gates.dart';

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
