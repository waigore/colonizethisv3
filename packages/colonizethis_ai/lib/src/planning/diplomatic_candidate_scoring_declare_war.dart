part of 'diplomatic_candidate_scoring.dart';

/// Declare-war score ladder.
///
/// Entry point [_scoreDeclareWarDiplomaticOrder] builds the per-target
/// [_DeclareWarTargetContext] (see
/// `diplomatic_candidate_scoring_declare_war_context.dart`), then walks the
/// suppression chain ([_declareWarSuppressedScore]) before delegating the
/// surviving candidates to the bonus addends
/// (`diplomatic_candidate_scoring_declare_war_bonuses.dart`). Split from the
/// context builder for readability (Refs #3749); behaviour is unchanged.
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
  required int Function(String targetFactionId, num relationScore)
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
  // Refs #2509 S5: derive DEVELOP suppression from the dispatched phase
  // plan instead of recomputing `observerGoalPhaseFor` per declare-war
  // candidate via `isObserverDevelopPhase`. The phase dispatcher already
  // resolved `observerGoalPhaseFor` once per player turn; this branch
  // mirrors `resolvePhaseDiplomacyDeclareWarColonialPressureActive`,
  // `resolvePhaseEconomyColonialPressureActive`, and
  // `resolvePhaseConquestColonialPressureActive` by routing the phase
  // check off the dispatched `PhasePlanOutcome`. Falls back to the
  // legacy compute when no phase plan was threaded through (test paths
  // and other callers); the orchestrator always passes `phasePlan` so
  // production runs route through the phase-derived value.
  final develop = ctx.phasePlan != null
      ? resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive(
          phasePlan: ctx.phasePlan!,
        )
      : isObserverDevelopPhase(snapshot: ctx.snapshot, game: ctx.game);
  if (!develop) {
    return null;
  }
  return kDeclareWarNonAdjacentSuppressedScore;
}

/// Shared NW-colonial declare-war suppression skeleton (Refs #3717
/// diplomatic-scoring dedup).
///
/// Single source of truth for the soft-phase NW-weight predicate that both
/// `_declareWarSuppressedExpandColonialScore` and
/// `_declareWarSuppressedColonialLiteScore` express identically: when the
/// soft-phase NW acquisition weight has not collapsed
/// (`nwAcquisitionWeight > 0.0`) NW colonial targets stay scorable (`null`);
/// otherwise the NW colonial candidates (tribe, NW owner, colonial-adjacent
/// owner) collapse to [kDeclareWarNonAdjacentSuppressedScore], while non-NW
/// targets remain scorable. Both call sites previously inlined this exact
/// three-line body, so routing them through one helper is pure delegation and
/// byte-identical to the inline checks it replaces. The two distinct chain
/// entries are retained at their call sites (see each delegating function) so
/// the suppression ordering in `_declareWarSuppressedScore` and the
/// independent Phase 4 retirement paths for the EXPAND / COLONIAL-lite Phase 2
/// resolvers are unchanged.
int? _declareWarSuppressedNwColonialScore(_DeclareWarTargetContext ctx) {
  if (ctx.nwAcquisitionWeight > 0.0) {
    return null;
  }
  if (ctx.isTribeTarget || ctx.ownsInvadableNw || ctx.isColonialAdjacentOwner) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  return null;
}

int? _declareWarSuppressedExpandColonialScore(_DeclareWarTargetContext ctx) {
  // Refs #2847 Phase 3 diplomacy wiring: derive EXPAND NW-colonial
  // suppression from the soft-phase NW acquisition weight on the
  // dispatched phase plan instead of the boolean
  // `resolvePhaseDiplomacyDeclareWarExpandColonialSuppressionActive`
  // (`phase == ObserverGoalPhase.expand`). The legacy hard-suppress
  // contract is preserved exactly at `nwAcquisitionWeight <= 0.0`
  // (mirroring `runConquestArmyMovePlanner`'s NW invadable-bonus zeroing
  // gate); the default soft-phase curve produces a `0.05` early-sprint
  // floor at OW<=7, so EXPAND turns now keep NW declare-war candidates
  // scorable at low priority rather than structurally collapsing them.
  // Callers without a phase plan use the legacy-derived weight (1.0 /
  // 0.0) from `_DeclareWarTargetContext.build`, preserving the
  // pre-soft-phase behaviour for tests and other entry points. The
  // soft-phase NW-weight predicate body is shared with the COLONIAL-lite
  // branch via `_declareWarSuppressedNwColonialScore` (Refs #3717).
  return _declareWarSuppressedNwColonialScore(ctx);
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
  // Refs #2847 Phase 3 diplomacy wiring: collapsed to the same soft-phase
  // NW-weight predicate as `_declareWarSuppressedExpandColonialScore`.
  // Under the soft-phase curve both EXPAND and COLONIAL-lite share the
  // same low-NW-priority profile (early-sprint plateau at OW<=9), so the
  // suppression contract is "NW colonial declare-war collapses iff
  // `nwAcquisitionWeight <= 0.0`" — which is reached only when an
  // explicit phase-plan override sets the weight to `0.0` (no override
  // does so today; default curves never produce `0.0`).
  //
  // The branch remains in the suppression chain (rather than being
  // inlined into the EXPAND branch) so the structural ordering matches
  // `_declareWarSuppressedScore` and so future Phase 4 SPEC alignment
  // can retire the EXPAND / COLONIAL-lite Phase 2 boolean resolvers
  // independently of this scoring path. Callers without a phase plan
  // use the legacy-derived weight (1.0 / 0.0) from
  // `_DeclareWarTargetContext.build`. The soft-phase NW-weight predicate
  // body is shared with the EXPAND branch via
  // `_declareWarSuppressedNwColonialScore` (Refs #3717).
  return _declareWarSuppressedNwColonialScore(ctx);
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
          (ctx.targetIsGreatPower &&
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
        ctx.isAdjacentOwner && ctx.targetIsInvadableOwner;
    final distantInvadableMinorOwner = ctx.targetIsInvadableOwner;
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

int? _declareWarSuppressedWarConcentrationScore(
  _DeclareWarTargetContext ctx, {
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
  if (ctx.isAdjacentGp &&
      ctx.targetIsGreatPower &&
      ctx.targetNotAlreadyAtWar) {
    final attackerGpWarCount =
        gpFactionIdsAtWarWith(ctx.game, ctx.snapshot).length;
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
