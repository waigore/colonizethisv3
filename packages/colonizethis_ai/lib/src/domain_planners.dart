import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'goal_manager.dart';
import 'hidden_agenda.dart';
import 'perception.dart';

final _log = packageLogger();

// Domain planners (utility AI). SPEC/ai/ai-architecture.md, ai-systems-impl.md, economy-planner.md.

/// Runs economy, military, diplomacy, and research planners; returns combined orders
/// for [nationId]. Uses [suggestionAPI] and [economyPlan] (cargo preference) to score
/// build candidates. Deterministic given seeds.
Orders runDomainPlanners({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  required EconomyPlan economyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  var orders = const Orders();
  final domainWeights = getDomainWeightsForLeader(config.personalityId);

  // Economy: build/work suggestions weighted by economy domain.
  final workCandidates = suggestionAPI.suggestWorkOrders(
    view,
    game,
    topology,
    orders,
    tileMapByRegion: tileMapByRegion,
  );
  final buildCandidates = suggestionAPI.suggestBuildOrders(
    view,
    game,
    topology,
    orders,
  );
  final hasSpyWork = workCandidates.any(
    (o) => o.target == 'steal_tech' || o.target == 'counter_spy',
  );
  final workThreshold =
      40 - (hasSpyWork ? agendaSpyOrderModifier(config.hiddenAgendaId) : 0);
  _log.d(
    'work eval nationId=$nationId workThreshold=$workThreshold '
    'domainWeights.economy=${domainWeights.economy} primaryGoal=$primaryGoal '
    'workCandidates=${workCandidates.map((o) => "${o.unitId}:${o.target}").toList()}',
  );
  if (workCandidates.isNotEmpty &&
      (primaryGoal == StrategicGoal.expand ||
          domainWeights.economy >= workThreshold)) {
    final agendaId = config.hiddenAgendaId;
    final pickFrom = (agendaId == 'tech_thief' && hasSpyWork)
        ? workCandidates
              .where(
                (o) => o.target == 'steal_tech' || o.target == 'counter_spy',
              )
              .toList()
        : workCandidates;
    final list = pickFrom.isNotEmpty ? pickFrom : workCandidates;
    final rng = math.Random(seeds.economySeed);
    final idx = rng.nextInt(list.length);
    final chosen = list[idx];
    _log.i(
      'work chosen nationId=$nationId unitId=${chosen.unitId} target=${chosen.target}',
    );
    orders = _appendWorkOrders(orders, nationId, [chosen]);
  } else if (workCandidates.isNotEmpty) {
    _log.d('work skipped nationId=$nationId weight below threshold');
  }
  final buildThreshold = 30 - agendaBuildOrderModifier(config.hiddenAgendaId);
  _log.d(
    'build eval nationId=$nationId buildThreshold=$buildThreshold '
    'buildCandidates=${buildCandidates.map((o) => o.unitType).toList()}',
  );
  if (buildCandidates.isNotEmpty && domainWeights.economy >= buildThreshold) {
    final chosen = _pickBuildOrder(
      buildCandidates: buildCandidates,
      cargoPreference: economyPlan.cargoPreference,
      primaryGoal: primaryGoal,
      config: config,
      seed: seeds.economySeed + 1,
      nationId: nationId,
    );
    if (chosen != null) {
      _log.i('build chosen nationId=$nationId unitType=${chosen.unitType}');
      orders = _appendBuildOrders(orders, nationId, [chosen]);
    }
  } else if (buildCandidates.isNotEmpty) {
    _log.d('build skipped nationId=$nationId weight below threshold');
  }

  // Movement: suggest moves; weight by military/expand.
  orders = _runMovePlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
  );

  orders = _runArmyMovePlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
  );

  // Naval: suggest naval moves and missions; weight by military/expand.
  orders = _runNavalPlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
  );

  // Diplomacy: suggest diplomatic orders; weight by diplomacy domain and goal.
  orders = _runDiplomacyPlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
  );

  // Research: suggest research; weight by tech domain, agenda (tech_thief boost), and personality research preference.
  final researchCandidates = suggestionAPI.suggestResearchOrders(
    view,
    game,
    topology,
    orders,
  );
  final researchThreshold = 40 - agendaResearchModifier(config.hiddenAgendaId);
  if (researchCandidates.isNotEmpty &&
      (primaryGoal == StrategicGoal.tech ||
          domainWeights.research >= researchThreshold)) {
    final thresholds = getThresholdsForLeader(config.personalityId);
    final scores = researchCandidates.map((o) {
      final tech = techById(o.techId);
      final category = tech?.category ?? '';
      final w = category == 'transport'
          ? thresholds.researchNaval
          : category == 'military'
          ? thresholds.researchMilitary
          : category == 'gathering'
          ? thresholds.researchEconomic
          : thresholds.researchExploration;
      return math.max(1, w);
    }).toList();
    _log.d(
      'research eval nationId=$nationId researchThreshold=$researchThreshold '
      'candidates=${researchCandidates.map((o) => o.techId).toList()} scores=$scores',
    );
    final total = scores.reduce((a, b) => a + b);
    final rng = math.Random(seeds.researchSeed);
    var r = rng.nextInt(total);
    var idx = 0;
    for (; idx < scores.length && r >= scores[idx]; idx++) {
      r -= scores[idx];
    }
    if (idx >= researchCandidates.length) idx = researchCandidates.length - 1;
    final chosen = researchCandidates[idx];
    _log.i(
      'research chosen nationId=$nationId techId=${chosen.techId} score=${scores[idx]}',
    );
    orders = _appendResearchOrders(orders, nationId, [chosen]);
  } else if (researchCandidates.isNotEmpty) {
    _log.d(
      'research skipped nationId=$nationId threshold not met or no candidates',
    );
  }

  return orders;
}

