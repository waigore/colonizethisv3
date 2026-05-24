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
  PhasePlanOutcome? phasePlan,
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
    phasePlan: phasePlan,
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
  final int Function(String targetFactionId, int relationScore)
  warDesireForTarget;
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
    PhasePlanOutcome? phasePlan,
  }) {
    final relation = snapshot.relations[order.targetFactionId];
    final relationScore = relation?.score ?? 50;
    final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
    final colonialAdjacent =
        snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
    final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
    final isColonialAdjacentOwner = colonialAdjacent.contains(
      order.targetFactionId,
    );
    final isMinorTarget = _isMinorOrTribeFaction(game, order.targetFactionId);
    final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
        .any((pid) => provinceOwner[pid] == order.targetFactionId);
    // Refs #2509 S5: derive colonial-pressure from the dispatched phase
    // plan when available — `resolvePhaseDiplomacyDeclareWarColonialPressureActive`
    // returns `true` only under `ObserverGoalPhase.colonial`, mirroring the
    // economy and conquest resolvers. Falls back to the legacy three-predicate
    // compute when no phase plan was threaded through (test paths and other
    // callers; the orchestrator always passes `phasePlan` so production runs
    // route through the phase-derived value). The legacy path retires
    // structurally in S1 once every consumer migrates.
    final colonialPressure = phasePlan != null
        ? resolvePhaseDiplomacyDeclareWarColonialPressureActive(
            phasePlan: phasePlan,
          )
        : hasColonialAcquisitionTargets(snapshot.colonial) &&
              !isStalledOldWorldGpBlockerFocus(
                game: game,
                snapshot: snapshot,
              ) &&
              !shouldSuppressNewWorldColonialOrders(
                snapshot: snapshot,
                game: game,
              );
    final isTribeTarget = _isTribeFaction(game, order.targetFactionId);
    final stalledOwExpansion = isObserverConquestExpansionPressure(
      snapshot.conquest.oldWorldProvincesOwned,
    );
    final ownsInvadableOwMinor =
        isMinorTarget &&
        !isTribeTarget &&
        invadableOwners.contains(order.targetFactionId);
    final minorProvinces = isMinorTarget && !isTribeTarget
        ? provinceCountOwnedBy(game, order.targetFactionId)
        : 0;
    final weakerDistantMinor =
        stalledOwExpansion &&
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
    final invadableGpBlocker =
        game.playerById(order.targetFactionId) != null &&
        snapshot.conquest.invadableProvinceIdsSorted.any(
          (pid) => provinceOwner[pid] == order.targetFactionId,
        );
    final invadableGpBlockerWeaker =
        invadableGpBlocker &&
        provinceCountOwnedBy(game, order.targetFactionId) <=
            snapshot.conquest.oldWorldProvincesOwned;
    final invadableOwOwnedByGp = snapshot.conquest.invadableProvinceIdsSorted
        .any((pid) => game.playerById(provinceOwner[pid] ?? '') != null);
    final tribeOwnsOwInvadable =
        isTribeTarget &&
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
  return _declareWarSuppressedDevelopPhaseScore(ctx) ??
      _declareWarSuppressedColonialLiteScore(ctx) ??
      _declareWarSuppressedExpandColonialScore(ctx) ??
      _declareWarSuppressedStalledOwFrontierScore(ctx) ??
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

int? _declareWarSuppressedDevelopPhaseScore(_DeclareWarTargetContext ctx) {
  if (!isObserverDevelopPhase(snapshot: ctx.snapshot, game: ctx.game)) {
    return null;
  }
  return kDeclareWarNonAdjacentSuppressedScore;
}

int? _declareWarSuppressedExpandColonialScore(_DeclareWarTargetContext ctx) {
  if (!shouldSuppressNewWorldColonialOrders(
    snapshot: ctx.snapshot,
    game: ctx.game,
  )) {
    return null;
  }
  if (ctx.isTribeTarget || ctx.ownsInvadableNw || ctx.isColonialAdjacentOwner) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}

// COLONIAL-lite NW `declareWar` suppression (Refs #2509 S10).
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI),
// COLONIAL-lite: "suppresses NW declareWar, invasion army moves, and
// purchase_land only". `shouldSuppressNewWorldDeclareWarInvasionAndPurchase`
// already returns true for COLONIAL-lite, and `conquest_planner.dart` uses
// it to gate army moves and `purchase_land`. The diplomatic declare-war
// scoring path previously only consulted `shouldSuppressNewWorldColonialOrders`
// (EXPAND-only) and so left NW `declareWar` reachable in COLONIAL-lite,
// allowing near-quota GPs at turn >= `kObserverColonialLiteMinTurn` to
// burn turns declaring on NW tribes before reaching the OW quota and
// regressing the canonical seed-42 `--verify-conquest` per-GP +3 OW gain
// gate at turn 100.
//
// The function mirrors `_declareWarSuppressedExpandColonialScore`: suppress
// only NW colonial targets (tribe, NW owner, colonial-adjacent owner) — not
// every declare-war candidate — so the COLONIAL-lite allow list
// ("establishOverture, colonial naval/cargo") is unaffected and the rule
// stays distinct from the broader DEVELOP suppression
// (`_declareWarSuppressedDevelopPhaseScore`).
int? _declareWarSuppressedColonialLiteScore(_DeclareWarTargetContext ctx) {
  if (observerGoalPhaseFor(snapshot: ctx.snapshot, game: ctx.game) !=
      ObserverGoalPhase.colonialLite) {
    return null;
  }
  if (ctx.isTribeTarget || ctx.ownsInvadableNw || ctx.isColonialAdjacentOwner) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
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
          (ctx.isMinorTarget &&
              !ctx.isTribeTarget &&
              !ctx.weakerDistantMinor))) {
    return 0;
  }
  if (ctx.stalledOwExpansion && ctx.isMinorTarget && !ctx.isTribeTarget) {
    final continuingMinorConflict = ctx.activeMinorConflicts.contains(
      ctx.order.targetFactionId,
    );
    final adjacentInvadableMinor =
        ctx.isAdjacentOwner &&
        ctx.invadableOwners.contains(ctx.order.targetFactionId);
    final distantInvadableMinorOwner = ctx.invadableOwners.contains(
      ctx.order.targetFactionId,
    );
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
            _minorOwnsOldWorldProvinces(ctx.game, ctx.order.targetFactionId))) {
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
      if (regimentCountForPlayer(ctx.game, ctx.nationId) == 0 &&
          isBelowObserverConquestQuota(attackerOw)) {
        return 0;
      }
      if (!ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId) &&
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
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId) &&
          attackerOw >= kObserverDefaultStartOldWorldProvincesPerGp &&
          targetOw <= attackerOw) {
        return 0;
      }
      final minorsOwnInvadable = ctx
          .snapshot
          .conquest
          .invadableProvinceIdsSorted
          .any((pid) {
            final owner = ctx.provinceOwner[pid];
            return owner != null &&
                ctx.game.minorNations.any((m) => m.id == owner);
          });
      if (minorsOwnInvadable &&
          isBelowObserverConquestQuota(attackerOw) &&
          isBelowObserverConquestQuota(targetOw) &&
          (targetOw - attackerOw).abs() <= 2 &&
          !ctx.invadableGpBlocker &&
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
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
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
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
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
        return 0;
      }
      if (isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kObserverDefaultStartOldWorldProvincesPerGp &&
          attackerOw > targetOw &&
          !ctx.invadableGpBlocker &&
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
        return 0;
      }
      if (!isBelowObserverConquestQuota(attackerOw) &&
          isBelowObserverConquestQuota(targetOw) &&
          targetOw <= kStalledOldWorldProvinceThreshold &&
          !ctx.invadableGpBlocker &&
          !ctx.snapshot.threats.atWarWith.contains(ctx.order.targetFactionId)) {
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
          ctx.invadableOwners.contains(ctx.order.targetFactionId) &&
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
    if (isBelowObserverConquestQuota(targetOw) &&
        attackerOw >= targetOw + 2 &&
        !ctx.invadableGpBlocker) {
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
