import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'ai_random_utils.dart';
import 'diplomacy_planner.dart';
import 'goal_manager.dart';
import 'hidden_agenda.dart';
import 'orders_extensions.dart';
import 'perception.dart';

final _log = packageLogger();

// Domain planners (utility AI). SPEC/ai/ai-architecture.md, ai-systems-impl.md, economy-planner.md.

/// Runs economy, military, diplomacy, and research planners; returns combined orders
/// for [nationId]. Uses [suggestionAPI] and [economyPlan] (cargo preference) to score
/// build candidates. Deterministic given seeds.
///
/// When [onStagedPlannerProgress] is set, emits coarse phase ids aligned with
/// staged planners A–G (Refs #2277): `suggestionPools`, `aiStageA` … `aiStageG`.
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
  void Function(String phaseId)? onStagedPlannerProgress,
}) {
  void emit(String phaseId) => onStagedPlannerProgress?.call(phaseId);

  var orders = const Orders();
  final domainWeights = getDomainWeightsForLeader(config.personalityId);

  // Economy: build/work suggestions weighted by economy domain.
  emit('suggestionPools');
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
    (o) =>
        o.target == kWorkTargetStealTech || o.target == kWorkTargetCounterSpy,
  );
  final workThreshold =
      40 - (hasSpyWork ? getAgendaSpyOrderModifier(config.hiddenAgendaId) : 0);
  final runFullAiCivilianWork =
      primaryGoal == StrategicGoal.expand ||
      domainWeights.economy >= workThreshold;
  _log.d(
    'work eval nationId=$nationId workThreshold=$workThreshold '
    'domainWeights.economy=${domainWeights.economy} primaryGoal=$primaryGoal '
    'workCandidates=${workCandidates.map((o) => "${o.unitId}:${o.target}").toList()}',
  );
  if (runFullAiCivilianWork) {
    final selection = selectFullAiCivilianWorkOrders(
      workSuggestions: workCandidates,
      view: view,
      game: game,
      tileMapByRegion: tileMapByRegion,
    );
    for (final w in selection.workOrders) {
      final unitType = view.ownUnitsById[w.unitId]?.type ?? 'unknown';
      _log.i(
        'civilian_work_assigned nationId=$nationId unitId=${w.unitId} '
        'unitType=$unitType target=${w.target} targetTileKey=${w.targetTileKey}',
      );
    }
    for (final idle in selection.idleEvents) {
      _log.i(
        'civilian_work_idle nationId=$nationId unitId=${idle.unitId} '
        'unitType=${idle.unitType} reason=${idle.reason}',
      );
    }
    if (selection.workOrders.isNotEmpty) {
      orders = orders.appendWorkOrders(nationId, selection.workOrders);
    }
  } else if (workCandidates.isNotEmpty) {
    _log.d('work skipped nationId=$nationId weight below threshold');
  }
  emit('aiStageA');
  final buildThreshold =
      30 - getAgendaBuildOrderModifier(config.hiddenAgendaId);
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
      orders = orders.appendBuildOrders(nationId, [chosen]);
    }
  } else if (buildCandidates.isNotEmpty) {
    _log.d('build skipped nationId=$nationId weight below threshold');
  }
  emit('aiStageB');

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
  emit('aiStageC');

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
  emit('aiStageD');

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
  emit('aiStageE');

  // Diplomacy: suggest diplomatic orders; weight by diplomacy domain and goal.
  orders = runDiplomacyPlanner(
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
  emit('aiStageF');

  // Research: suggest research; weight by tech domain, agenda (tech_thief boost), and personality research preference.
  final researchCandidates = suggestionAPI.suggestResearchOrders(
    view,
    game,
    topology,
    orders,
  );
  final researchThreshold =
      40 - getAgendaResearchModifier(config.hiddenAgendaId);
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
    final idx = pickWeightedIndex(scores, seeds.researchSeed, useIntRoll: true);
    if (idx == null) {
      emit('aiStageG');
      return orders;
    }
    final chosen = researchCandidates[idx];
    _log.i(
      'research chosen nationId=$nationId techId=${chosen.techId} score=${scores[idx]}',
    );
    orders = orders.appendResearchOrders(nationId, [chosen]);
  } else if (researchCandidates.isNotEmpty) {
    _log.d(
      'research skipped nationId=$nationId threshold not met or no candidates',
    );
  }
  emit('aiStageG');

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
    'candidates=${filtered.map((m) => "${m.unitId}->${m.destinationTileKey}").toList()}',
  );
  if (weight < 20) {
    _log.d('move skipped nationId=$nationId weight < 20');
    return orders;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final scores = filtered.map((m) {
    final destProv = Unit.provinceIdFromTileKey(m.destinationTileKey);
    final destOwner = destProv != null ? provinceOwner[destProv] : null;
    if (destOwner == null || destOwner == nationId) return 1.0;
    final rel = getRelation(game, nationId, destOwner);
    final atWar = rel != null && rel.atWar;
    return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
  }).toList();
  _log.d('move scores nationId=$nationId scores=$scores');
  final idx = pickWeightedIndex(scores, seeds.militarySeed);
  if (idx == null) return orders;
  final selected = [filtered[idx]];
  _log.i(
    'move chosen nationId=$nationId '
    'unitId=${selected.first.unitId} destinationTileKey=${selected.first.destinationTileKey}',
  );
  return orders.appendMoveOrders(nationId, selected);
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
  final idx = pickWeightedIndex(scores, seeds.militarySeed + 2000);
  if (idx == null) return orders;
  final selected = filtered[idx];
  _log.i(
    'army move chosen nationId=$nationId '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId}',
  );
  return applyArmyMoveOrderForPlayer(orders, nationId, selected);
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

  final idx = pickWeightedIndex(scores, seed);
  if (idx == null) return buildCandidates.first;
  return buildCandidates[idx];
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
      o = o.appendNavalMoveOrders(nationId, selected);
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
    o = o.appendNavalMissionOrders(nationId, [chosen]);
  }

  return o;
}
