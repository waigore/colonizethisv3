import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

import 'ai_config.dart';
import 'goal_manager.dart';
import 'hidden_agenda.dart';
import 'perception.dart';
import 'seed_bundle.dart';

// Domain planners (utility AI). SPEC/ai/ai-architecture.md, ai-systems-impl.md.

/// Runs economy, military, diplomacy, and research planners; returns combined orders
/// for [nationId]. Uses [suggestionAPI] and scores with [config] and [snapshot].
/// Deterministic given seeds.
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
}) {
  var orders = const Orders();
  final domainWeights = getDomainWeightsForLeader(config.leaderId);

  // Economy: build/work suggestions weighted by economy domain.
  final workCandidates = suggestionAPI.suggestWorkOrders(view, game, topology, orders);
  final buildCandidates = suggestionAPI.suggestBuildOrders(view, game, topology, orders);
  if (workCandidates.isNotEmpty && (primaryGoal == StrategicGoal.expand || domainWeights.economy >= 40)) {
    final rng = math.Random(seeds.economySeed);
    final idx = rng.nextInt(workCandidates.length);
    orders = _appendWorkOrders(orders, nationId, [workCandidates[idx]]);
  }
  final buildThreshold = 30 - agendaBuildOrderModifier(config.hiddenAgendaId);
  if (buildCandidates.isNotEmpty && domainWeights.economy >= buildThreshold) {
    final rng = math.Random(seeds.economySeed + 1);
    final idx = rng.nextInt(buildCandidates.length);
    orders = _appendBuildOrders(orders, nationId, [buildCandidates[idx]]);
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
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
  );

  // Research: suggest research; weight by tech domain and agenda (tech_thief boost).
  final researchCandidates = suggestionAPI.suggestResearchOrders(view, game, topology, orders);
  final researchThreshold = 40 - agendaResearchModifier(config.hiddenAgendaId);
  if (researchCandidates.isNotEmpty &&
      (primaryGoal == StrategicGoal.tech || domainWeights.research >= researchThreshold)) {
    final rng = math.Random(seeds.researchSeed);
    final idx = rng.nextInt(researchCandidates.length);
    orders = _appendResearchOrders(orders, nationId, [researchCandidates[idx]]);
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
  final moveCandidates = suggestionAPI.suggestMoveOrders(view, game, topology, orders);
  if (moveCandidates.isEmpty) return orders;
  final domainWeights = getDomainWeightsForLeader(config.leaderId);
  final weight = primaryGoal == StrategicGoal.conquer || primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
          ? domainWeights.economy
          : 50;
  if (weight < 20) return orders;
  final rng = math.Random(seeds.militarySeed);
  final cap = (moveCandidates.length.clamp(0, 5));
  final take = cap > 0 ? 1 + rng.nextInt(cap) : 0;
  if (take <= 0) return orders;
  final selected = moveCandidates.take(take).toList();
  return _appendMoveOrders(orders, nationId, selected);
}

Orders _appendMoveOrders(Orders o, String playerId, List<MoveOrder> list) {
  final existing = o.moveOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    moveOrdersByPlayerId: {...o.moveOrdersByPlayerId, playerId: [...existing, ...list]},
  );
}

Orders _appendBuildOrders(Orders o, String playerId, List<BuildUnitOrder> list) {
  final existing = o.buildUnitOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    buildUnitOrdersByPlayerId: {...o.buildUnitOrdersByPlayerId, playerId: [...existing, ...list]},
  );
}

Orders _appendWorkOrders(Orders o, String playerId, List<WorkOrder> list) {
  final existing = o.workOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    workOrdersByPlayerId: {...o.workOrdersByPlayerId, playerId: [...existing, ...list]},
  );
}

Orders _appendResearchOrders(Orders o, String playerId, List<ResearchOrder> list) {
  final existing = o.researchOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    researchOrdersByPlayerId: {...o.researchOrdersByPlayerId, playerId: [...existing, ...list]},
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
  final domainWeights = getDomainWeightsForLeader(config.leaderId);
  final weight = primaryGoal == StrategicGoal.conquer ||
      primaryGoal == StrategicGoal.defend ||
      primaryGoal == StrategicGoal.expand
      ? domainWeights.military
      : 40;
  if (weight < 25) return orders;

  var o = orders;

  final navalMoveCandidates = suggestionAPI.suggestNavalMoveOrders(view, game, topology, o);
  if (navalMoveCandidates.isNotEmpty) {
    final rng = math.Random(seeds.militarySeed + 1000);
    final cap = (navalMoveCandidates.length.clamp(0, 3));
    final take = cap > 0 ? 1 + rng.nextInt(cap) : 0;
    if (take > 0) {
      final selected = navalMoveCandidates.take(take).toList();
      o = _appendNavalMoveOrders(o, nationId, selected);
    }
  }

  final navalMissionCandidates = suggestionAPI.suggestNavalMissionOrders(view, game, topology, o);
  if (navalMissionCandidates.isNotEmpty) {
    final rng = math.Random(seeds.militarySeed + 1001);
    final idx = rng.nextInt(navalMissionCandidates.length);
    o = _appendNavalMissionOrders(o, nationId, [navalMissionCandidates[idx]]);
  }

  return o;
}

Orders _appendNavalMoveOrders(Orders o, String playerId, List<NavalMoveOrder> list) {
  final existing = o.navalMoveOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    navalMoveOrdersByPlayerId: {...o.navalMoveOrdersByPlayerId, playerId: [...existing, ...list]},
  );
}

Orders _appendNavalMissionOrders(Orders o, String playerId, List<NavalMissionOrder> list) {
  final existing = o.navalMissionOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    navalMissionOrdersByPlayerId: {...o.navalMissionOrdersByPlayerId, playerId: [...existing, ...list]},
  );
}

Orders _runDiplomacyPlanner({
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
  final domainWeights = getDomainWeightsForLeader(config.leaderId);
  final weight = primaryGoal == StrategicGoal.diplomacy ||
      primaryGoal == StrategicGoal.conquer ||
      primaryGoal == StrategicGoal.trade
      ? domainWeights.diplomacy
      : 40;
  if (weight < 25) return orders;

  final diploCandidates = suggestionAPI.suggestDiplomaticOrders(view, game, topology, orders);
  if (diploCandidates.isEmpty) return orders;

  final rng = math.Random(seeds.diplomacySeed);
  final idx = rng.nextInt(diploCandidates.length);
  return _appendDiplomaticOrders(orders, nationId, [diploCandidates[idx]]);
}

Orders _appendDiplomaticOrders(Orders o, String playerId, List<DiplomaticOrder> list) {
  final existing = o.diplomaticOrdersByPlayerId[playerId] ?? const [];
  return o.copyWith(
    diplomaticOrdersByPlayerId: {...o.diplomaticOrdersByPlayerId, playerId: [...existing, ...list]},
  );
}
