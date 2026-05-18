part of 'diplomatic_candidate_scoring.dart';

int _scoreDeclareWarDiplomaticOrder({
  required DiplomaticOrder order,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String agendaId,
  required PersonalityThresholds thresholds,
  required int maxRelationForDeclareWar,
  required bool behindVictoryPace,
  required bool suppressGpDeclareWar,
  required Set<String> invadableOwners,
  required Map<String, String> provinceOwner,
  required int warCooldownTurns,
  required int currentTurn,
  required bool anyMinorOwnsOldWorld,
  required StrategicGoal? primaryGoal,
  required int Function(String targetFactionId, int relationScore)
  warDesireForTarget,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final ctx = _DeclareWarTargetContext.build(
    order: order,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
    thresholds: thresholds,
    maxRelationForDeclareWar: maxRelationForDeclareWar,
    behindVictoryPace: behindVictoryPace,
    suppressGpDeclareWar: suppressGpDeclareWar,
    invadableOwners: invadableOwners,
    provinceOwner: provinceOwner,
    warCooldownTurns: warCooldownTurns,
    currentTurn: currentTurn,
    anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
    primaryGoal: primaryGoal,
    warDesireForTarget: warDesireForTarget,
    agendaId: agendaId,
  );
  final suppressed = _declareWarSuppressedScore(
    ctx,
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
  );
  if (suppressed != null) {
    return suppressed;
  }
  return _scoreDeclareWarBonuses(ctx);
}

final class _DeclareWarTargetContext {
  _DeclareWarTargetContext._({
    required this.order,
    required this.nationId,
    required this.game,
    required this.snapshot,
    required this.agendaId,
    required this.thresholds,
    required this.maxRelationForDeclareWar,
    required this.behindVictoryPace,
    required this.suppressGpDeclareWar,
    required this.invadableOwners,
    required this.provinceOwner,
    required this.warCooldownTurns,
    required this.currentTurn,
    required this.anyMinorOwnsOldWorld,
    required this.primaryGoal,
    required this.warDesireForTarget,
    required this.relation,
    required this.relationScore,
    required this.adjacentOwners,
    required this.isAdjacentOwner,
    required this.isColonialAdjacentOwner,
    required this.isMinorTarget,
    required this.ownsInvadableNw,
    required this.colonialPressure,
    required this.isTribeTarget,
    required this.stalledOwExpansion,
    required this.ownsInvadableOwMinor,
    required this.weakerDistantMinor,
    required this.hasInvadableMinorOwner,
    required this.minorsHoldOldWorldProvinces,
    required this.atWarInvadableOwMinor,
    required this.activeMinorConflicts,
    required this.hasAdjacentInvadableMinorOwner,
    required this.isAdjacentGp,
    required this.invadableGpBlocker,
    required this.invadableGpBlockerWeaker,
    required this.invadableOwOwnedByGp,
    required this.tribeOwnsOwInvadable,
  });

  final DiplomaticOrder order;
  final String nationId;
  final Game game;
  final AIWorldSnapshot snapshot;
  final String agendaId;
  final PersonalityThresholds thresholds;
  final int maxRelationForDeclareWar;
  final bool behindVictoryPace;
  final bool suppressGpDeclareWar;
  final Set<String> invadableOwners;
  final Map<String, String> provinceOwner;
  final int warCooldownTurns;
  final int currentTurn;
  final bool anyMinorOwnsOldWorld;
  final StrategicGoal? primaryGoal;
  final int Function(String targetFactionId, int relationScore) warDesireForTarget;
  final DiplomacyRelation? relation;
  final int relationScore;
  final List<String> adjacentOwners;
  final bool isAdjacentOwner;
  final bool isColonialAdjacentOwner;
  final bool isMinorTarget;
  final bool ownsInvadableNw;
  final bool colonialPressure;
  final bool isTribeTarget;
  final bool stalledOwExpansion;
  final bool ownsInvadableOwMinor;
  final bool weakerDistantMinor;
  final bool hasInvadableMinorOwner;
  final bool minorsHoldOldWorldProvinces;
  final bool atWarInvadableOwMinor;
  final Set<String> activeMinorConflicts;
  final bool hasAdjacentInvadableMinorOwner;
  final bool isAdjacentGp;
  final bool invadableGpBlocker;
  final bool invadableGpBlockerWeaker;
  final bool invadableOwOwnedByGp;
  final bool tribeOwnsOwInvadable;

  factory _DeclareWarTargetContext.build({
    required DiplomaticOrder order,
    required String nationId,
    required Game game,
    required AIWorldSnapshot snapshot,
    required String agendaId,
    required PersonalityThresholds thresholds,
    required int maxRelationForDeclareWar,
    required bool behindVictoryPace,
    required bool suppressGpDeclareWar,
    required Set<String> invadableOwners,
    required Map<String, String> provinceOwner,
    required int warCooldownTurns,
    required int currentTurn,
    required bool anyMinorOwnsOldWorld,
    required StrategicGoal? primaryGoal,
    required int Function(String targetFactionId, int relationScore)
    warDesireForTarget,
  }) {
    final relation = snapshot.relations[order.targetFactionId];
    final relationScore = relation?.score ?? 50;
    final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
    final colonialAdjacent =
        snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
    final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
    final isColonialAdjacentOwner =
        colonialAdjacent.contains(order.targetFactionId);
    final isMinorTarget = _isMinorOrTribeFaction(game, order.targetFactionId);
    final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
        .any((pid) => provinceOwner[pid] == order.targetFactionId);
    final colonialPressure = hasColonialAcquisitionTargets(snapshot.colonial) &&
        !isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot) &&
        !isBelowObserverConquestQuota(
          snapshot.conquest.oldWorldProvincesOwned,
        );
    final isTribeTarget = _isTribeFaction(game, order.targetFactionId);
    final stalledOwExpansion = isObserverConquestExpansionPressure(
      snapshot.conquest.oldWorldProvincesOwned,
    );
    final ownsInvadableOwMinor = isMinorTarget &&
        !isTribeTarget &&
        invadableOwners.contains(order.targetFactionId);
    final minorProvinces = isMinorTarget && !isTribeTarget
        ? provinceCountOwnedBy(game, order.targetFactionId)
        : 0;
    final weakerDistantMinor = stalledOwExpansion &&
        behindVictoryPace &&
        isMinorTarget &&
        !isTribeTarget &&
        !isAdjacentOwner &&
        !invadableOwners.contains(order.targetFactionId) &&
        !isColonialAdjacentOwner &&
        !ownsInvadableNw &&
        minorProvinces > 0 &&
        minorProvinces < snapshot.conquest.oldWorldProvincesOwned;
    final hasInvadableMinorOwner = invadableOwners.any(
      (id) => game.minorNations.any((m) => m.id == id),
    );
    final minorsHoldOldWorldProvinces = game.minorNations.any(
      (m) => game.worldState.oldWorld.provinces.any((p) => p.ownerId == m.id),
    );
    final atWarInvadableOwMinor = snapshot.threats.atWarWith.any(
      (factionId) =>
          game.minorNations.any((m) => m.id == factionId) &&
          invadableOwners.contains(factionId),
    );
    final activeMinorConflicts = _activeOldWorldMinorConflictIds(
      game: game,
      nationId: nationId,
      currentTurn: currentTurn,
      warCooldownTurns: warCooldownTurns,
    );
    final hasAdjacentInvadableMinorOwner = adjacentOwners.any(
      (id) =>
          game.minorNations.any((m) => m.id == id) &&
          invadableOwners.contains(id),
    );
    final isAdjacentGp =
        isAdjacentOwner && game.playerById(order.targetFactionId) != null;
    final invadableGpBlocker = game.playerById(order.targetFactionId) != null &&
        snapshot.conquest.invadableProvinceIdsSorted.any(
          (pid) => provinceOwner[pid] == order.targetFactionId,
        );
    final invadableGpBlockerWeaker = invadableGpBlocker &&
        provinceCountOwnedBy(game, order.targetFactionId) <=
            snapshot.conquest.oldWorldProvincesOwned;
    final invadableOwOwnedByGp =
        snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => game.playerById(provinceOwner[pid] ?? '') != null,
    );
    final tribeOwnsOwInvadable = isTribeTarget &&
        snapshot.conquest.invadableProvinceIdsSorted.any(
          (pid) => provinceOwner[pid] == order.targetFactionId,
        );
    return _DeclareWarTargetContext._(
      order: order,
      nationId: nationId,
      game: game,
      snapshot: snapshot,
      agendaId: agendaId,
      thresholds: thresholds,
      maxRelationForDeclareWar: maxRelationForDeclareWar,
      behindVictoryPace: behindVictoryPace,
      suppressGpDeclareWar: suppressGpDeclareWar,
      invadableOwners: invadableOwners,
      provinceOwner: provinceOwner,
      warCooldownTurns: warCooldownTurns,
      currentTurn: currentTurn,
      anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
      primaryGoal: primaryGoal,
      warDesireForTarget: warDesireForTarget,
      relation: relation,
      relationScore: relationScore,
      adjacentOwners: adjacentOwners,
      isAdjacentOwner: isAdjacentOwner,
      isColonialAdjacentOwner: isColonialAdjacentOwner,
      isMinorTarget: isMinorTarget,
      ownsInvadableNw: ownsInvadableNw,
      colonialPressure: colonialPressure,
      isTribeTarget: isTribeTarget,
      stalledOwExpansion: stalledOwExpansion,
      ownsInvadableOwMinor: ownsInvadableOwMinor,
      weakerDistantMinor: weakerDistantMinor,
      hasInvadableMinorOwner: hasInvadableMinorOwner,
      minorsHoldOldWorldProvinces: minorsHoldOldWorldProvinces,
      atWarInvadableOwMinor: atWarInvadableOwMinor,
      activeMinorConflicts: activeMinorConflicts,
      hasAdjacentInvadableMinorOwner: hasAdjacentInvadableMinorOwner,
      isAdjacentGp: isAdjacentGp,
      invadableGpBlocker: invadableGpBlocker,
      invadableGpBlockerWeaker: invadableGpBlockerWeaker,
      invadableOwOwnedByGp: invadableOwOwnedByGp,
      tribeOwnsOwInvadable: tribeOwnsOwInvadable,
    );
  }
}

