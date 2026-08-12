/// Declare-war stalled / finalize bonus arms (Refs #4310 Slice B).
library;

import 'dart:math' as math;

import '../util/faction_query.dart';
import 'diplomatic_candidate_scoring_declare_war_bonuses.dart'
    show owConquestDeclareWarBonus, raiseToOwConquestDeclareWarFloorLocal;
import 'diplomatic_candidate_scoring_declare_war_bonuses_adjacency.dart'
    show declareWarAdjacentOwnerBonuses;
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'goal_manager.dart';
import 'planning_helpers.dart' show isAtWarWithAnyGreatPower;
import 'planning_imports.dart';

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
