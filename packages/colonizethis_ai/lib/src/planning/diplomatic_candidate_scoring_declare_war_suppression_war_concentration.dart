import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart'
    show gpFactionIdsAtWarWith, isAtWarWithAnyGreatPower;
import 'planning_imports.dart';

/// War-concentration / GP-blocker declare-war suppression arm (Refs #4104 Slice B).
int? declareWarSuppressedWarConcentrationScore(
  DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarWithGp = isAtWarWithAnyGreatPower(ctx.game, ctx.snapshot);
  if (ctx.stalledOwExpansion &&
      atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.targetNotAlreadyAtWar) {
    return 0;
  }
  if (ctx.isAdjacentGp && ctx.targetIsGreatPower && ctx.targetNotAlreadyAtWar) {
    final attackerGpWarCount = gpFactionIdsAtWarWith(
      ctx.game,
      ctx.snapshot,
    ).length;
    if (attackerGpWarCount >= 2) {
      return 0;
    }
    final targetGpId = ctx.order.targetFactionId;
    final targetOw = ctx.targetProvinceCount;
    final targetGpWarCount = greatPowerWarCountOnTarget(
      game: ctx.game,
      targetGpId: targetGpId,
      sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
    );
    if (targetGpWarCount >= 2) {
      return 0;
    }
    final attackerOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    if (isBelowObserverConquestQuota(targetOw) && targetGpWarCount >= 1) {
      return 0;
    }
    if (isBelowObserverConquestQuota(targetOw) &&
        attackerOw >= targetOw + 2 &&
        !ctx.invadableGpBlocker) {
      return 0;
    }
  }
  // While an invadable OW frontier has a GP blocker, do not open (or stack)
  // wars on other adjacent GPs — applies above the stalled OW band (seed-42 gp4).
  final primaryGpBlocker = primaryInvadableOldWorldGpBlocker(
    game: ctx.game,
    snapshot: ctx.snapshot,
  );
  if (atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.targetNotAlreadyAtWar &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      primaryGpBlocker != null &&
      ctx.order.targetFactionId != primaryGpBlocker) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableGpBlocker &&
      ctx.targetProvinceCount > ctx.snapshot.conquest.oldWorldProvincesOwned &&
      ctx.hasInvadableMinorOwner) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.isTribeTarget &&
      !ctx.tribeOwnsOwInvadable &&
      !(ctx.colonialPressure && ctx.ownsInvadableNw) &&
      (ctx.behindVictoryPace ||
          ctx.hasInvadableMinorOwner ||
          ctx.atWarInvadableOwMinor)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      !ctx.invadableGpBlocker &&
      !(ctx.stalledOwExpansion && ctx.invadableGpBlockerWeaker)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.hasInvadableMinorOwner &&
      !ctx.invadableGpBlocker &&
      !ctx.invadableGpBlockerWeaker &&
      ctx.lowWarLikelihood) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}
