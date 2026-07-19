import 'conquest_move_scoring_context.dart';
import 'conquest_planner_destination_scoring.dart';
import 'goal_manager.dart';
import 'planning_imports.dart';
import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planner_context.dart';
import 'planning_helpers.dart'
    show
        colonialPressureScaleFromWeight,
        factionOwnsInvadableOldWorldProvince,
        isAtWarWithAnyGreatPower,
        minorAtWarPeaceTargetsWhere;
import '../util/ai_random_utils.dart';
import 'conquest_planner_stalled_fallback.dart';

export 'conquest_planner_destination_scoring.dart'
    show conquestOldWorldArmyMoveScaledBonus, conquestNwInvadableArmyMoveBonus;

final _log = packageLogger();

/// When Old World expansion is stalled, prefer marching against an at-war minor
/// that still owns invadable provinces over this turn's declare-war target (e.g.
/// a tribe picked while OW minors remain unconquered). Refs #2509.
String? stalledConquestDeclaredWarTarget({
  required Game game,
  required String nationId,
  required AIWorldSnapshot snapshot,
  required String? declaredThisTurn,
}) {
  var activeMinor = belowQuotaActiveMinorWarTarget(
    game: game,
    snapshot: snapshot,
  );
  if (activeMinor == null &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    final atWarMinors = minorAtWarPeaceTargetsWhere(
      game: game,
      snapshot: snapshot,
    );
    if (atWarMinors.length == 1 &&
        snapshot.conquest.oldWorldProvincesOwned <=
            kStalledOldWorldProvinceThreshold) {
      activeMinor = atWarMinors.single;
    }
  }
  if (activeMinor != null && snapshot.threats.atWarWith.contains(activeMinor)) {
    return activeMinor;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final gpBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (gpBlocker != null &&
      snapshot.threats.atWarWith.contains(gpBlocker) &&
      factionOwnsInvadableOldWorldProvince(
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        factionId: gpBlocker,
      )) {
    return gpBlocker;
  }
  if (!isObserverConquestExpansionPressure(
    snapshot.conquest.oldWorldProvincesOwned,
  )) {
    return declaredThisTurn;
  }
  String? bestMinorId;
  var bestInvadableCount = 0;
  for (final minor in game.minorNations) {
    final rel = getRelation(game, nationId, minor.id);
    if (rel?.state != RelationState.atWar) continue;
    final invadableCount = snapshot.conquest.invadableProvinceIdsSorted
        .where((pid) => provinceOwner[pid] == minor.id)
        .length;
    if (invadableCount > bestInvadableCount) {
      bestInvadableCount = invadableCount;
      bestMinorId = minor.id;
    }
  }
  return bestMinorId ?? declaredThisTurn;
}

Set<String> _legacyInvadableProvinceIds({
  required Game game,
  required AIWorldSnapshot snapshot,
  required bool structuralNewWorldSuppressed,
  double? nwInvasionWeightFromPhasePlan,
}) {
  final nwInvasionWeight =
      nwInvasionWeightFromPhasePlan ??
      (shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
            snapshot: snapshot,
            game: game,
          )
          ? 0.0
          : 1.0);
  return {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    if (!structuralNewWorldSuppressed && nwInvasionWeight > 0.0)
      ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
}

Set<String> _invadableProvinceIdsForConquestPass({
  required Game game,
  required AIWorldSnapshot snapshot,
  PhasePlanOutcome? phasePlan,
  PhaseConquestInvadableResolution? conquestResolution,
}) {
  if (phasePlan == null) {
    return _legacyInvadableProvinceIds(
      game: game,
      snapshot: snapshot,
      structuralNewWorldSuppressed: false,
    );
  }
  final resolution =
      conquestResolution ??
      resolvePhaseConquestInvadable(
        phasePlan: phasePlan,
        snapshot: snapshot,
        game: game,
      );
  final nwInvasionWeightFromPhasePlan = resolvePhaseConquestNwInvasionWeight(
    phasePlan: phasePlan,
  );
  if (resolution.useLegacyInvadable) {
    return _legacyInvadableProvinceIds(
      game: game,
      snapshot: snapshot,
      structuralNewWorldSuppressed: resolution.structuralNewWorldSuppressed,
      nwInvasionWeightFromPhasePlan: nwInvasionWeightFromPhasePlan,
    );
  }
  return resolution.phasePlanInvadableSorted.toSet();
}

/// Invasion army moves after same-turn declare war. SPEC/ai/ai-architecture.md.
/// Resolves the military-economy weight floor for a conquest army-move pass
/// (Refs #3977 AC6). Behaviour-preserving extraction from
/// [runConquestArmyMovePlanner].
int _resolveConquestArmyMoveWeight({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required bool stalledExpansion,
  required bool colonialPressureActive,
  required PhasePlanOutcome? phasePlan,
}) {
  var weight = ctx.resolveMilitaryEconomyWeight();
  final provincesToVictory = snapshot.conquest.provincesToVictory;
  if (ctx.primaryGoal == StrategicGoal.conquer || provincesToVictory > 10) {
    weight = weight < 10 ? 10 : weight;
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 10) {
    weight = 10;
  }
  final atWarWithInvadableTarget =
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      snapshot.threats.atWarWith.isNotEmpty;
  if (stalledExpansion &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < 90) {
    weight = 90;
  } else if (stalledExpansion && atWarWithInvadableTarget && weight < 80) {
    weight = 80;
  }
  if (stalledExpansion && weight < kConquestArmyMoveMinWeightWhenStalled) {
    weight = kConquestArmyMoveMinWeightWhenStalled;
  }
  if (snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      !isAtWarWithAnyGreatPower(ctx.game, snapshot) &&
      weight < kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar) {
    weight = kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar;
  }
  // Refs #2847 Phase 3 conquest colonial-pressure floor wiring: source
  // the floor magnitude from the soft-phase NW acquisition weight on the
  // dispatched phase plan instead of the legacy hard
  // `kConquestArmyMoveMinWeightWhenColonialPressure` floor. The null-phase-plan
  // fallback maps the legacy boolean (`colonialPressureActive`) to
  // `1.0 / 0.0` so callers without a `PhasePlanOutcome` preserve
  // pre-Phase-3 behaviour exactly. At the early-sprint default curve
  // (`newWorldAcquisition = 0.05` for OW <= 7) the floor collapses to
  // `round(45 * 0.05) = 2`, well below the stalled-expansion floors so
  // the OW conquest sprint is not dominated by colonial-pressure pulls.
  final colonialPressureWeight = colonialPressureScaleFromWeight(
    colonialPressureWeight: phasePlan != null
        ? resolvePhaseConquestColonialPressureWeight(phasePlan: phasePlan)
        : null,
    legacyColonialPressureActive: colonialPressureActive,
  );
  final colonialPressureFloor = conquestColonialPressureMinWeightFloor(
    colonialPressureWeight: colonialPressureWeight,
  );
  if (weight < colonialPressureFloor) {
    weight = colonialPressureFloor;
  }
  return weight;
}

Orders runConquestArmyMovePlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
  PhasePlanOutcome? phasePlan,
}) {
  PhaseConquestInvadableResolution? conquestResolution;
  if (phasePlan != null) {
    conquestResolution = resolvePhaseConquestInvadable(
      phasePlan: phasePlan,
      snapshot: snapshot,
      game: ctx.game,
    );
    if (conquestResolution.skipConquestPass) {
      return ctx.orders;
    }
  }

  final invadableForPass = _invadableProvinceIdsForConquestPass(
    game: ctx.game,
    snapshot: snapshot,
    phasePlan: phasePlan,
    conquestResolution: conquestResolution,
  );
  final phasePlanInvadableIsAuthoritative =
      conquestResolution != null && !conquestResolution.useLegacyInvadable;
  final colonialPressureActive = phasePlan != null
      ? resolvePhaseConquestColonialPressureActive(phasePlan: phasePlan)
      : hasColonialAcquisitionTargets(snapshot.colonial);
  final nwInvasionWeight = phasePlan != null
      ? resolvePhaseConquestNwInvasionWeight(phasePlan: phasePlan)
      : (shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
              snapshot: snapshot,
              game: ctx.game,
            )
            ? 0.0
            : 1.0);
  final oldWorldInvasionWeight = phasePlan != null
      ? resolvePhaseConquestOldWorldInvasionWeight(phasePlan: phasePlan)
      : 1.0;

  final stalledExpansion = isObserverConquestExpansionPressure(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  // Refs #2847 § EXPAND feedstock-tile acquisition conquest army-move target
  // bias (`SPEC/ai/economy-planner.md`). A flagged below-quota zero-NW
  // lock-recovery seller is always below quota and therefore always on the
  // stalled-expansion army-move path, so the conquest-target bias is computed
  // once here and threaded into the stalled selection helpers only. It returns
  // `null` for every player whose acquisition residual is inactive (so the +6
  // Old World conquest baseline GPs gp1/gp2 are never redirected) and for any
  // non-stalled caller, which never reaches the biased selection path.
  final feedstockConquestTarget = stalledExpansion
      ? expandSellerFeedstockTileAcquisitionTarget(
          game: ctx.game,
          snapshot: snapshot,
        )
      : null;
  final stalledScoringCtx = stalledExpansion
      ? ConquestMoveScoringContext.forArmyMovePass(
          plannerCtx: ctx,
          snapshot: snapshot,
          invadable: invadableForPass,
          stalledExpansion: true,
          declaredWarTargetFactionId: declaredWarTargetFactionId,
          phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
          nwInvasionWeight: nwInvasionWeight,
          oldWorldInvasionWeight: oldWorldInvasionWeight,
        )
      : null;
  final armyMoveCandidates = ctx.suggestionAPI.suggestArmyMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  if (armyMoveCandidates.isEmpty) {
    if (_log.debugEnabled) {
      _log.d('conquest army move nationId=${ctx.nationId} candidatesCount=0');
    }
    if (stalledExpansion) {
      return runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        scoringCtx: stalledScoringCtx!,
        feedstockConquestTarget: feedstockConquestTarget,
      );
    }
    return ctx.orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    ctx.game,
    ctx.nationId,
    armyMoveCandidates,
    draftOrders: ctx.orders,
  );
  if (filtered.isEmpty) {
    if (_log.debugEnabled) {
      _log.d('conquest army move filtered empty nationId=${ctx.nationId}');
    }
    if (stalledExpansion) {
      return runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        scoringCtx: stalledScoringCtx!,
        feedstockConquestTarget: feedstockConquestTarget,
      );
    }
    return ctx.orders;
  }
  final weight = _resolveConquestArmyMoveWeight(
    ctx: ctx,
    snapshot: snapshot,
    stalledExpansion: stalledExpansion,
    colonialPressureActive: colonialPressureActive,
    phasePlan: phasePlan,
  );
  if (weight < 10) {
    if (_log.debugEnabled) {
      _log.d(
        'conquest army move skipped nationId=${ctx.nationId} weight=$weight',
      );
    }
    return ctx.orders;
  }
  // Under stalled-expansion (Refs #2509 EXPAND / COLONIAL-lite hot path) a
  // capital field army frequently has no direct neighbor in the phase plan's
  // invadable set — e.g. seed-42 gp1's two field armies at `oldWorld|p12`
  // produce 12 diplomacy-passed candidates that all land on gp1-owned
  // provinces (`p1, p4, p5, p7, p8, p9`), none of which appear in
  // `invadableForPass = {p11, p13, p2}`. The strict invadable-only prefilter
  // here would empty `scoringCandidates`, the planner would return without
  // emitting any army move, and the capital armies sit at the capital across
  // every turn of the 100-turn observer run (gp1 OW gain = 0 against the
  // turn-100 +3 gate). Bypass the prefilter on the stalled-expansion path so
  // the stalled-expansion scoring in `scoreArmyMoveDestination` (which
  // already prefers invadable destinations first, then own-territory
  // adjacent-at-war-frontier marches via
  // `stalledExpansionArmyMoveScoreDelta`, and structurally returns `0` for
  // foreign non-invadable destinations) picks the best multi-turn approach
  // move toward the at-war frontier instead. Non-stalled (at-quota) callers
  // keep the strict prefilter so DEVELOP / COLONIAL stay structural.
  final scoringCandidates =
      phasePlanInvadableIsAuthoritative && !stalledExpansion
      ? filtered
            .where(
              (move) => invadableForPass.contains(move.destinationProvinceId),
            )
            .toList()
      : filtered;
  if (scoringCandidates.isEmpty) {
    return ctx.orders;
  }
  if (stalledExpansion) {
    return applyStalledArmyMovesForAllFieldArmies(
      ctx: ctx,
      scoringCtx: stalledScoringCtx!,
      filtered: scoringCandidates,
      feedstockConquestTarget: feedstockConquestTarget,
    );
  }
  final scoringCtx = ConquestMoveScoringContext.forArmyMovePass(
    plannerCtx: ctx,
    snapshot: snapshot,
    invadable: invadableForPass,
    stalledExpansion: false,
    declaredWarTargetFactionId: declaredWarTargetFactionId,
    phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
    nwInvasionWeight: nwInvasionWeight,
    oldWorldInvasionWeight: oldWorldInvasionWeight,
  );
  final selected = selectWeightedCandidate(
    candidates: scoringCandidates,
    seed: ctx.seeds.militarySeed + 4000,
    score: (m) => scoreArmyMoveDestination(scoringCtx, m),
  );
  if (selected == null) return ctx.orders;
  if (_log.infoEnabled) {
    _log.i(
      'conquest army move chosen nationId=${ctx.nationId} '
      'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId} '
      'declaredWarTarget=$declaredWarTargetFactionId',
    );
  }
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, selected);
}

