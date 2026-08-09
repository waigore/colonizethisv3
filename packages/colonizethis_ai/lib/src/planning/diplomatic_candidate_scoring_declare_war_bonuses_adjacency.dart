/// Declare-war adjacency / stalled / finalize bonus arms (Refs #4079 Slice C).
library;

import 'dart:math' as math;

import '../util/faction_query.dart';
import 'diplomatic_candidate_scoring_declare_war_bonuses.dart'
    show owConquestDeclareWarBonus, raiseToOwConquestDeclareWarFloorLocal;
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'expand_phase_planner.dart';
import 'goal_manager.dart';
import 'planning_helpers.dart'
    show
        gpFactionIdsAtWarWith,
        isAtWarWithAnyGreatPower,
        isOwnOldWorldBelowConquestQuota;
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
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarNearObserverQuotaMinorBonus,
      );
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

int declareWarAdjacencyAndStalledBonuses(DeclareWarTargetContext ctx, int s) {
  s = declareWarAdjacentOwnerBonuses(ctx, s);
  if (!ctx.isAdjacentOwner &&
      ctx.stalledOwExpansion &&
      ctx.ownsInvadableOwMinor) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarAdjacentMinorBonusWhenFarFromVictory,
    );
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarMinorWithInvadableProvinceBonus,
    );
    s += owConquestDeclareWarBonus(ctx, kDeclareWarStalledExpansionMinorBonus);
    if (ctx.lowWarLikelihood) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarLowWarLikelihoodAdjacentBonus,
      );
    }
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final targetMinorProvinces = ctx.targetProvinceCount;
    if (targetMinorProvinces > 0 &&
        targetMinorProvinces < ctx.snapshot.conquest.oldWorldProvincesOwned) {
      s += owConquestDeclareWarBonus(ctx, kDeclareWarStalledWeakerMinorBonus);
    }
    if (ctx.behindVictoryPace && targetMinorProvinces > 0) {
      s += owConquestDeclareWarBonus(
        ctx,
        kDeclareWarStalledActiveOwMinorBonus,
      );
    }
  }
  if (ctx.weakerDistantMinor && ctx.activeMinorConflicts.isEmpty) {
    s += owConquestDeclareWarBonus(ctx, kDeclareWarStalledWeakerMinorBonus);
    s += owConquestDeclareWarBonus(ctx, kDeclareWarStalledActiveOwMinorBonus);
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableOwOwnedByGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      !ctx.isAdjacentOwner &&
      !ctx.targetIsInvadableOwner) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarStalledGpBlockerDistantMinorBonus,
    );
  }
  if (ctx.snapshot.conquest.oldWorldProvincesOwned ==
          kObserverDefaultStartOldWorldProvincesPerGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.invadableOwOwnedByGp) {
    s += owConquestDeclareWarBonus(ctx, kDeclareWarDefaultStartOwMinorBonus);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableOwOwnedByGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      minorOwnsOldWorldProvinces(ctx.game, ctx.order.targetFactionId)) {
    s += owConquestDeclareWarBonus(ctx, kDeclareWarStalledAnyOwMinorBonus);
  }
  if (ctx.stalledOwExpansion && ctx.invadableGpBlockerWeaker) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarStalledWeakestInvadableGpBonus,
    );
    if (ctx.behindVictoryPace) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableGpBlockerWeaker) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarStalledInvadableGpBlockerBonus,
    );
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarStalledWeakestInvadableGpBonus,
    );
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableGpBlocker &&
      ctx.invadableOwOwnedByGp &&
      !ctx.hasInvadableMinorOwner) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarStalledInvadableGpBlockerBonus,
    );
    s = raiseToOwConquestDeclareWarFloorLocal(
      ctx,
      currentScore: s,
      floorBonus: kDeclareWarStalledGpInvadableBlockerFloor,
    );
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.hasInvadableMinorOwner &&
      !ctx.invadableGpBlocker) {
    s -= kDeclareWarStalledGpWhenMinorsRemainPenalty;
  }
  final targetOw = ctx.targetProvinceCount;
  if (ctx.isAdjacentGp &&
      targetOw > 0 &&
      targetOw < ctx.snapshot.conquest.oldWorldProvincesOwned &&
      isStalledOldWorldExpansion(targetOw)) {
    s -= kDeclareWarOnStalledWeakerNeighborPenalty;
  }
  final atWarWithGp = isAtWarWithAnyGreatPower(ctx.game, ctx.snapshot);
  if (!atWarWithGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    s += owConquestDeclareWarBonus(
      ctx,
      kDeclareWarCriticalWeakNoGpWarMinorBonus,
    );
    if (ctx.isAdjacentOwner && ctx.targetIsInvadableOwner) {
      s = raiseToOwConquestDeclareWarFloorLocal(
        ctx,
        currentScore: s,
        floorBonus: kDeclareWarWeakGpAdjacentInvadableMinorFloor,
      );
    }
  }
  return s;
}

int declareWarFinalizeBonuses(DeclareWarTargetContext ctx, int s) {
  if (ctx.primaryGoal == StrategicGoal.conquer) {
    s += 20;
  }
  s += ctx.behindVictoryPace
      ? conquerScoreBonusForProvincesToVictory(
          ctx.snapshot.conquest.provincesToVictory,
        )
      : conquerScoreBonusForProvincesToVictory(
              ctx.snapshot.conquest.provincesToVictory,
            ) ~/
            4;
  if (ctx.relation?.level == RelationLevel.allied) {
    s += getDeclareWarTargetBonusAlly(ctx.agendaId);
  }
  final adjacentWeakMinor =
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.snapshot.opportunities.weakNeighbors.contains(
        ctx.order.targetFactionId,
      );
  if (ctx.stalledOwExpansion && ctx.isAdjacentInvadableOwMinor) {
    final floor =
        ctx.snapshot.conquest.oldWorldProvincesOwned <=
            kFewOldWorldProvincesDefendThreshold
        ? kDeclareWarWeakGpAdjacentInvadableMinorFloor
        : kDeclareWarStalledAdjacentInvadableMinorFloor;
    s = raiseToOwConquestDeclareWarFloorLocal(
      ctx,
      currentScore: s,
      floorBonus: floor,
    );
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      adjacentWeakMinor &&
      (ctx.targetIsInvadableOwner ||
          isMinorFaction(ctx.game, ctx.order.targetFactionId))) {
    s = raiseToOwConquestDeclareWarFloorLocal(
      ctx,
      currentScore: s,
      floorBonus: kDeclareWarStalledAdjacentInvadableMinorFloor,
    );
  }
  if (ctx.stalledOwExpansion &&
      ctx.isTribeTarget &&
      ctx.hasInvadableMinorOwner) {
    s = math.min(s, kDeclareWarStalledTribeWhenOwMinorCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isTribeTarget &&
      ctx.lowWarLikelihood &&
      ctx.invadableOwners.any((id) => isMinorFaction(ctx.game, id))) {
    s = math.min(s, kDeclareWarStalledLowWarLikelihoodTribeCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isAdjacentInvadableOwMinor &&
      ctx.lowWarLikelihood) {
    s = raiseToOwConquestDeclareWarFloorLocal(
      ctx,
      currentScore: s,
      floorBonus: kDeclareWarStalledLowWarLikelihoodMinorFloor,
    );
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
