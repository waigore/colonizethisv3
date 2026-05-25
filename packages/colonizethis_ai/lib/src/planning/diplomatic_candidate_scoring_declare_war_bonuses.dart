part of 'diplomatic_candidate_scoring.dart';

int _scoreDeclareWarBonuses(_DeclareWarTargetContext ctx) {
  var s = _declareWarCoreBonuses(ctx);
  s = _declareWarExpansionAndColonialBonuses(ctx, s);
  s = _declareWarAdjacencyAndStalledBonuses(ctx, s);
  return _declareWarFinalizeBonuses(ctx, s);
}

int _declareWarCoreBonuses(_DeclareWarTargetContext ctx) {
  final warDesire = ctx.warDesireForTarget(
    ctx.order.targetFactionId,
    ctx.relationScore,
  );
  final targetProvinceCount = provinceCountOwnedBy(
    ctx.game,
    ctx.order.targetFactionId,
  );
  final desiredTerritory = targetProvinceCount <= 0
      ? 1
      : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
  var s = 50;
  s += getAgendaConquerModifier(ctx.agendaId);
  s += getAgendaTreatyBreakingModifier(ctx.agendaId);
  s += (ctx.thresholds.warLikelihood - 50);
  s += (warDesire - 50);
  if (!ctx.suppressGpDeclareWar &&
      ctx.snapshot.opportunities.weakNeighbors.contains(
        ctx.order.targetFactionId,
      )) {
    s += getDeclareWarTargetBonusWeakerNeighbor(ctx.agendaId);
    if (ctx.game.playerById(ctx.order.targetFactionId) != null &&
        warDesire >= kDeclareWarGpWeakNeighborMinWarDesire) {
      s += kDeclareWarGpWeakNeighborBonus;
    }
  }
  if (ctx.snapshot.conquest.preferredConquestTargetFactionIdsSorted.contains(
    ctx.order.targetFactionId,
  )) {
    s += 15;
  }
  _log.d(
    'diplomacy warDesire nationId=${ctx.nationId} '
    'targetFactionId=${ctx.order.targetFactionId} '
    'warDesire=$warDesire desiredTerritory=$desiredTerritory',
  );
  return s;
}

bool _isStalledOwMinorInvadableTarget(_DeclareWarTargetContext ctx) =>
    ctx.isMinorTarget &&
    !ctx.isTribeTarget &&
    ctx.isAdjacentOwner &&
    ctx.invadableOwners.contains(ctx.order.targetFactionId);

int _stalledOwMinorRecoveryBonus(_DeclareWarTargetContext ctx) {
  final owned = ctx.snapshot.conquest.oldWorldProvincesOwned;
  if (owned <= kFewOldWorldProvincesDefendThreshold) {
    return kDeclareWarWeakGpOwMinorRecoveryBonus;
  }
  if (isBelowObserverConquestQuota(owned)) {
    return kDeclareWarBelowQuotaOwMinorRecoveryBonus;
  }
  return 0;
}

int _declareWarColonialNwTribeBonuses(_DeclareWarTargetContext ctx, int s) {
  if (!ctx.colonialPressure || !ctx.ownsInvadableNw || !ctx.isTribeTarget) {
    return s;
  }
  s += kDeclareWarColonialNwTribeDominanceBonus;
  if (ctx.stalledOwExpansion &&
      !ctx.hasInvadableMinorOwner &&
      !ctx.atWarInvadableOwMinor) {
    s += kDeclareWarColonialNwTribePriorityOverOwMinorBonus;
  }
  return s;
}

