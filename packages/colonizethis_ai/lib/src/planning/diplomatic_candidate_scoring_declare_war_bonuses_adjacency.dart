/// Declare-war adjacency bonus arm (Refs #4079 Slice C).
library;

import 'diplomatic_candidate_scoring_declare_war_bonuses.dart'
    show owConquestDeclareWarBonus;
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'expand_phase_planner.dart';
import 'planning_helpers.dart'
    show gpFactionIdsAtWarWith, isOwnOldWorldBelowConquestQuota;
import 'planning_imports.dart';

int declareWarAdjacentOwnerBonuses(DeclareWarTargetContext ctx, int s) {
  if (ctx.isAdjacentOwner) {
    s += owConquestDeclareWarBonus(ctx, kDeclareWarAdjacentOwnerBonus);
    if (ctx.behindVictoryPace && ctx.isMinorTarget) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarAdjacentMinorBonusWhenFarFromVictory,
      );
    }
    if (ctx.isMinorTarget && ctx.targetIsInvadableOwner) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarMinorWithInvadableProvinceBonus,
      );
    }
    if (ctx.isAdjacentInvadableOwMinor &&
        isOwnOldWorldBelowConquestQuota(ctx.snapshot)) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarBelowObserverQuotaMinorBonus,
      );
    }
    final ownedOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    if (ctx.isAdjacentInvadableOwMinor &&
        isBelowObserverConquestQuota(ownedOw) &&
        !gpWarBlocksPlateauMinorDeclare(ctx)) {
      s += owConquestDeclareWarBonus(ctx, kDeclareWarPlateauOwMinorBonus);
    }
    if (ctx.isAdjacentInvadableOwMinor &&
        ownedOw >= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
        ownedOw < kObserverConquestMinOwProvincesPerGp &&
        !gpWarBlocksPlateauMinorDeclare(ctx)) {
      s += owConquestDeclareWarBonus(ctx, kDeclareWarNearObserverQuotaMinorBonus);
    }
    if (ctx.isMinorTarget && ctx.stalledOwExpansion) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarStalledExpansionMinorBonus,
      );
    }
    if (ctx.stalledOwExpansion &&
        ctx.isAdjacentInvadableOwMinor &&
        ctx.lowWarLikelihood) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarStalledLowWarLikelihoodMinorBonus,
      );
    }
    if (ctx.isMinorTarget &&
        !ctx.stalledOwExpansion &&
        !isOwnOldWorldBelowConquestQuota(ctx.snapshot) &&
        ctx.snapshot.conquest.oldWorldProvincesOwned >=
            kDeclareWarSatedExpansionMinorThreshold) {
      final ownedOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
      s -= ownedOw >= kObserverConquestMinOwProvincesPerGp + 2
          ? kDeclareWarSatedExpansionMinorPenalty * 3
          : kDeclareWarSatedExpansionMinorPenalty;
    }
    if (!ctx.suppressGpDeclareWar &&
        ctx.behindVictoryPace &&
        ctx.isAdjacentGp) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
    if (ctx.lowWarLikelihood) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  return s;
}

/// Plateau minor declare is blocked only by distracting multi-front GP wars.
bool gpWarBlocksPlateauMinorDeclare(DeclareWarTargetContext ctx) {
  final gpWars = gpFactionIdsAtWarWith(ctx.game, ctx.snapshot);
  if (gpWars.isEmpty) {
    return false;
  }
  if (unwinnableSoleGpFrontierPeaceTarget(
        game: ctx.game,
        snapshot: ctx.snapshot,
      ) !=
      null) {
    return false;
  }
  if (gpWars.length == 1 &&
      isStalledOldWorldGpBlockerFocus(game: ctx.game, snapshot: ctx.snapshot) &&
      gpWars.single ==
          primaryInvadableOldWorldGpBlocker(
            game: ctx.game,
            snapshot: ctx.snapshot,
          )) {
    return false;
  }
  return true;
}
