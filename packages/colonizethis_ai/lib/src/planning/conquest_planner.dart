import 'goal_manager.dart';
import 'planning_imports.dart';
import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planner_context.dart';
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
    final atWarMinors = <String>[
      for (final factionId in snapshot.threats.atWarWith)
        if (game.minorNations.any((m) => m.id == factionId)) factionId,
    ]..sort();
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
      snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == gpBlocker,
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
  bool? suppressNwInvasionFromPhasePlan,
}) {
  final suppressNwInvasion =
      suppressNwInvasionFromPhasePlan ??
      shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
        snapshot: snapshot,
        game: game,
      );
  return {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    if (!structuralNewWorldSuppressed && !suppressNwInvasion)
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
      conquestResolution ?? resolvePhaseConquestInvadable(phasePlan: phasePlan);
  final suppressNwInvasionFromPhasePlan =
      resolvePhaseConquestSuppressNwInvasionScoring(phasePlan: phasePlan);
  if (resolution.useLegacyInvadable) {
    return _legacyInvadableProvinceIds(
      game: game,
      snapshot: snapshot,
      structuralNewWorldSuppressed: resolution.structuralNewWorldSuppressed,
      suppressNwInvasionFromPhasePlan: suppressNwInvasionFromPhasePlan,
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
    conquestResolution = resolvePhaseConquestInvadable(phasePlan: phasePlan);
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
  final suppressNwInvasionScoring = phasePlan != null
      ? resolvePhaseConquestSuppressNwInvasionScoring(phasePlan: phasePlan)
      : shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: snapshot,
          game: ctx.game,
        );

  final stalledExpansion = isObserverConquestExpansionPressure(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  final armyMoveCandidates = ctx.suggestionAPI.suggestArmyMoveOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('conquest army move nationId=${ctx.nationId} candidatesCount=0');
    if (stalledExpansion) {
      return _runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
        invadable: invadableForPass,
        phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
        suppressNwInvasionScoring: suppressNwInvasionScoring,
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
    _log.d('conquest army move filtered empty nationId=${ctx.nationId}');
    if (stalledExpansion) {
      return _runStalledFrontierArmyMoveFallback(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
        invadable: invadableForPass,
        phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
        suppressNwInvasionScoring: suppressNwInvasionScoring,
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
      !snapshot.threats.atWarWith.any(
        (id) => ctx.game.playerById(id) != null,
      ) &&
      weight < kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar) {
    weight = kConquestArmyMoveMinWeightWhenCriticallyWeakNoGpWar;
  }
  if (colonialPressureActive &&
      weight < kConquestArmyMoveMinWeightWhenColonialPressure) {
    weight = kConquestArmyMoveMinWeightWhenColonialPressure;
  }
  if (weight < 10) {
    _log.d(
      'conquest army move skipped nationId=${ctx.nationId} weight=$weight',
    );
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
      snapshot: snapshot,
      invadable: invadableForPass,
      filtered: scoringCandidates,
      declaredWarTargetFactionId: declaredWarTargetFactionId,
      phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
      suppressNwInvasionScoring: suppressNwInvasionScoring,
    );
  }
  final selected = selectWeightedCandidate(
    candidates: scoringCandidates,
    seed: ctx.seeds.militarySeed + 4000,
    score: (m) => _scoreArmyMoveDestination(
      move: m,
      nationId: ctx.nationId,
      game: ctx.game,
      topology: ctx.topology,
      snapshot: snapshot,
      provinceOwner: ctx.provinceOwner,
      invadable: invadableForPass,
      stalledExpansion: false,
      declaredWarTargetFactionId: declaredWarTargetFactionId,
      phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
      suppressNwInvasionScoring: suppressNwInvasionScoring,
    ),
  );
  if (selected == null) return ctx.orders;
  _log.i(
    'conquest army move chosen nationId=${ctx.nationId} '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId} '
    'declaredWarTarget=$declaredWarTargetFactionId',
  );
  return applyArmyMoveOrderForPlayer(ctx.orders, ctx.nationId, selected);
}

Orders _applyStalledArmyMovesForAllFieldArmies({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required Set<String> invadable,
  required List<ArmyMoveOrder> filtered,
  required String? declaredWarTargetFactionId,
  required bool phasePlanInvadableIsAuthoritative,
  required bool suppressNwInvasionScoring,
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
    ArmyMoveOrder? best;
    var bestScore = -1.0;
    for (final move in candidates) {
      final score = _scoreArmyMoveDestination(
        move: move,
        nationId: ctx.nationId,
        game: ctx.game,
        topology: ctx.topology,
        snapshot: snapshot,
        provinceOwner: ctx.provinceOwner,
        invadable: invadable,
        stalledExpansion: true,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
        phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
        suppressNwInvasionScoring: suppressNwInvasionScoring,
      );
      if (score > bestScore) {
        bestScore = score;
        best = move;
      }
    }
    if (best == null) continue;
    _log.i(
      'conquest army move stalled multi nationId=${ctx.nationId} '
      'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
    );
    result = applyArmyMoveOrderForPlayer(result, ctx.nationId, best);
    armiesWithOrders.add(best.armyId);
  }
  return result;
}

Orders _runStalledFrontierArmyMoveFallback({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required String? declaredWarTargetFactionId,
  required Set<String> invadable,
  required bool phasePlanInvadableIsAuthoritative,
  required bool suppressNwInvasionScoring,
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
    view: ctx.view,
    unitsById: unitsByIdFromWorld(ctx.game.worldState),
  );
  final armiesWithOrders = <String>{
    for (final m
        in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
      m.armyId,
  };
  ArmyMoveOrder? best;
  var bestScore = -1.0;
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
      final score = _scoreArmyMoveDestination(
        move: candidate,
        nationId: ctx.nationId,
        game: ctx.game,
        topology: ctx.topology,
        snapshot: snapshot,
        provinceOwner: ctx.provinceOwner,
        invadable: invadable,
        stalledExpansion: true,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
        phasePlanInvadableIsAuthoritative: phasePlanInvadableIsAuthoritative,
        suppressNwInvasionScoring: suppressNwInvasionScoring,
      );
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
  }
  if (best == null) {
    return ctx.orders;
  }
  _log.i(
    'conquest army move stalled fallback nationId=${ctx.nationId} '
    'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
  );
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

double _stalledExpansionArmyMoveScoreDelta({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required Map<String, String?> provinceOwner,
  required Set<String> invadable,
  required String destOwner,
  required String destRegion,
  required Iterable<String> destNeighborLocals,
  required String? declaredWarTargetFactionId,
}) {
  final atWarMinorOrTribe =
      destOwner.isNotEmpty &&
      destOwner != nationId &&
      snapshot.threats.atWarWith.contains(destOwner) &&
      isMinorOrTribeFaction(game, destOwner);
  final atWarGpInvadableBlocker =
      destOwner.isNotEmpty &&
      destOwner != nationId &&
      snapshot.threats.atWarWith.contains(destOwner) &&
      game.playerById(destOwner) != null &&
      snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == destOwner,
      );
  final targetsDeclaredOrAtWarEnemy =
      (declaredWarTargetFactionId != null &&
          destOwner == declaredWarTargetFactionId) ||
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
      final blockerOw = provinceCountOwnedBy(game, destOwner);
      final deficit = blockerOw - snapshot.conquest.oldWorldProvincesOwned;
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

double _scoreArmyMoveDestination({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required Map<String, String?> provinceOwner,
  required Set<String> invadable,
  required bool stalledExpansion,
  required String? declaredWarTargetFactionId,
  required bool phasePlanInvadableIsAuthoritative,
  required bool suppressNwInvasionScoring,
}) {
  final destOwner = provinceOwner[move.destinationProvinceId] ?? '';
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
      score += delta;
    }
  } else if (declaredWarTargetFactionId != null &&
      destOwner == declaredWarTargetFactionId) {
    score += 50;
  } else {
    final rel = getRelation(game, nationId, destOwner);
    if (rel != null && rel.atWar) {
      score += kMovePreferEnemyTerritoryBonus.toDouble();
    }
  }
  if (invadable.contains(move.destinationProvinceId)) {
    score += 10;
  }
  if (snapshot.colonial.invadableNewWorldProvinceIdsSorted.contains(
    move.destinationProvinceId,
  )) {
    if (suppressNwInvasionScoring) {
      return 0;
    }
    if (isBelowObserverConquestQuota(
      snapshot.conquest.oldWorldProvincesOwned,
    )) {
      score -= kConquestArmyMoveNwInvadableBonus;
    } else {
      score += kConquestArmyMoveNwInvadableBonus;
    }
  }
  if (snapshot.conquest.adjacentOwnerFactionIdsSorted.contains(destOwner)) {
    score += 8;
  }
  for (final inv in snapshot.conquest.invadableProvinceIdsSorted) {
    if (ProvinceId.regionIdFrom(inv) != destRegion) {
      continue;
    }
    if (destNeighborLocals.contains(ProvinceId.localIdFrom(inv))) {
      score += kConquestArmyMoveAdjacentInvadableBonus;
      break;
    }
  }
  return score;
}
