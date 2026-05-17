import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import 'colonial_pressure.dart';
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
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return declaredThisTurn;
  }
  final provinceOwner = getProvinceOwnerMap(game);
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
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  String? declaredWarTargetFactionId,
}) {
  final stalledExpansion = isStalledOldWorldExpansion(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  final armyMoveCandidates = suggestionAPI.suggestArmyMoveOrders(
    view,
    game,
    topology,
    orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('conquest army move nationId=$nationId candidatesCount=0');
    if (stalledExpansion) {
      return _runStalledFrontierArmyMoveFallback(
        nationId: nationId,
        view: view,
        game: game,
        topology: topology,
        orders: orders,
        snapshot: snapshot,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
      );
    }
    return orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    game,
    nationId,
    armyMoveCandidates,
    draftOrders: orders,
  );
  if (filtered.isEmpty) {
    _log.d('conquest army move filtered empty nationId=$nationId');
    if (stalledExpansion) {
      return _runStalledFrontierArmyMoveFallback(
        nationId: nationId,
        view: view,
        game: game,
        topology: topology,
        orders: orders,
        snapshot: snapshot,
        declaredWarTargetFactionId: declaredWarTargetFactionId,
      );
    }
    return orders;
  }
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  var weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
      ? domainWeights.economy
      : 50;
  final provincesToVictory = snapshot.conquest.provincesToVictory;
  if (primaryGoal == StrategicGoal.conquer || provincesToVictory > 10) {
    weight = weight < 10 ? 10 : weight;
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 10) {
    weight = 10;
  }
  final atWarWithInvadableTarget = snapshot.conquest.invadableProvinceIdsSorted
      .isNotEmpty &&
      snapshot.threats.atWarWith.isNotEmpty;
  if (stalledExpansion && atWarWithInvadableTarget && weight < 80) {
    weight = 80;
  }
  if (stalledExpansion && weight < kConquestArmyMoveMinWeightWhenStalled) {
    weight = kConquestArmyMoveMinWeightWhenStalled;
  }
  if (hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kConquestArmyMoveMinWeightWhenColonialPressure) {
    weight = kConquestArmyMoveMinWeightWhenColonialPressure;
  }
  if (weight < 10) {
    _log.d('conquest army move skipped nationId=$nationId weight=$weight');
    return orders;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final invadable = {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
  if (stalledExpansion) {
    return _applyStalledArmyMovesForAllFieldArmies(
      nationId: nationId,
      game: game,
      topology: topology,
      orders: orders,
      snapshot: snapshot,
      provinceOwner: provinceOwner,
      invadable: invadable,
      filtered: filtered,
      declaredWarTargetFactionId: declaredWarTargetFactionId,
    );
  }
  final scores = filtered
      .map(
        (m) => _scoreArmyMoveDestination(
          move: m,
          nationId: nationId,
          game: game,
          topology: topology,
          snapshot: snapshot,
          provinceOwner: provinceOwner,
          invadable: invadable,
          stalledExpansion: false,
          declaredWarTargetFactionId: declaredWarTargetFactionId,
        ),
      )
      .toList();
  final idx = pickWeightedIndex(scores, seeds.militarySeed + 4000);
  if (idx == null) return orders;
  final selected = filtered[idx];
  _log.i(
    'conquest army move chosen nationId=$nationId '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId} '
    'declaredWarTarget=$declaredWarTargetFactionId',
  );
  return applyArmyMoveOrderForPlayer(orders, nationId, selected);
}

Orders _applyStalledArmyMovesForAllFieldArmies({
  required String nationId,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
  required Set<String> invadable,
  required List<ArmyMoveOrder> filtered,
  required String? declaredWarTargetFactionId,
}) {
  final armiesWithOrders = <String>{
    for (final m in orders.armyMoveOrdersByPlayerId[nationId] ?? const [])
      m.armyId,
  };
  final byArmy = <String, List<ArmyMoveOrder>>{};
  for (final move in filtered) {
    if (armiesWithOrders.contains(move.armyId)) continue;
    (byArmy[move.armyId] ??= []).add(move);
  }
  var result = orders;
  for (final armyId in byArmy.keys.toList()..sort()) {
    final candidates = byArmy[armyId]!;
    ArmyMoveOrder? best;
    var bestScore = -1.0;
    for (final move in candidates) {
      final score = _scoreArmyMoveDestination(
        move: move,
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
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
      'conquest army move stalled multi nationId=$nationId '
      'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
    );
    result = applyArmyMoveOrderForPlayer(result, nationId, best);
    armiesWithOrders.add(best.armyId);
  }
  return result;
}

Orders _runStalledFrontierArmyMoveFallback({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIWorldSnapshot snapshot,
  required String? declaredWarTargetFactionId,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  final invadable = {
    ...snapshot.conquest.invadableProvinceIdsSorted,
    ...snapshot.colonial.invadableNewWorldProvinceIdsSorted,
  };
  final playerOwnedFullProvinceIds = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == nationId) e.key,
  };
  final validator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: nationId,
    basePrefix: orders,
    factionMembership: DiplomacyFactionMembership.from(game),
    view: view,
    unitsById: unitsByIdFromWorld(game.worldState),
  );
  final armiesWithOrders = <String>{
    for (final m in orders.armyMoveOrdersByPlayerId[nationId] ?? const [])
      m.armyId,
  };
  ArmyMoveOrder? best;
  var bestScore = -1.0;
  for (final army in game.worldState.armies) {
    if (army.ownerId != nationId || army.isHomeArmy) continue;
    if (armiesWithOrders.contains(army.id)) continue;
    final destIds = armyMoveCandidateDestinationProvinceIds(
      game: game,
      topology: topology,
      playerId: nationId,
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
        nationId: nationId,
        game: game,
        topology: topology,
        snapshot: snapshot,
        provinceOwner: provinceOwner,
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
    return orders;
  }
  _log.i(
    'conquest army move stalled fallback nationId=$nationId '
    'armyId=${best.armyId} destinationProvinceId=${best.destinationProvinceId}',
  );
  return applyArmyMoveOrderForPlayer(orders, nationId, best);
}

double _scoreArmyMoveDestination({
  required ArmyMoveOrder move,
  required String nationId,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required Map<String, String> provinceOwner,
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
    final atWarMinorOrTribe =
        destOwner.isNotEmpty &&
        destOwner != nationId &&
        snapshot.threats.atWarWith.contains(destOwner) &&
        _isMinorOrTribeFaction(game, destOwner);
    if ((declaredWarTargetFactionId != null &&
            destOwner == declaredWarTargetFactionId) ||
        atWarMinorOrTribe) {
      score += kConquestArmyMoveStalledDeclaredTargetBonus;
      if (invadable.contains(move.destinationProvinceId)) {
        score += kConquestArmyMoveStalledDeclaredTargetInvadableBonus;
      }
    } else if (destOwner == nationId) {
      var onAtWarFrontier = false;
      for (final n in destNeighborLocals) {
        final nOwner = provinceOwner[ProvinceId.full(destRegion, n)] ?? '';
        if (snapshot.threats.atWarWith.contains(nOwner) &&
            _isMinorOrTribeFaction(game, nOwner)) {
          onAtWarFrontier = true;
          break;
        }
      }
      if (onAtWarFrontier) {
        score += kConquestArmyMoveAdjacentAtWarFrontierBonus;
      } else {
        score *= 0.05;
      }
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
    score += kConquestArmyMoveNwInvadableBonus;
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