/// Returns a suppressed score when declare-war should not proceed; null = score.
int? _declareWarSuppressedScore(
  _DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  return _declareWarSuppressedStalledOwFrontierScore(ctx) ??
      _declareWarSuppressedAdjacentGpScore(
        ctx,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ) ??
      _declareWarSuppressedWarConcentrationScore(
        ctx,
        sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
      ) ??
      _declareWarSuppressedRelationAndCooldownScore(ctx);
}

int? _declareWarSuppressedStalledOwFrontierScore(_DeclareWarTargetContext ctx) {
  if (ctx.isTribeTarget &&
      ctx.stalledOwExpansion &&
      (ctx.minorsHoldOldWorldProvinces ||
          ctx.activeMinorConflicts.isNotEmpty ||
          ctx.invadableOwOwnedByGp)) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableOwOwnedByGp &&
      !ctx.hasInvadableMinorOwner &&
      (ctx.isTribeTarget ||
          (ctx.game.playerById(ctx.order.targetFactionId) != null &&
              !ctx.invadableGpBlocker) ||
          (ctx.isMinorTarget && !ctx.isTribeTarget && !ctx.weakerDistantMinor))) {
    return 0;
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final continuingMinorConflict =
        ctx.activeMinorConflicts.contains(ctx.order.targetFactionId);
    final adjacentInvadableMinor = ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId);
    final distantInvadableMinorOwner =
        ctx.invadableOwners.contains(ctx.order.targetFactionId);
    if (ctx.activeMinorConflicts.isNotEmpty) {
      if (!continuingMinorConflict) {
        return 0;
      }
    } else if (ctx.hasAdjacentInvadableMinorOwner) {
      if (!adjacentInvadableMinor) {
        return 0;
      }
    } else if (!adjacentInvadableMinor &&
        !ctx.weakerDistantMinor &&
        !distantInvadableMinorOwner &&
        !(ctx.behindVictoryPace &&
            ctx.anyMinorOwnsOldWorld &&
            _minorOwnsOldWorldProvinces(
              ctx.game,
              ctx.order.targetFactionId,
            ))) {
      return 0;
    }
  }
  if (ctx.behindVictoryPace &&
      ctx.adjacentOwners.isNotEmpty &&
      !ctx.isAdjacentOwner &&
      !ctx.isColonialAdjacentOwner &&
      !(ctx.ownsInvadableNw && ctx.isMinorTarget) &&
      !(ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) &&
      !ctx.weakerDistantMinor) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (ctx.stalledOwExpansion &&
      ctx.isAdjacentGp &&
      !ctx.invadableGpBlockerWeaker &&
      !ctx.invadableGpBlocker) {
    return 0;
  }
  return null;
}