int _declareWarStalledOldWorldExpansionBonuses(
  _DeclareWarTargetContext ctx,
  int s,
) {
  final observerExpansionPressure = isObserverConquestExpansionPressure(
    ctx.snapshot.conquest.oldWorldProvincesOwned,
  );
  final hasInvadableOldWorld =
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (!observerExpansionPressure || !hasInvadableOldWorld) {
    return s;
  }
  if (_isStalledOwMinorInvadableTarget(ctx)) {
    s += kDeclareWarStalledOwMinorPriorityBonus;
    s += _stalledOwMinorRecoveryBonus(ctx);
    if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (ctx.isTribeTarget && !ctx.ownsInvadableNw) {
    s -= kDeclareWarStalledExpansionTribePenalty;
  }
  return s;
}

int _declareWarEarlyExpansionBonuses(_DeclareWarTargetContext ctx, int s) {
  final observerExpansionPressure = isObserverConquestExpansionPressure(
    ctx.snapshot.conquest.oldWorldProvincesOwned,
  );
  final hasInvadableOldWorld =
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (ctx.currentTurn > kDeclareWarEarlyExpansionMaxTurn ||
      !ctx.anyMinorOwnsOldWorld ||
      !observerExpansionPressure ||
      !hasInvadableOldWorld) {
    return s;
  }
  if (_isStalledOwMinorInvadableTarget(ctx)) {
    s += kDeclareWarEarlyExpansionMinorBonus;
  }
  if (ctx.isTribeTarget && !ctx.ownsInvadableNw) {
    s -= kDeclareWarEarlyExpansionTribePenalty;
  }
  return s;
}

int _declareWarColonialPressureOwMinorPenalty(
  _DeclareWarTargetContext ctx,
  int s,
) {
  if (!ctx.colonialPressure ||
      !ctx.isMinorTarget ||
      ctx.isTribeTarget ||
      ctx.ownsInvadableNw) {
    return s;
  }
  s -= kDeclareWarColonialPressureOwMinorPenalty;
  if (ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) {
    s -= kDeclareWarColonialPressureOwMinorPenalty;
  }
  return s;
}

int _declareWarExpansionAndColonialBonuses(
  _DeclareWarTargetContext ctx,
  int s,
) {
  if (ctx.ownsInvadableNw && ctx.isMinorTarget && !ctx.stalledOwExpansion) {
    s += kDeclareWarColonialInvadableOwnerBonus;
  }
  s = _declareWarColonialNwTribeBonuses(ctx, s);
  s = _declareWarStalledOldWorldExpansionBonuses(ctx, s);
  s = _declareWarEarlyExpansionBonuses(ctx, s);
  s = _declareWarColonialPressureOwMinorPenalty(ctx, s);
  if (ctx.isColonialAdjacentOwner && ctx.isTribeTarget) {
    s += kDeclareWarColonialAdjacentTribeBonus;
  }
  return s;
}

int _declareWarAdjacencyAndStalledBonuses(_DeclareWarTargetContext ctx, int s) {
  if (ctx.isAdjacentOwner) {
    s += kDeclareWarAdjacentOwnerBonus;
    if (ctx.behindVictoryPace && ctx.isMinorTarget) {
      s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    }
    if (ctx.isMinorTarget &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
      s += kDeclareWarMinorWithInvadableProvinceBonus;
    }
    if (ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
        isBelowObserverConquestQuota(
          ctx.snapshot.conquest.oldWorldProvincesOwned,
        )) {
      s += kDeclareWarBelowObserverQuotaMinorBonus;
    }
    final ownedOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    if (ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
        isBelowObserverConquestQuota(ownedOw) &&
        !_gpWarBlocksPlateauMinorDeclare(ctx)) {
      s += kDeclareWarPlateauOwMinorBonus;
    }
    if (ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
        ownedOw >= kObserverDefaultStartOldWorldProvincesPerGp + 1 &&
        ownedOw < kObserverConquestMinOwProvincesPerGp &&
        !_gpWarBlocksPlateauMinorDeclare(ctx)) {
      s += kDeclareWarNearObserverQuotaMinorBonus;
    }
    if (ctx.isMinorTarget && ctx.stalledOwExpansion) {
      s += kDeclareWarStalledExpansionMinorBonus;
    }
    if (ctx.stalledOwExpansion &&
        ctx.isMinorTarget &&
        !ctx.isTribeTarget &&
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
        ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarStalledLowWarLikelihoodMinorBonus;
    }
    if (ctx.isMinorTarget &&
        !ctx.stalledOwExpansion &&
        !isBelowObserverConquestQuota(
          ctx.snapshot.conquest.oldWorldProvincesOwned,
        ) &&
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
    if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (!ctx.isAdjacentOwner &&
      ctx.stalledOwExpansion &&
      ctx.ownsInvadableOwMinor) {
    s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    s += kDeclareWarMinorWithInvadableProvinceBonus;
    s += kDeclareWarStalledExpansionMinorBonus;
    if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final targetMinorProvinces = provinceCountOwnedBy(
      ctx.game,
      ctx.order.targetFactionId,
    );
    if (targetMinorProvinces > 0 &&
        targetMinorProvinces < ctx.snapshot.conquest.oldWorldProvincesOwned) {
      s += kDeclareWarStalledWeakerMinorBonus;
    }
    if (ctx.behindVictoryPace && targetMinorProvinces > 0) {
      s += kDeclareWarStalledActiveOwMinorBonus;
    }
  }
  if (ctx.weakerDistantMinor && ctx.activeMinorConflicts.isEmpty) {
    s += kDeclareWarStalledWeakerMinorBonus;
    s += kDeclareWarStalledActiveOwMinorBonus;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableOwOwnedByGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      !ctx.isAdjacentOwner &&
      !ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
    s += kDeclareWarStalledGpBlockerDistantMinorBonus;
  }
  if (ctx.snapshot.conquest.oldWorldProvincesOwned ==
          kObserverDefaultStartOldWorldProvincesPerGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.invadableOwOwnedByGp) {
    s += kDeclareWarDefaultStartOwMinorBonus;
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableOwOwnedByGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      _minorOwnsOldWorldProvinces(ctx.game, ctx.order.targetFactionId)) {
    s += kDeclareWarStalledAnyOwMinorBonus;
  }
  if (ctx.stalledOwExpansion && ctx.invadableGpBlockerWeaker) {
    s += kDeclareWarStalledWeakestInvadableGpBonus;
    if (ctx.behindVictoryPace) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableGpBlockerWeaker) {
    s += kDeclareWarStalledInvadableGpBlockerBonus;
    s += kDeclareWarStalledWeakestInvadableGpBonus;
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.invadableGpBlocker &&
      ctx.invadableOwOwnedByGp &&
      !ctx.hasInvadableMinorOwner) {
    s += kDeclareWarStalledInvadableGpBlockerBonus;
    s = math.max(s, kDeclareWarStalledGpInvadableBlockerFloor);
  }
  if (ctx.suppressGpDeclareWar &&
      ctx.isAdjacentGp &&
      ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.hasInvadableMinorOwner &&
      !ctx.invadableGpBlocker) {
    s -= kDeclareWarStalledGpWhenMinorsRemainPenalty;
  }
  final targetOw = provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
  if (ctx.isAdjacentGp &&
      targetOw > 0 &&
      targetOw < ctx.snapshot.conquest.oldWorldProvincesOwned &&
      isStalledOldWorldExpansion(targetOw)) {
    s -= kDeclareWarOnStalledWeakerNeighborPenalty;
  }
  final atWarWithGp = ctx.snapshot.threats.atWarWith.any(
    (id) => ctx.game.playerById(id) != null,
  );
  if (!atWarWithGp &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty) {
    s += kDeclareWarCriticalWeakNoGpWarMinorBonus;
    if (ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
      s = math.max(s, kDeclareWarWeakGpAdjacentInvadableMinorFloor);
    }
  }
  return s;
}

int _declareWarFinalizeBonuses(_DeclareWarTargetContext ctx, int s) {
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
  if (ctx.stalledOwExpansion &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
    final floor =
        ctx.snapshot.conquest.oldWorldProvincesOwned <=
            kFewOldWorldProvincesDefendThreshold
        ? kDeclareWarWeakGpAdjacentInvadableMinorFloor
        : kDeclareWarStalledAdjacentInvadableMinorFloor;
    s = math.max(s, floor);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      adjacentWeakMinor &&
      (ctx.invadableOwners.contains(ctx.order.targetFactionId) ||
          ctx.game.minorNations.any(
            (m) => m.id == ctx.order.targetFactionId,
          ))) {
    s = math.max(s, kDeclareWarStalledAdjacentInvadableMinorFloor);
  }
  if (ctx.stalledOwExpansion &&
      ctx.isTribeTarget &&
      ctx.hasInvadableMinorOwner) {
    s = math.min(s, kDeclareWarStalledTribeWhenOwMinorCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isTribeTarget &&
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold &&
      ctx.invadableOwners.any(
        (id) => ctx.game.minorNations.any((m) => m.id == id),
      )) {
    s = math.min(s, kDeclareWarStalledLowWarLikelihoodTribeCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
    s = math.max(s, kDeclareWarStalledLowWarLikelihoodMinorFloor);
  }
  return s;
}

/// Plateau minor declare is blocked only by distracting multi-front GP wars.
bool _gpWarBlocksPlateauMinorDeclare(_DeclareWarTargetContext ctx) {
  final gpWars = ctx.snapshot.threats.atWarWith
      .where((id) => ctx.game.playerById(id) != null)
      .toList();
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