Orders _runMovePlanner({
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
}) {
  final moveCandidates = suggestionAPI.suggestMoveOrders(
    view,
    game,
    topology,
    orders,
  );
  if (moveCandidates.isEmpty) return orders;
  final filtered = filterMoveOrdersByDiplomacy(game, nationId, moveCandidates);
  if (filtered.isEmpty) return orders;
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
      ? domainWeights.economy
      : 50;
  _log.d(
    'move eval nationId=$nationId weight=$weight '
    'filteredCount=${filtered.length} '
    'candidates=${filtered.map((m) => "${m.unitId}->${m.destinationProvinceId}").toList()}',
  );
  if (weight < 20) {
    _log.d('move skipped nationId=$nationId weight < 20');
    return orders;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final scores = filtered.map((m) {
    final destOwner = provinceOwner[m.destinationProvinceId];
    if (destOwner == null || destOwner == nationId) return 1.0;
    final rel = getRelation(game, nationId, destOwner);
    final atWar = rel != null && rel.atWar;
    return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
  }).toList();
  _log.d('move scores nationId=$nationId scores=$scores');
  final total = scores.reduce((a, b) => a + b);
  if (total <= 0) return orders;
  final rng = math.Random(seeds.militarySeed);
  var r = rng.nextDouble() * total;
  var idx = 0;
  for (; idx < filtered.length && r > scores[idx]; idx++) {
    r -= scores[idx];
  }
  if (idx >= filtered.length) idx = filtered.length - 1;
  final selected = [filtered[idx]];
  _log.i(
    'move chosen nationId=$nationId '
    'unitId=${selected.first.unitId} destinationProvinceId=${selected.first.destinationProvinceId}',
  );
  return _appendMoveOrders(orders, nationId, selected);
}

Orders _runArmyMovePlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
}) {
  final armyMoveCandidates = suggestionAPI.suggestArmyMoveOrders(
    view,
    game,
    topology,
    orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('army move eval nationId=$nationId candidatesCount=0');
    return orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    game,
    nationId,
    armyMoveCandidates,
  );
  if (filtered.isEmpty) {
    _log.d('army move filtered empty nationId=$nationId');
    return orders;
  }
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
      ? domainWeights.economy
      : 50;
  if (weight < 20) {
    _log.d('army move skipped nationId=$nationId weight=$weight < 20');
    return orders;
  }
  _log.d(
    'army move eval nationId=$nationId weight=$weight '
    'filteredCount=${filtered.length} '
    'candidates=${filtered.map((m) => "${m.armyId}->${m.destinationProvinceId}").toList()}',
  );
  final provinceOwner = getProvinceOwnerMap(game);
  final scores = filtered.map((m) {
    final destOwner = provinceOwner[m.destinationProvinceId];
    if (destOwner == null || destOwner == nationId) return 1.0;
    final rel = getRelation(game, nationId, destOwner);
    final atWar = rel != null && rel.atWar;
    return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
  }).toList();
  final total = scores.reduce((a, b) => a + b);
  if (total <= 0) return orders;
  final rng = math.Random(seeds.militarySeed + 2000);
  var r = rng.nextDouble() * total;
  var idx = 0;
  for (; idx < filtered.length && r > scores[idx]; idx++) {
    r -= scores[idx];
  }
  if (idx >= filtered.length) idx = filtered.length - 1;
  final selected = filtered[idx];
  _log.i(
    'army move chosen nationId=$nationId '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId}',
  );
  return applyArmyMoveOrderForPlayer(orders, nationId, selected);
}