int? _declareWarSuppressedAdjacentGpScore(
  _DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  if (ctx.order.type == DiplomaticOrderType.declareWar && ctx.isAdjacentGp) {
    final attackerOw = ctx.snapshot.conquest.oldWorldProvincesOwned;
    final targetOw = provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
    if (ctx.game.playerById(ctx.order.targetFactionId) != null) {
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
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
        return 0;
      }
      if (!ctx.invadableGpBlocker &&
          isBelowObserverConquestQuota(targetOw) &&
          regimentCountForPlayer(ctx.game, ctx.order.targetFactionId) == 0 &&
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          !ctx.invadableGpBlocker &&
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId) &&
          ((!isBelowObserverConquestQuota(attackerOw)) ||
              (ctx.currentTurn <= kDeclareWarEarlyAntiDogpileMaxTurn &&
                  attackerOw > targetOw))) {
        return 0;
      }
      final belowQuotaSuppressLead = targetOw <= kFewOldWorldProvincesDefendThreshold
          ? 1
          : kUnwinnableSoleGpMinProvinceDeficit;
      if (isBelowObserverConquestQuota(targetOw) &&
          !ctx.invadableGpBlocker &&
          attackerOw >= targetOw + belowQuotaSuppressLead) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          !isBelowObserverConquestQuota(attackerOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
        return 0;
      }
      if (isBelowObserverConquestQuota(attackerOw) &&
          targetOw >= attackerOw + kUnwinnableSoleGpMinProvinceDeficit) {
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
        !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
      return 0;
    }
  }
  if (ctx.order.type == DiplomaticOrderType.declareWar &&
      ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      isObserverConquestExpansionPressure(
        ctx.snapshot.conquest.oldWorldProvincesOwned,
      )) {
    final targetOw = provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
    if (!ctx.invadableGpBlocker &&
        targetOw <= kFewOldWorldProvincesDefendThreshold &&
        ctx.snapshot.conquest.oldWorldProvincesOwned >=
            targetOw + kDeclareWarAggressorSuppressWeakGpLeadThreshold) {
      return 0;
    }
  }
  return null;
}

