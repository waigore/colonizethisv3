import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
import 'goal_manager.dart';
import 'war_desire_calculator.dart';

final _log = packageLogger();

/// Pre-weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores({
  required List<DiplomaticOrder> candidates,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  StrategicGoal? primaryGoal,
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = getThresholdsForLeader(config.personalityId);
  var maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  final behindVictoryPace = snapshot.conquest.provincesToVictory >
      kConquerScoreFloorProvincesToVictoryThreshold;
  final suppressGpDeclareWar = snapshot.conquest.provincesToVictory >
      kSuppressGpDeclareWarMinProvincesToVictory;
  final provinceOwner = getProvinceOwnerMap(game);
  final invadableOwners = <String>{
    for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
    for (final provinceId
        in snapshot.colonial.invadableNewWorldProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
  }..remove('');
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
  final anyMinorOwnsOldWorld = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  final warDesireByTarget = <String, int>{};
  int warDesireForTarget(String targetFactionId, int relationScore) {
    return warDesireByTarget.putIfAbsent(
      targetFactionId,
      () => computeWarDesireScore(
        game: game,
        nationId: nationId,
        targetFactionId: targetFactionId,
        relationScore: relationScore,
      ),
    );
  }
  return candidates.map((o) {
    var s = 50;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          // Lower peace desire when current war desire remains high.
          s -= (warDesire - 50);
          if (_isMinorOrTribeFaction(game, o.targetFactionId) &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              !invadableOwners.contains(o.targetFactionId)) {
            s += kOfferPeaceFutileMinorWarBonus;
          }
        }
        s += getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.peaceTendency - 50);
        break;
      case DiplomaticOrderType.alliance:
        s += getAgendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.declareWar:
        s = _scoreDeclareWarDiplomaticOrder(
          order: o,
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
        );
        break;
      case DiplomaticOrderType.establishOverture:
        {
          if (_isDecisionOnCooldown(
            game: game,
            actorFactionId: nationId,
            targetFactionId: o.targetFactionId,
            eventTypes: const [
              DiplomaticEventType.overtureAccepted,
              DiplomaticEventType.overtureRejected,
            ],
            cooldownTurns: improveRelationsCooldownTurns,
            currentTurn: currentTurn,
          )) {
            s = 0;
            break;
          }
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          final improveRelationsDesire = 100 - warDesire;
          s += (improveRelationsDesire - 50);
          if (snapshot.colonial.preferredColonialTargetFactionIdsSorted
              .contains(o.targetFactionId)) {
            s += kEstablishOvertureColonialTribeBonus;
          }
          final ownsInvadableNw = snapshot
              .colonial
              .invadableNewWorldProvinceIdsSorted
              .any((pid) => provinceOwner[pid] == o.targetFactionId);
          if (ownsInvadableNw && _isTribeFaction(game, o.targetFactionId)) {
            s += kEstablishOvertureColonialInvadableOwnerBonus;
          }
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

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
}) {
  final rel = snapshot.relations[order.targetFactionId];
  final relationScore = rel?.score ?? 50;
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  final colonialAdjacent =
      snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
  final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
  final isColonialAdjacentOwner =
      colonialAdjacent.contains(order.targetFactionId);
  final isMinorTarget = _isMinorOrTribeFaction(game, order.targetFactionId);
  final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
      .any((pid) => provinceOwner[pid] == order.targetFactionId);
  final colonialPressure = hasColonialAcquisitionTargets(snapshot.colonial);
  final isTribeTarget = _isTribeFaction(game, order.targetFactionId);
  final stalledOwExpansion = isStalledOldWorldExpansion(
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
  if (isTribeTarget &&
      stalledOwExpansion &&
      (minorsHoldOldWorldProvinces || activeMinorConflicts.isNotEmpty)) {
    return 0;
  }
  final hasAdjacentInvadableMinorOwner = adjacentOwners.any(
    (id) =>
        game.minorNations.any((m) => m.id == id) &&
        invadableOwners.contains(id),
  );
  if (stalledOwExpansion && isMinorTarget && !isTribeTarget) {
    final continuingMinorConflict =
        activeMinorConflicts.contains(order.targetFactionId);
    final adjacentInvadableMinor = isAdjacentOwner &&
        invadableOwners.contains(order.targetFactionId);
    final distantInvadableMinorOwner =
        invadableOwners.contains(order.targetFactionId);
    if (activeMinorConflicts.isNotEmpty) {
      if (!continuingMinorConflict) {
        return 0;
      }
    } else if (hasAdjacentInvadableMinorOwner) {
      if (!adjacentInvadableMinor) {
        return 0;
      }
    } else if (!adjacentInvadableMinor &&
        !weakerDistantMinor &&
        !distantInvadableMinorOwner) {
      return 0;
    }
  }
  if (behindVictoryPace &&
      adjacentOwners.isNotEmpty &&
      !isAdjacentOwner &&
      !isColonialAdjacentOwner &&
      !(ownsInvadableNw && isMinorTarget) &&
      !(stalledOwExpansion && ownsInvadableOwMinor) &&
      !weakerDistantMinor) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  final isAdjacentGp =
      isAdjacentOwner && game.playerById(order.targetFactionId) != null;
  final invadableGpBlockerWeaker = isAdjacentGp &&
      invadableOwners.contains(order.targetFactionId) &&
      provinceCountOwnedBy(game, order.targetFactionId) <=
          snapshot.conquest.oldWorldProvincesOwned;
  if (stalledOwExpansion && isAdjacentGp) {
    return 0;
  }
  final tribeOwnsOwInvadable = isTribeTarget &&
      snapshot.conquest.invadableProvinceIdsSorted.any(
        (pid) => provinceOwner[pid] == order.targetFactionId,
      );
  if (stalledOwExpansion &&
      isTribeTarget &&
      !tribeOwnsOwInvadable &&
      !(colonialPressure && ownsInvadableNw) &&
      (behindVictoryPace || hasInvadableMinorOwner || atWarInvadableOwMinor)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (suppressGpDeclareWar &&
      isAdjacentGp &&
      !(stalledOwExpansion && invadableGpBlockerWeaker)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (suppressGpDeclareWar &&
      isAdjacentGp &&
      stalledOwExpansion &&
      behindVictoryPace &&
      hasInvadableMinorOwner &&
      !invadableGpBlockerWeaker &&
      thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  final effectiveMaxRelation = behindVictoryPace && isMinorTarget
      ? kDeclareWarMinorMaxRelationWhenFarFromVictory
      : behindVictoryPace && isAdjacentGp
      ? kDeclareWarGpMaxRelationWhenFarFromVictory
      : maxRelationForDeclareWar;
  if (relationScore > effectiveMaxRelation) {
    return 0;
  }
  if (_isDecisionOnCooldown(
    game: game,
    actorFactionId: nationId,
    targetFactionId: order.targetFactionId,
    eventTypes: const [DiplomaticEventType.declareWar],
    cooldownTurns: warCooldownTurns,
    currentTurn: currentTurn,
  )) {
    return 0;
  }
  var s = 50;
  final warDesire = warDesireForTarget(order.targetFactionId, relationScore);
  final targetProvinceCount = provinceCountOwnedBy(game, order.targetFactionId);
  final desiredTerritory = targetProvinceCount <= 0
      ? 1
      : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
  s += getAgendaConquerModifier(agendaId);
  s += getAgendaTreatyBreakingModifier(agendaId);
  s += (thresholds.warLikelihood - 50);
  s += (warDesire - 50);
  if (!suppressGpDeclareWar &&
      snapshot.opportunities.weakNeighbors.contains(order.targetFactionId)) {
    s += getDeclareWarTargetBonusWeakerNeighbor(agendaId);
    if (game.playerById(order.targetFactionId) != null &&
        warDesire >= kDeclareWarGpWeakNeighborMinWarDesire) {
      s += kDeclareWarGpWeakNeighborBonus;
    }
  }
  if (snapshot.conquest.preferredConquestTargetFactionIdsSorted
      .contains(order.targetFactionId)) {
    s += 15;
  }
  if (ownsInvadableNw && isMinorTarget && !stalledOwExpansion) {
    s += kDeclareWarColonialInvadableOwnerBonus;
  }
  if (colonialPressure && ownsInvadableNw && isTribeTarget) {
    s += kDeclareWarColonialNwTribeDominanceBonus;
    if (stalledOwExpansion &&
        !hasInvadableMinorOwner &&
        !atWarInvadableOwMinor) {
      s += kDeclareWarColonialNwTribePriorityOverOwMinorBonus;
    }
  }
  final stalledOldWorldExpansion =
      snapshot.conquest.oldWorldProvincesOwned <=
      kStalledOldWorldProvinceThreshold;
  final hasInvadableOldWorld =
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (stalledOldWorldExpansion && hasInvadableOldWorld) {
    if (isMinorTarget &&
        !isTribeTarget &&
        isAdjacentOwner &&
        invadableOwners.contains(order.targetFactionId)) {
      s += kDeclareWarStalledOwMinorPriorityBonus;
      if (thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
        s += kDeclareWarLowWarLikelihoodAdjacentBonus;
      }
    }
    if (isTribeTarget && !ownsInvadableNw) {
      s -= kDeclareWarStalledExpansionTribePenalty;
    }
  }
  if (currentTurn <= kDeclareWarEarlyExpansionMaxTurn &&
      anyMinorOwnsOldWorld &&
      stalledOldWorldExpansion &&
      hasInvadableOldWorld) {
    if (isMinorTarget &&
        !isTribeTarget &&
        isAdjacentOwner &&
        invadableOwners.contains(order.targetFactionId)) {
      s += kDeclareWarEarlyExpansionMinorBonus;
    }
    if (isTribeTarget && !ownsInvadableNw) {
      s -= kDeclareWarEarlyExpansionTribePenalty;
    }
  }
  if (colonialPressure &&
      isMinorTarget &&
      !isTribeTarget &&
      !ownsInvadableNw) {
    s -= kDeclareWarColonialPressureOwMinorPenalty;
    if (stalledOwExpansion && ownsInvadableOwMinor) {
      s -= kDeclareWarColonialPressureOwMinorPenalty;
    }
  }
  if (isColonialAdjacentOwner && isTribeTarget) {
    s += kDeclareWarColonialAdjacentTribeBonus;
  }
  if (isAdjacentOwner) {
    s += kDeclareWarAdjacentOwnerBonus;
    if (behindVictoryPace && isMinorTarget) {
      s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    }
    if (isMinorTarget && invadableOwners.contains(order.targetFactionId)) {
      s += kDeclareWarMinorWithInvadableProvinceBonus;
    }
    if (isMinorTarget && stalledOwExpansion) {
      s += kDeclareWarStalledExpansionMinorBonus;
    }
    if (stalledOwExpansion &&
        isMinorTarget &&
        !isTribeTarget &&
        isAdjacentOwner &&
        invadableOwners.contains(order.targetFactionId) &&
        thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarStalledLowWarLikelihoodMinorBonus;
    }
    if (isMinorTarget &&
        snapshot.conquest.oldWorldProvincesOwned >=
            kDeclareWarSatedExpansionMinorThreshold) {
      s -= kDeclareWarSatedExpansionMinorPenalty;
    }
    if (!suppressGpDeclareWar && behindVictoryPace && isAdjacentGp) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
    if (thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (!isAdjacentOwner && stalledOwExpansion && ownsInvadableOwMinor) {
    s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    s += kDeclareWarMinorWithInvadableProvinceBonus;
    s += kDeclareWarStalledExpansionMinorBonus;
    if (thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (stalledOwExpansion && isMinorTarget && !isTribeTarget) {
    final targetMinorProvinces = provinceCountOwnedBy(game, order.targetFactionId);
    if (targetMinorProvinces > 0 &&
        targetMinorProvinces < snapshot.conquest.oldWorldProvincesOwned) {
      s += kDeclareWarStalledWeakerMinorBonus;
    }
    if (behindVictoryPace && targetMinorProvinces > 0) {
      s += kDeclareWarStalledActiveOwMinorBonus;
    }
  }
  if (weakerDistantMinor && activeMinorConflicts.isEmpty) {
    s += kDeclareWarStalledWeakerMinorBonus;
    s += kDeclareWarStalledActiveOwMinorBonus;
  }
  if (stalledOwExpansion && invadableGpBlockerWeaker) {
    s += kDeclareWarStalledWeakestInvadableGpBonus;
    if (behindVictoryPace) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
  }
  if (suppressGpDeclareWar &&
      isAdjacentGp &&
      stalledOwExpansion &&
      behindVictoryPace &&
      hasInvadableMinorOwner &&
      !invadableGpBlockerWeaker) {
    s -= kDeclareWarStalledGpWhenMinorsRemainPenalty;
  }
  if (primaryGoal == StrategicGoal.conquer) {
    s += 20;
  }
  s += behindVictoryPace
      ? conquerScoreBonusForProvincesToVictory(
          snapshot.conquest.provincesToVictory,
        )
      : conquerScoreBonusForProvincesToVictory(
              snapshot.conquest.provincesToVictory,
            ) ~/
          4;
  if (rel?.level == RelationLevel.allied) {
    s += getDeclareWarTargetBonusAlly(agendaId);
  }
  final adjacentWeakMinor = isMinorTarget &&
      !isTribeTarget &&
      isAdjacentOwner &&
      snapshot.opportunities.weakNeighbors.contains(order.targetFactionId);
  if (stalledOwExpansion &&
      isMinorTarget &&
      !isTribeTarget &&
      isAdjacentOwner &&
      invadableOwners.contains(order.targetFactionId)) {
    s = math.max(s, kDeclareWarStalledAdjacentInvadableMinorFloor);
  }
  if (stalledOwExpansion &&
      behindVictoryPace &&
      adjacentWeakMinor &&
      (invadableOwners.contains(order.targetFactionId) ||
          game.minorNations.any((m) => m.id == order.targetFactionId))) {
    s = math.max(s, kDeclareWarStalledAdjacentInvadableMinorFloor);
  }
  if (stalledOwExpansion && isTribeTarget && hasInvadableMinorOwner) {
    s = math.min(s, kDeclareWarStalledTribeWhenOwMinorCap);
  }
  if (stalledOwExpansion &&
      behindVictoryPace &&
      isTribeTarget &&
      thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold &&
      invadableOwners.any((id) => game.minorNations.any((m) => m.id == id))) {
    s = math.min(s, kDeclareWarStalledLowWarLikelihoodTribeCap);
  }
  if (stalledOwExpansion &&
      behindVictoryPace &&
      isMinorTarget &&
      !isTribeTarget &&
      isAdjacentOwner &&
      invadableOwners.contains(order.targetFactionId) &&
      thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
    s = math.max(s, kDeclareWarStalledLowWarLikelihoodMinorFloor);
  }
  _log.d(
    'diplomacy warDesire nationId=$nationId targetFactionId=${order.targetFactionId} '
    'warDesire=$warDesire desiredTerritory=$desiredTerritory',
  );
  return s;
}

bool _isMinorOrTribeFaction(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
}

bool _isTribeFaction(Game game, String factionId) {
  return game.tribes.any((t) => t.id == factionId);
}

Set<String> _activeOldWorldMinorConflictIds({
  required Game game,
  required String nationId,
  required int currentTurn,
  required int warCooldownTurns,
}) {
  final conflicts = <String>{};
  for (final minor in game.minorNations) {
    final rel = getRelation(game, nationId, minor.id);
    if (rel?.state == RelationState.atWar) {
      conflicts.add(minor.id);
      continue;
    }
    if (_isDecisionOnCooldown(
      game: game,
      actorFactionId: nationId,
      targetFactionId: minor.id,
      eventTypes: const [DiplomaticEventType.declareWar],
      cooldownTurns: warCooldownTurns,
      currentTurn: currentTurn,
    )) {
      conflicts.add(minor.id);
    }
  }
  return conflicts;
}

bool _isDecisionOnCooldown({
  required Game game,
  required String actorFactionId,
  required String targetFactionId,
  required List<DiplomaticEventType> eventTypes,
  required int cooldownTurns,
  required int currentTurn,
}) {
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (!eventTypes.contains(event.type)) continue;
    if (event.fromFactionId != actorFactionId) continue;
    if (event.toFactionId != targetFactionId) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}
