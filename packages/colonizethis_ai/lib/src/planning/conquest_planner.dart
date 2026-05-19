import 'goal_manager.dart';
import 'planning_imports.dart';
import '../perception/perception_snapshot.dart';
import 'colonial_pressure.dart';
import 'diplomacy_planner_peace_targets.dart'
    show belowQuotaActiveMinorWarTarget;
import 'planner_context.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

bool _isMinorOrTribeFaction(Game game, String factionId) =>
    game.minorNations.any((m) => m.id == factionId) ||
    game.tribes.any((t) => t.id == factionId);

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
      isBelowObserverConquestQuota(
        snapshot.conquest.oldWorldProvincesOwned,
      )) {
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
  if (activeMinor != null &&
      snapshot.threats.atWarWith.contains(activeMinor)) {
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

/// Invasion army moves after same-turn declare war. SPEC/ai/ai-architecture.md.
Orders runConquestArmyMovePlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  String? declaredWarTargetFactionId,
}) {
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
  final atWarWithInvadableTarget = snapshot.conquest.invadableProvinceIdsSorted
      .isNotEmpty &&
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
  if (hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kConquestArmyMoveMinWeightWhenColonialPressure) {
    weight = kConquestArmyMoveMinWeightWhenColonialPressure;
  }
  if (weight < 10) {
    _log.d('conquest army move skipped nationId=${ctx.nationId} weight=$weight');
    return ctx.orders;
  }
  final invadable = {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
  if (stalledExpansion) {
    return _applyStalledArmyMovesForAllFieldArmies(
      ctx: ctx,
      snapshot: snapshot,
      invadable: invadable,
      filtered: filtered,
      declaredWarTargetFactionId: declaredWarTargetFactionId,
    );
  }
  final selected = selectWeightedCandidate(
    candidates: filtered,
    seed: ctx.seeds.militarySeed + 4000,
    score: (m) => _scoreArmyMoveDestination(
      move: m,
      nationId: ctx.nationId,
      game: ctx.game,
      topology: ctx.topology,
      snapshot: snapshot,
      provinceOwner: ctx.provinceOwner,
      invadable: invadable,
      stalledExpansion: false,
      declaredWarTargetFactionId: declaredWarTargetFactionId,
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
}) {
  final armiesWithOrders = <String>{
    for (final m in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
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
}) {
  final invadable = {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
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
    for (final m in ctx.orders.armyMoveOrdersByPlayerId[ctx.nationId] ?? const [])
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
    if (_isMinorOrTribeFaction(game, nOwner)) return true;
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
      _isMinorOrTribeFaction(game, destOwner);
  final atWarGpInvadableBlocker = destOwner.isNotEmpty &&
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
}) {
  final destOwner = provinceOwner[move.destinationProvinceId] ?? '';
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
  if (snapshot.colonial.invadableNewWorldProvinceIdsSorted
      .contains(move.destinationProvinceId)) {
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