int? _declareWarSuppressedWarConcentrationScore(
  _DeclareWarTargetContext ctx, {
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final atWarWithGp = ctx.snapshot.threats.atWarWith.any(
    (id) => ctx.game.playerById(id) != null,
  );
  if (ctx.stalledOwExpansion &&
      atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
    return 0;
  }
  if (ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
    final attackerGpWarCount = ctx.snapshot.threats.atWarWith
        .where((id) => ctx.game.playerById(id) != null)
        .length;
    if (attackerGpWarCount >= 2) {
      return 0;
    }
    final targetGpId = ctx.order.targetFactionId;
    final targetOw = provinceCountOwnedBy(ctx.game, targetGpId);
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
  }
  // While an invadable OW frontier has a GP blocker, do not open (or stack)
  // wars on other adjacent GPs — applies above the stalled OW band (seed-42 gp4).
  if (atWarWithGp &&
      ctx.isAdjacentGp &&
      ctx.game.playerById(ctx.order.targetFactionId) != null &&
      !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId) &&
      ctx.snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      ctx.invadableGpBlocker != null &&
      ctx.order.targetFactionId != ctx.invadableGpBlocker) {
    return 0;
  }
  if (ctx.stalledOwExpansion &&
      ctx.invadableGpBlocker &&
      provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId) >
          ctx.snapshot.conquest.oldWorldProvincesOwned &&
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
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}

int? _declareWarSuppressedRelationAndCooldownScore(
  _DeclareWarTargetContext ctx,
) {
  final effectiveMaxRelation = ctx.behindVictoryPace && ctx.isMinorTarget
      ? kDeclareWarMinorMaxRelationWhenFarFromVictory
      : ctx.behindVictoryPace && ctx.isAdjacentGp
      ? kDeclareWarGpMaxRelationWhenFarFromVictory
      : ctx.maxRelationForDeclareWar;
  if (ctx.relationScore > effectiveMaxRelation) {
    return 0;
  }
  if (_isDecisionOnCooldown(
    game: ctx.game,
    actorFactionId: ctx.nationId,
    targetFactionId: ctx.order.targetFactionId,
    eventTypes: const [DiplomaticEventType.declareWar],
    cooldownTurns: ctx.warCooldownTurns,
    currentTurn: ctx.currentTurn,
  )) {
    return 0;
  }
  return null;
}

