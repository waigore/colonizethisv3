import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'conquest_move_scoring_context.dart';
import 'goal_manager.dart';
import 'planning_imports.dart';
import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_priority_weights.dart';
import 'planner_context.dart';
import 'planning_helpers.dart'
    show
        clampPhaseWeightUpperUnit,
        colonialPressureScaleFromWeight,
        factionOwnsInvadableOldWorldProvince,
        isAtWarWithAnyGreatPower,
        minorAtWarPeaceTargetsWhere,
        oldWorldProvinceLeadOver;
import '../util/ai_random_utils.dart';
import '../util/faction_query.dart';

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
      return _runStalledFrontierArmyMoveFallback(
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
      return _runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        scoringCtx: stalledScoringCtx!,
        feedstockConquestTarget: feedstockConquestTarget,
      );
    }
    return ctx.orders;
  }
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
  // the stalled-expansion scoring in `_scoreArmyMoveDestination` (which
  // already prefers invadable destinations first, then own-territory
  // adjacent-at-war-frontier marches via
  // `_stalledExpansionArmyMoveScoreDelta`, and structurally returns `0` for
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
    return _applyStalledArmyMovesForAllFieldArmies(
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
    score: (m) => _scoreArmyMoveDestination(scoringCtx, m),
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

Orders _applyStalledArmyMovesForAllFieldArmies({
  required PlannerContext ctx,
  required ConquestMoveScoringContext scoringCtx,
  required List<ArmyMoveOrder> filtered,
  required String? feedstockConquestTarget,
}) {
  final armiesWithOrders = <String>{
    for (final m
        in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
      m.armyId,
  };
  final byArmy = <String, List<ArmyMoveOrder>>{};
  for (final move in filtered) {
    if (armiesWithOrders.contains(move.armyId)) continue;
    (byArmy[move.armyId] ??= []).add(move);
  }
  var result = ctx.orders;
  for (final armyId in byArmy.keys.toList()..sort()) {
    final candidates = byArmy[armyId]!;
    final best = selectFeedstockBiasedBestArmyMove(
      candidates: candidates,
      feedstockConquestTarget: feedstockConquestTarget,
      score: (move) => _scoreArmyMoveDestination(scoringCtx, move),
    );
    if (best == null) continue;
    if (_log.infoEnabled) {
      _log.i(
        'conquest army move stalled multi nationId=${ctx.nationId} '
        'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
      );
    }
    result = applyArmyMoveOrderForPlayer(result, ctx.nationId, best);
    armiesWithOrders.add(best.armyId);
  }
  return result;
}

Orders _runStalledFrontierArmyMoveFallback({
  required PlannerContext ctx,
  required ConquestMoveScoringContext scoringCtx,
  required String? feedstockConquestTarget,
}) {
  final playerOwnedFullProvinceIds = <String>{
    for (final e in ctx.view.provincesById.entries)
      if (e.value.ownerId == ctx.nationId) e.key,
  };
  final validator = IncrementalCandidateValidator.forPlayer(
    game: ctx.game,
    topology: ctx.topology,
    playerId: ctx.nationId,
    basePrefix: ctx.orders,
    factionMembership: DiplomacyFactionMembership.from(ctx.game),
    resolution: orderResolutionContextFromView(ctx.view, ctx.game),
  );
  final armiesWithOrders = <String>{
    for (final m
        in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
      m.armyId,
  };
  final acceptedCandidates = <ArmyMoveOrder>[];
  for (final army in ctx.game.worldState.armies) {
    if (army.ownerId != ctx.nationId || army.isHomeArmy) continue;
    if (armiesWithOrders.contains(army.id)) continue;
    final destIds = armyMoveCandidateDestinationProvinceIds(
      game: ctx.game,
      topology: ctx.topology,
      playerId: ctx.nationId,
      army: army,
      playerOwnedFullProvinceIds: playerOwnedFullProvinceIds,
    );
    for (final destinationProvinceId in destIds) {
      final candidate = ArmyMoveOrder(
        armyId: army.id,
        destinationProvinceId: destinationProvinceId,
      );
      if (!validator.isArmyMoveAccepted(candidate)) continue;
      acceptedCandidates.add(candidate);
    }
  }
  final best = selectFeedstockBiasedBestArmyMove(
    candidates: acceptedCandidates,
    feedstockConquestTarget: feedstockConquestTarget,
    score: (candidate) => _scoreArmyMoveDestination(scoringCtx, candidate),
  );
  if (best == null) {
    return ctx.orders;
  }
  if (_log.infoEnabled) {
    _log.i(
      'conquest army move stalled fallback nationId=${ctx.nationId} '
      'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
    );
  }
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, best);
}

bool _isOnAtWarMinorOrTribeFrontier({
  required Game game,
  required Map<String, String?> provinceOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required Iterable<String> atWarWith,
}) {
  for (final n in destNeighborLocals) {
    final nOwner = provinceOwner[ProvinceId.full(destRegion, n)] ?? '';
    if (!atWarWith.contains(nOwner)) continue;
    if (isMinorOrTribeFaction(game, nOwner)) return true;
  }
  return false;
}

/// Sole at-war Great Power peer when [expandIsGeographicPeerWarLock] holds.
String? _geographicPeerWarLockPeerGpId(AIWorldSnapshot snapshot) {
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  if (adjacentOwners.length != 1) {
    return null;
  }
  return adjacentOwners.single;
}

bool _provinceNeighborOwnedByAtWarMinorOrTribe({
  required Game game,
  required Map<String, String?> provinceOwner,
  required String regionId,
  required Iterable<String> neighborLocals,
  required Iterable<String> atWarWith,
}) {
  for (final n in neighborLocals) {
    final nOwner = provinceOwner[ProvinceId.full(regionId, n)] ?? '';
    if (!atWarWith.contains(nOwner)) continue;
    if (isMinorOrTribeFaction(game, nOwner)) return true;
  }
  return false;
}

/// Whether [move]'s destination is a stalled-expansion march step toward an
/// at-war minor/tribe reachable only through the geographic peer-war lock
/// (Refs #2847 § H4-b).
bool _isGeographicPeerLockMinorTransitDestination({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required Map<String, String?> provinceOwner,
  required String destOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required String peerGpId,
}) {
  final atWarWith = snapshot.threats.atWarWith;
  if (destOwner == peerGpId) {
    return _provinceNeighborOwnedByAtWarMinorOrTribe(
      game: game,
      provinceOwner: provinceOwner,
      regionId: destRegion,
      neighborLocals: destNeighborLocals,
      atWarWith: atWarWith,
    );
  }
  if (destOwner != nationId) {
    return false;
  }
  for (final peerLocal in destNeighborLocals) {
    final peerFull = ProvinceId.full(destRegion, peerLocal);
    if ((provinceOwner[peerFull] ?? '') != peerGpId) continue;
    final beyondPeer = neighborProvinceIdsInRegion(
      topology,
      destRegion,
      peerLocal,
    );
    if (_provinceNeighborOwnedByAtWarMinorOrTribe(
      game: game,
      provinceOwner: provinceOwner,
      regionId: destRegion,
      neighborLocals: beyondPeer,
      atWarWith: atWarWith,
    )) {
      return true;
    }
  }
  return false;
}

double _stalledExpansionArmyMoveScoreDelta({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required Map<String, String?> provinceOwner,
  required Set<String> invadable,
  required String destOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required String? declaredWarTargetFactionId,
}) {
  final geoLockPeerGpId = _geographicPeerWarLockPeerGpId(snapshot);
  final geoLockActive = geoLockPeerGpId != null &&
      expandIsGeographicPeerWarLock(
        snapshot: snapshot,
        peerGpId: geoLockPeerGpId,
      ) &&
      snapshot.conquest.oldWorldProvincesOwned <=
          provinceCountOwnedBy(game, geoLockPeerGpId);
  if (geoLockActive &&
      _isGeographicPeerLockMinorTransitDestination(
        move: move,
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        destOwner: destOwner,
        destRegion: destRegion,
        destNeighborLocals: destNeighborLocals,
        peerGpId: geoLockPeerGpId,
      )) {
    return kConquestArmyMoveAdjacentAtWarFrontierBonus +
        kConquestArmyMoveStalledDeclaredTargetBonus;
  }
  final atWarMinorOrTribe =
      destOwner.isNotEmpty &&
      destOwner != nationId &&
      snapshot.threats.atWarWith.contains(destOwner) &&
      isMinorOrTribeFaction(game, destOwner);
  final atWarGpInvadableBlocker =
      !geoLockActive &&
      destOwner.isNotEmpty &&
      destOwner != nationId &&
      snapshot.threats.atWarWith.contains(destOwner) &&
      game.playerById(destOwner) != null &&
      snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == destOwner,
      );
  final peerDeclaredWarWithoutMinorTransit = geoLockActive &&
      declaredWarTargetFactionId == geoLockPeerGpId &&
      destOwner == geoLockPeerGpId &&
      !_isGeographicPeerLockMinorTransitDestination(
        move: move,
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
        destOwner: destOwner,
        destRegion: destRegion,
        destNeighborLocals: destNeighborLocals,
        peerGpId: geoLockPeerGpId,
      );
  final targetsDeclaredOrAtWarEnemy =
      (declaredWarTargetFactionId != null &&
          destOwner == declaredWarTargetFactionId &&
          !peerDeclaredWarWithoutMinorTransit) ||
      atWarMinorOrTribe ||
      atWarGpInvadableBlocker;
  if (targetsDeclaredOrAtWarEnemy) {
    var delta = atWarGpInvadableBlocker
        ? kConquestArmyMoveStalledGpInvadableBlockerBonus
        : kConquestArmyMoveStalledDeclaredTargetBonus;
    if (atWarMinorOrTribe &&
        isBelowObserverConquestQuota(
          snapshot.conquest.oldWorldProvincesOwned,
        )) {
      delta += kConquestArmyMoveStalledDeclaredTargetBonus;
    }
    if (atWarGpInvadableBlocker) {
      final deficit = oldWorldProvinceLeadOver(
        game: game,
        snapshot: snapshot,
        factionId: destOwner,
      );
      if (deficit > 0) {
        delta +=
            deficit * kConquestArmyMoveStalledBehindGpBlockerBonusPerProvince;
      }
    }
    if (invadable.contains(move.destinationProvinceId)) {
      delta += kConquestArmyMoveStalledDeclaredTargetInvadableBonus;
    }
    return delta;
  }
  if (destOwner != nationId) return 0;
  if (_isOnAtWarMinorOrTribeFrontier(
    game: game,
    provinceOwner: provinceOwner,
    destRegion: destRegion,
    destNeighborLocals: destNeighborLocals,
    atWarWith: snapshot.threats.atWarWith,
  )) {
    return kConquestArmyMoveAdjacentAtWarFrontierBonus;
  }
  return -0.95;
}

/// Scales an OW army-move additive score term by the soft-phase
/// [oldWorldInvasionWeight] (Refs #2847 Phase 3 conquest OW-invasion wiring).
///
/// Returns `0.0` when [oldWorldInvasionWeight] is `<= 0.0` (legacy
/// hard-suppress equivalent). At `1.0` the result equals [baseBonus]
/// exactly. Intermediate weights scale linearly with clamping to `[0.0, 1.0]`.
///
/// Pure and deterministic (Refs #2509 Must-have #7).
double conquestOldWorldArmyMoveScaledBonus({
  required double baseBonus,
  required double oldWorldInvasionWeight,
}) {
  if (oldWorldInvasionWeight <= 0.0) {
    return 0.0;
  }
  final clamped = clampPhaseWeightUpperUnit(oldWorldInvasionWeight);
  return baseBonus * clamped;
}

/// NW-invadable army-move bonus contribution for the conquest destination
/// scorer (Refs #2847 Phase 2 conquest NW-invasion sign migration).
///
/// A **below-quota** GP normally pays a **negative** NW-invadable bonus so the
/// early-game OW conquest sprint stays dominant. But once a § Resource-need
/// override has lifted the dispatched `newWorldAcquisition` weight to/above
/// [kPhasePriorityNwInvadablePursuitWeightThreshold], the GP is electing to
/// pursue NW provinces for treasury income (requirement clarification #3 —
/// "resource-need overrides bypass phase priority; the AI pursues NW provinces
/// *because* it needs income to fund OW conquest"). Below quota, only the
/// treasury-recovery (`0.60`) and zero-regiment (`0.30`) override floors reach
/// that threshold; the ordinary curve plateau peaks at `0.20` at OW = 9, so it
/// never trips it. The bonus then flips **positive** so the weight biases the
/// field army *toward* the NW income foothold instead of repelling it (the
/// prior unconditional below-quota negation inverted the override, leaving
/// treasury-locked below-quota GPs unable to reach the NW foothold the
/// override exists to unlock).
///
/// At or above the OW conquest quota ([belowQuota] is `false`) the bonus is
/// always positive — the early-sprint penalty applies only below quota — so
/// healthy expanding GPs are unaffected and the magnitude scales continuously
/// with [nwInvasionWeight].
///
/// Pure and deterministic — identical `(belowQuota, nwInvasionWeight)` inputs
/// always yield the same `double` (Refs #2509 Must-have #7). Callers gate the
/// `nwInvasionWeight <= 0.0` legacy hard-suppress case (zeroed destination)
/// before invoking this helper.
double conquestNwInvadableArmyMoveBonus({
  required bool belowQuota,
  required double nwInvasionWeight,
}) {
  final pursueNwForResourceNeed =
      nwInvasionWeight >= kPhasePriorityNwInvadablePursuitWeightThreshold;
  final signedBonus = (belowQuota && !pursueNwForResourceNeed)
      ? -kConquestArmyMoveNwInvadableBonus
      : kConquestArmyMoveNwInvadableBonus;
  return signedBonus * nwInvasionWeight;
}

double _scoreArmyMoveDestination(
  ConquestMoveScoringContext ctx,
  ArmyMoveOrder move,
) {
  final nationId = ctx.nationId;
  final game = ctx.game;
  final topology = ctx.topology;
  final snapshot = ctx.snapshot;
  final provinceOwner = ctx.provinceOwner;
  final invadable = ctx.invadable;
  final stalledExpansion = ctx.stalledExpansion;
  final declaredWarTargetFactionId = ctx.declaredWarTargetFactionId;
  final phasePlanInvadableIsAuthoritative =
      ctx.phasePlanInvadableIsAuthoritative;
  final nwInvasionWeight = ctx.nwInvasionWeight;
  final oldWorldInvasionWeight = ctx.oldWorldInvasionWeight;

  final destOwner = provinceOwner[move.destinationProvinceId] ?? '';
  final isNwInvadableDestination = snapshot
      .colonial
      .invadableNewWorldProvinceIdsSorted
      .contains(move.destinationProvinceId);
  if (phasePlanInvadableIsAuthoritative &&
      !invadable.contains(move.destinationProvinceId)) {
    // Stalled-expansion allowance (Refs #2509): own-territory marches stay
    // scoreable even when the phase plan's invadable set is authoritative,
    // so a stuck capital field army can march one province toward the
    // at-war frontier this turn and invade on the next. Foreign non-invadable
    // destinations (other GP, NW under EXPAND, etc.) remain blocked here —
    // the relaxation does not introduce any new declare-war / NW behavior.
    final ownMarchPermitted = stalledExpansion && destOwner == nationId;
    if (!ownMarchPermitted) {
      return 0;
    }
  }
  final destRegion = ProvinceId.regionIdFrom(move.destinationProvinceId);
  final destLocal = ProvinceId.localIdFrom(move.destinationProvinceId);
  final destNeighborLocals = neighborProvinceIdsInRegion(
    topology,
    destRegion,
    destLocal,
  );
  var score = 1.0;
  if (stalledExpansion) {
    final delta = _stalledExpansionArmyMoveScoreDelta(
      move: move,
      nationId: nationId,
      game: game,
      topology: topology,
      snapshot: snapshot,
      provinceOwner: provinceOwner,
      invadable: invadable,
      destOwner: destOwner,
      destRegion: destRegion,
      destNeighborLocals: destNeighborLocals,
      declaredWarTargetFactionId: declaredWarTargetFactionId,
    );
    if (delta < 0) {
      score *= 0.05;
    } else {
      score += conquestOldWorldArmyMoveScaledBonus(
        baseBonus: delta,
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
    }
  } else if (declaredWarTargetFactionId != null &&
      destOwner == declaredWarTargetFactionId) {
    score += conquestOldWorldArmyMoveScaledBonus(
      baseBonus: 50,
      oldWorldInvasionWeight: oldWorldInvasionWeight,
    );
  } else {
    final rel = getRelation(game, nationId, destOwner);
    if (rel != null && rel.atWar) {
      score += conquestOldWorldArmyMoveScaledBonus(
        baseBonus: kMovePreferEnemyTerritoryBonus.toDouble(),
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
    }
  }
  if (invadable.contains(move.destinationProvinceId) &&
      !isNwInvadableDestination) {
    score += conquestOldWorldArmyMoveScaledBonus(
      baseBonus: 10,
      oldWorldInvasionWeight: oldWorldInvasionWeight,
    );
  }
  if (snapshot.colonial.invadableNewWorldProvinceIdsSorted.contains(
    move.destinationProvinceId,
  )) {
    if (nwInvasionWeight <= 0.0) {
      return 0;
    }
    score += conquestNwInvadableArmyMoveBonus(
      belowQuota: isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      ),
      nwInvasionWeight: nwInvasionWeight,
    );
  }
  if (snapshot.conquest.adjacentOwnerFactionIdsSorted.contains(destOwner)) {
    score += conquestOldWorldArmyMoveScaledBonus(
      baseBonus: 8,
      oldWorldInvasionWeight: oldWorldInvasionWeight,
    );
  }
  for (final inv in snapshot.conquest.invadableProvinceIdsSorted) {
    if (ProvinceId.regionIdFrom(inv) != destRegion) {
      continue;
    }
    if (destNeighborLocals.contains(ProvinceId.localIdFrom(inv))) {
      score += conquestOldWorldArmyMoveScaledBonus(
        baseBonus: kConquestArmyMoveAdjacentInvadableBonus.toDouble(),
        oldWorldInvasionWeight: oldWorldInvasionWeight,
      );
      break;
    }
  }
  return score;
}
