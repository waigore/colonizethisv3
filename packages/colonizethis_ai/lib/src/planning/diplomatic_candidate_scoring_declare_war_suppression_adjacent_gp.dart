import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart' show anyInvadableProvinceOwnedByMinor;
import 'planning_imports.dart';

/// Adjacent-GP declare-war suppression arm (Refs #4104 Slice B).
int? declareWarSuppressedAdjacentGpScore(
  DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  if (ctx.order.type == DiplomaticOrderType.declareWar && ctx.isAdjacentGp) {
    final attackerOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    final targetOw = ctx.targetProvinceCount;
    if (ctx.targetIsGreatPower) {
      if (regimentCountForPlayer(ctx.game, ctx.nationId) == 0 &&
          isBelowObserverConquestQuota(attackerOw)) {
        return 0;
      }
      if (ctx.targetNotAlreadyAtWar &&
          isMutualBelowQuotaPlateauPeer(
            ownOw: attackerOw,
            partnerOw: targetOw,
          ) &&
          targetOw <= attackerOw + 1) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          isBelowObserverConquestQuota(attackerOw) &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar &&
          attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp &&
          targetOw <= attackerOw) {
        return 0;
      }
      final minorsOwnInvadable = anyInvadableProvinceOwnedByMinor(
        game: ctx.game,
        snapshot: ctx.snapshot,
        provinceOwner: ctx.provinceOwner,
      );
      if (minorsOwnInvadable &&
          isBelowObserverConquestQuota(attackerOw) &&
          isBelowObserverConquestQuota(targetOw) &&
          (targetOw - attackerOw).abs() <= 2 &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp &&
          isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
          !ctx.invadableGpBlocker) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          pendingDeclareWarFrom(
            sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
            declarerFactionId: ctx.order.targetFactionId,
            targetFactionId: ctx.nationId,
          )) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kFewOldWorldProvincesDefendThreshold &&
          !isBelowObserverConquestQuota(attackerOw) &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (!ctx.invadableGpBlocker &&
          isBelowObserverConquestQuota(targetOw) &&
          regimentCountForPlayer(ctx.game, ctx.order.targetFactionId) == 0 &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar &&
          ((!isBelowObserverConquestQuota(attackerOw)) ||
              (ctx.currentTurn <= kDeclareWarEarlyAntiDogpileMaxTurn &&
                  attackerOw > targetOw))) {
        return 0;
      }
      final belowQuotaSuppressLead =
          targetOw <= kFewOldWorldProvincesDefendThreshold
          ? 1
          : kUnwinnableSoleGpMinProvinceDeficit;
      if (isBelowObserverConquestQuota(targetOw) &&
          !ctx.invadableGpBlocker &&
          attackerOw >= targetOw + belowQuotaSuppressLead) {
        return 0;
      }
      if (targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw > targetOw &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
          !ctx.invadableGpBlocker) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          !isBelowObserverConquestQuota(attackerOw) &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw > targetOw &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (!isBelowObserverConquestQuota(attackerOw) &&
          isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kStalledOldWorldProvinceThreshold &&
          !ctx.invadableGpBlocker &&
          ctx.targetNotAlreadyAtWar) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          targetOw >= attackerOw + kUnwinnableSoleGpMinProvinceDeficit) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          attackerOw <= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
          ctx.isAdjacentGp &&
          !ctx.invadableGpBlocker &&
          ctx.targetIsInvadableOwner &&
          targetOw > attackerOw) {
        return 0;
      }
    }
    if (!ctx.invadableGpBlocker &&
        attackerOw <= kFewOldWorldProvincesDefendThreshold &&
        targetOw > attackerOw) {
      return 0;
    }
    if (!ctx.invadableGpBlocker &&
        attackerOw <= kFewOldWorldProvincesDefendThreshold &&
        ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
        ctx.targetNotAlreadyAtWar) {
      return 0;
    }
  }
  if (ctx.order.type == DiplomaticOrderType.declareWar &&
      ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.stalledOwExpansion) {
    final targetOw = ctx.targetProvinceCount;
    if (!ctx.invadableGpBlocker &&
        targetOw <= kFewOldWorldProvincesDefendThreshold &&
        ctx.snapshot.conquest.oldWorldProvincesOwned >=
            targetOw + kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
      return 0;
    }
  }
  return null;
}