int _scoreDeclareWarBonuses(_DeclareWarTargetContext ctx) {
  var s = _declareWarCoreBonuses(ctx);
  s = _declareWarExpansionAndColonialBonuses(ctx, s);
  s = _declareWarAdjacencyAndStalledBonuses(ctx, s);
  return _declareWarFinalizeBonuses(ctx, s);
}

int _declareWarCoreBonuses(_DeclareWarTargetContext ctx) {
  final warDesire =
      ctx.warDesireForTarget(ctx.order.targetFactionId, ctx.relationScore);
  final targetProvinceCount =
      provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
  final desiredTerritory = targetProvinceCount <= 0
      ? 1
      : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
  var s = 50;
  s += getAgendaConquerModifier(ctx.agendaId);
  s += getAgendaTreatyBreakingModifier(ctx.agendaId);
  s += (ctx.thresholds.warLikelihood - 50);
  s += (warDesire - 50);
  if (!ctx.suppressGpDeclareWar &&
      ctx.snapshot.opportunities.weakNeighbors
          .contains(ctx.order.targetFactionId)) {
    s += getDeclareWarTargetBonusWeakerNeighbor(ctx.agendaId);
    if (ctx.game.playerById(ctx.order.targetFactionId) != null &&
        warDesire >= kDeclareWarGpWeakNeighborMinWarDesire) {
      s += kDeclareWarGpWeakNeighborBonus;
    }
  }
  if (ctx.snapshot.conquest.preferredConquestTargetFactionIdsSorted
      .contains(ctx.order.targetFactionId)) {
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

int _declareWarAdjacencyAndStalledBonuses(
  _DeclareWarTargetContext ctx,
  int s,
) {
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
        !ctx.snapshot.threats.atWarWith.any(
          (id) => ctx.game.playerById(id) != null,
        )) {
      s += kDeclareWarPlateauOwMinorBonus;
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
      s -= kDeclareWarSatedExpansionMinorPenalty;
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
  if (!ctx.isAdjacentOwner && ctx.stalledOwExpansion && ctx.ownsInvadableOwMinor) {
    s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    s += kDeclareWarMinorWithInvadableProvinceBonus;
    s += kDeclareWarStalledExpansionMinorBonus;
    if (ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final targetMinorProvinces =
        provinceCountOwnedBy(ctx.game, ctx.order.targetFactionId);
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
  final adjacentWeakMinor = ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.snapshot.opportunities.weakNeighbors
          .contains(ctx.order.targetFactionId);
  if (ctx.stalledOwExpansion &&
      ctx.isMinorTarget &&
      !ctx.isTribeTarget &&
      ctx.isAdjacentOwner &&
      ctx.invadableOwners.contains(ctx.order.targetFactionId)) {
    final floor = ctx.snapshot.conquest.oldWorldProvincesOwned <=
            kFewOldWorldProvincesDefendThreshold
        ? kDeclareWarWeakGpAdjacentInvadableMinorFloor
        : kDeclareWarStalledAdjacentInvadableMinorFloor;
    s = math.max(s, floor);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      adjacentWeakMinor &&
      (ctx.invadableOwners.contains(ctx.order.targetFactionId) ||
          ctx.game.minorNations.any((m) => m.id == ctx.order.targetFactionId))) {
    s = math.max(s, kDeclareWarStalledAdjacentInvadableMinorFloor);
  }
  if (ctx.stalledOwExpansion && ctx.isTribeTarget && ctx.hasInvadableMinorOwner) {
    s = math.min(s, kDeclareWarStalledTribeWhenOwMinorCap);
  }
  if (ctx.stalledOwExpansion &&
      ctx.behindVictoryPace &&
      ctx.isTribeTarget &&
      ctx.thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold &&
      ctx.invadableOwners.any((id) => ctx.game.minorNations.any((m) => m.id == id))) {
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