/// Picks the highest-scoring army move from [candidates], applying the EXPAND
/// feedstock-tile acquisition conquest army-move target **tiebreak** (Refs
/// #2847 § EXPAND feedstock-tile acquisition conquest army-move target bias;
/// `SPEC/ai/economy-planner.md`).
///
/// Scans [candidates] tracking the highest [score]. On an **exact** score tie
/// the candidate whose `destinationProvinceId` equals [feedstockConquestTarget]
/// wins over a non-feedstock incumbent, so a flagged below-quota zero-NW
/// lock-recovery seller marches the field army onto the Old World feedstock
/// province it must acquire to source `lumber` / `castIron` domestically. The
/// tiebreak **never overrides a strictly higher-scored destination** (it only
/// breaks ties) and **never fires when [feedstockConquestTarget] is `null`** —
/// `expandSellerFeedstockTileAcquisitionTarget` returns `null` for every player
/// whose acquisition residual is inactive, so the +6 Old World conquest
/// baseline GPs gp1/gp2 are never redirected. With [feedstockConquestTarget]
/// `null` the selection is identical to a strict `score > best` argmax
/// (first-in-iteration order wins ties), preserving the prior behaviour
/// exactly. Pure and deterministic over [candidates] and [score].
ArmyMoveOrder? selectFeedstockBiasedBestArmyMove({
  required Iterable<ArmyMoveOrder> candidates,
  required double Function(ArmyMoveOrder move) score,
  required String? feedstockConquestTarget,
}) {
  ArmyMoveOrder? best;
  var bestScore = -1.0;
  var bestIsFeedstock = false;
  for (final move in candidates) {
    final moveScore = score(move);
    final isFeedstock =
        feedstockConquestTarget != null &&
        move.destinationProvinceId == feedstockConquestTarget;
    final beatsBest = moveScore > bestScore;
    final winsTiebreak =
        moveScore == bestScore && isFeedstock && !bestIsFeedstock;
    if (beatsBest || winsTiebreak) {
      best = move;
      bestScore = moveScore;
      bestIsFeedstock = isFeedstock;
    }
  }
  return best;
}