Orders _appendMoveOrders(Orders o, String playerId, List<MoveOrder> list) {
  final existing = o.moveOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    moveOrdersByPlayerId: {
      ...o.moveOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}

Orders _appendBuildOrders(
  Orders o,
  String playerId,
  List<BuildUnitOrder> list,
) {
  final existing = o.buildUnitOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    buildUnitOrdersByPlayerId: {
      ...o.buildUnitOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}

/// Scores build candidates (ships vs regiments) by cargo preference, goal, and personality.
/// Returns one build order via weighted random, or null if list empty. SPEC/ai/economy-planner.md.
BuildUnitOrder? _pickBuildOrder({
  required List<BuildUnitOrder> buildCandidates,
  required CargoPreference cargoPreference,
  required StrategicGoal primaryGoal,
  required AIConfig config,
  required int seed,
  required String nationId,
}) {
  if (buildCandidates.isEmpty) return null;
  final thresholds = getThresholdsForLeader(config.personalityId);
  final scores = buildCandidates.map((o) {
    final unitType = o.unitType;
    final isShip = ShipEconomyCatalog.byId.containsKey(unitType);
    final cargoHold = isShip ? NavalStatsCatalog.get(unitType).cargoHold : 0;
    final isRegiment = RegimentEconomyCatalog.byId.containsKey(unitType);

    double cargoBonus = 0.0;
    if (isShip && cargoHold > 0) {
      switch (cargoPreference) {
        case CargoPreference.strongCargo:
          cargoBonus = 2.0;
          break;
        case CargoPreference.preferCargo:
          cargoBonus = 1.0;
          break;
        case CargoPreference.none:
          break;
      }
    }

    double militaryBonus = 0.0;
    if (primaryGoal == StrategicGoal.conquer ||
        primaryGoal == StrategicGoal.defend) {
      if (isRegiment) {
        militaryBonus = 1.0;
      } else if (isShip && cargoHold == 0) {
        militaryBonus = 1.0;
      }
    }

    double personalityBonus = 0.0;
    if (isShip) {
      personalityBonus = thresholds.researchNaval / 100.0;
    } else if (isRegiment) {
      personalityBonus = thresholds.researchMilitary / 100.0;
    }

    return 1.0 + cargoBonus + militaryBonus + personalityBonus;
  }).toList();

  _log.d(
    'build scores nationId=$nationId '
    'candidates=${buildCandidates.map((o) => o.unitType).toList()} '
    'scores=$scores',
  );

  final total = scores.reduce((a, b) => a + b);
  if (total <= 0) return buildCandidates.first;
  final rng = math.Random(seed);
  var r = rng.nextDouble() * total;
  for (var idx = 0; idx < buildCandidates.length; idx++) {
    if (r < scores[idx]) return buildCandidates[idx];
    r -= scores[idx];
  }
  return buildCandidates.last;
}

Orders _appendWorkOrders(Orders o, String playerId, List<WorkOrder> list) {
  final existing = o.workOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    workOrdersByPlayerId: {
      ...o.workOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}

Orders _appendResearchOrders(
  Orders o,
  String playerId,
  List<ResearchOrder> list,
) {
  final existing = o.researchOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    researchOrdersByPlayerId: {
      ...o.researchOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}

Orders _runNavalPlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend ||
          primaryGoal == StrategicGoal.expand
      ? domainWeights.military
      : 40;
  if (weight < 25) {
    _log.d('naval skipped nationId=$nationId weight=$weight < 25');
    return orders;
  }

  var o = orders;

  final navalMoveCandidates = suggestionAPI.suggestNavalMoveOrders(
    view,
    game,
    topology,
    o,
  );
  _log.d(
    'naval move eval nationId=$nationId '
    'candidatesCount=${navalMoveCandidates.length}',
  );
  if (navalMoveCandidates.isNotEmpty) {
    final rng = math.Random(seeds.militarySeed + 1000);
    final cap = (navalMoveCandidates.length.clamp(0, 3));
    final take = cap > 0 ? 1 + rng.nextInt(cap) : 0;
    if (take > 0) {
      final selected = navalMoveCandidates.take(take).toList();
      _log.i(
        'naval move chosen nationId=$nationId '
        'take=$take selected=${selected.map((m) => "fleetId=${m.fleetId} destSea=${m.destinationSeaZoneId} destPort=${m.destinationPortProvinceId}").toList()}',
      );
      o = _appendNavalMoveOrders(o, nationId, selected);
    }
  }

  final navalMissionCandidates = suggestionAPI.suggestNavalMissionOrders(
    view,
    game,
    topology,
    o,
  );
  _log.d(
    'naval mission eval nationId=$nationId '
    'candidatesCount=${navalMissionCandidates.length}',
  );
  if (navalMissionCandidates.isNotEmpty) {
    final rng = math.Random(seeds.militarySeed + 1001);
    final idx = rng.nextInt(navalMissionCandidates.length);
    final chosen = navalMissionCandidates[idx];
    _log.i(
      'naval mission chosen nationId=$nationId '
      'mission=${chosen.mission} fleetId=${chosen.fleetId}',
    );
    o = _appendNavalMissionOrders(o, nationId, [chosen]);
  }

  return o;
}

Orders _appendNavalMoveOrders(
  Orders o,
  String playerId,
  List<NavalMoveOrder> list,
) {
  final existing = o.navalMoveOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    navalMoveOrdersByPlayerId: {
      ...o.navalMoveOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}

Orders _appendNavalMissionOrders(
  Orders o,
  String playerId,
  List<NavalMissionOrder> list,
) {
  final existing = o.navalMissionOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    navalMissionOrdersByPlayerId: {
      ...o.navalMissionOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}

Orders _runDiplomacyPlanner({
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
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.diplomacy ||
          primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.trade
      ? domainWeights.diplomacy
      : 40;
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=$nationId weight=$weight < 25');
    return orders;
  }

  final diploCandidates = suggestionAPI.suggestDiplomaticOrders(
    view,
    game,
    topology,
    orders,
  );
  if (diploCandidates.isEmpty) return orders;

  final scores = computeDiplomaticCandidateScores(
    candidates: diploCandidates,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
    config: config,
  );

  final candidateDesc = diploCandidates
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=$nationId hiddenAgendaId=${config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final total = scores.reduce((a, b) => a + b);
  if (total <= 0) return orders;
  final rng = math.Random(seeds.diplomacySeed);
  var r = rng.nextDouble() * total;
  var idx = 0;
  for (; idx < scores.length && r > scores[idx]; idx++) {
    r -= scores[idx];
  }
  if (idx >= diploCandidates.length) idx = diploCandidates.length - 1;
  final chosen = diploCandidates[idx];
  _log.i(
    'diplomacy chosen nationId=$nationId '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""} score=${scores[idx]}',
  );
  return _appendDiplomaticOrders(orders, nationId, [chosen]);
}

/// Pre–weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores({
  required List<DiplomaticOrder> candidates,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = getThresholdsForLeader(config.personalityId);
  final maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
  return candidates.map((o) {
    var s = 50;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = computeWarDesireScore(
            game: game,
            nationId: nationId,
            targetFactionId: o.targetFactionId,
            relationScore: rel?.score ?? 50,
          );
          // Lower peace desire when current war desire remains high.
          s -= (warDesire - 50);
        }
        s += agendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.peaceTendency - 50);
        break;
      case DiplomaticOrderType.alliance:
        s += agendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.declareWar:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final relationScore = rel?.score ?? 50;
          if (relationScore > maxRelationForDeclareWar) {
            s = 0;
          } else {
            if (_isDecisionOnCooldown(
              game: game,
              actorFactionId: nationId,
              targetFactionId: o.targetFactionId,
              eventTypes: const [DiplomaticEventType.declareWar],
              cooldownTurns: warCooldownTurns,
              currentTurn: currentTurn,
            )) {
              s = 0;
              break;
            }
            final warDesire = computeWarDesireScore(
              game: game,
              nationId: nationId,
              targetFactionId: o.targetFactionId,
              relationScore: relationScore,
            );
            final targetProvinceCount = provinceCountOwnedBy(
              game,
              o.targetFactionId,
            );
            final desiredTerritory = targetProvinceCount <= 0
                ? 1
                : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
            s += agendaConquerModifier(agendaId);
            s += agendaTreatyBreakingModifier(agendaId);
            s += (thresholds.warLikelihood - 50);
            s += (warDesire - 50);
            if (snapshot.opportunities.weakNeighbors.contains(
              o.targetFactionId,
            )) {
              s += getDeclareWarTargetBonusWeakerNeighbor(agendaId);
            }
            if (rel?.level == RelationLevel.allied) {
              s += getDeclareWarTargetBonusAlly(agendaId);
            }
            _log.d(
              'diplomacy warDesire nationId=$nationId targetFactionId=${o.targetFactionId} '
              'warDesire=$warDesire desiredTerritory=$desiredTerritory',
            );
          }
          break;
        }
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
          final warDesire = computeWarDesireScore(
            game: game,
            nationId: nationId,
            targetFactionId: o.targetFactionId,
            relationScore: rel?.score ?? 50,
          );
          final improveRelationsDesire = 100 - warDesire;
          s += (improveRelationsDesire - 50);
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

int computeWarDesireScore({
  required Game game,
  required String nationId,
  required String targetFactionId,
  required int relationScore,
}) {
  final attackerPower = greatPowerPowerScore(game, nationId);
  final targetPower = greatPowerPowerScore(game, targetFactionId);
  final targetPowerSafe = targetPower <= 0 ? 1 : targetPower;
  final strengthRatio = attackerPower / targetPowerSafe;
  var score = 50;

  // Power score already combines military + provinces + naval.
  if (strengthRatio >= 1.35) {
    score += 30;
  } else if (strengthRatio >= 0.85) {
    score += 5;
  } else {
    score -= 25;
  }

  // Keep relation as a hard strategic drag even before final relation gate.
  if (relationScore >= 70) {
    score -= 40;
  } else if (relationScore >= 50) {
    score -= 20;
  } else if (relationScore <= 25) {
    score += 10;
  }

  final targetIsMinorOrTribe =
      game.minorNations.any((m) => m.id == targetFactionId) ||
      game.tribes.any((t) => t.id == targetFactionId);
  if (targetIsMinorOrTribe) {
    score += _resourceNeedBonus(game, nationId, targetFactionId);
    score += _interventionRiskPenalty(game, nationId, targetFactionId);
    score += _invasionCapacityAdjustment(game, nationId, targetFactionId);
  }

  return score.clamp(0, 100);
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

int _resourceNeedBonus(Game game, String nationId, String targetFactionId) {
  final ownedResourceIds = <String>{};
  final player = game.playerById(nationId);
  if (player != null) {
    for (final entry in player.stockpile.quantities.entries) {
      if (entry.value > 0) ownedResourceIds.add(entry.key);
    }
  }
  final targetResourceIds = <String>{};
  final byRegion = game.worldState.tileKeysByRegionAndProvince;
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId != targetFactionId) continue;
    final tiles = byRegion[p.regionId]?[p.id] ?? const <String>[];
    for (final tileKey in tiles) {
      final resource = game.worldState.resourceByTileKey[tileKey];
      if (resource != null && resource.isNotEmpty)
        targetResourceIds.add(resource);
    }
  }
  final missing = targetResourceIds
      .where((id) => !ownedResourceIds.contains(id))
      .length;
  return (missing * 5).clamp(0, 15);
}

int _interventionRiskPenalty(
  Game game,
  String nationId,
  String targetFactionId,
) {
  var count = 0;
  for (final overture in game.overtureStates) {
    if (overture.targetId != targetFactionId) continue;
    if (overture.gpId == nationId) continue;
    if (!overture.hasEmbassy) continue;
    if (game.players.any((p) => p.id == overture.gpId)) count++;
  }
  return -(count * 8).clamp(0, 24);
}

int _invasionCapacityAdjustment(
  Game game,
  String nationId,
  String targetFactionId,
) {
  final ownRegiments = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == nationId).length;
  final targetRegiments = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == targetFactionId).length;
  var score = 0;
  if (ownRegiments < math.max(2, targetRegiments ~/ 2)) {
    score -= 20;
  } else if (ownRegiments > targetRegiments) {
    score += 10;
  }

  final ownRegionIds = allProvinces(
    game.worldState,
  ).where((p) => p.ownerId == nationId).map((p) => p.regionId).toSet();
  final targetRegionIds = allProvinces(
    game.worldState,
  ).where((p) => p.ownerId == targetFactionId).map((p) => p.regionId).toSet();
  final requiresOverseas = targetRegionIds.any(
    (id) => !ownRegionIds.contains(id),
  );
  if (requiresOverseas && shipCountForFaction(game, nationId) <= 0) {
    score -= 25;
  }

  final activeWars = game.diplomacyRelations.where((r) {
    final involvesNation = r.factionId1 == nationId || r.factionId2 == nationId;
    return involvesNation && r.state == RelationState.atWar;
  }).length;
  if (activeWars >= 2) score -= 15;
  return score;
}

Orders _appendDiplomaticOrders(
  Orders o,
  String playerId,
  List<DiplomaticOrder> list,
) {
  final existing = o.diplomaticOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    diplomaticOrdersByPlayerId: {
      ...o.diplomaticOrdersByPlayerId,
      playerId: [...existing, ...list],
    },
  );
}
