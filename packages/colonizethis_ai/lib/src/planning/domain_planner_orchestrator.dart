import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/orders_extensions.dart';
import 'build_planner.dart';
import 'conquest_planner.dart';
import 'diplomacy_planner.dart';
import 'domain_planner_outcome.dart';
import 'move_planner.dart';
import 'naval_planner.dart';
import 'research_planner.dart';

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
  return runDomainPlannersWithOutcome(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    onStagedPlannerProgress: onStagedPlannerProgress,
  ).orders;
}

DomainPlannerOutcome runDomainPlannersWithOutcome({
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
  orders = _runEconomyDomainPlanners(
    orders: orders,
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    snapshot: snapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    emit: emit,
  );

  // Movement: suggest moves; weight by military/expand.
  orders = runMovePlanner(
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
  emit('aiStageC');

  // Military: declare war before invasion army moves (SPEC/ai/ai-architecture.md).
  final declareWarResult = runDiplomacyPlannerWithResult(
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
    pass: DiplomacyPlannerPass.declareWarOnly,
  );
  orders = declareWarResult.orders;
  final armyMovesBeforeConquest =
      orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  orders = runConquestArmyMovePlanner(
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
    declaredWarTargetFactionId: declareWarResult.declaredWarTargetFactionId,
  );
  final conquestArmyMoveCount =
      (orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0) -
      armyMovesBeforeConquest;
  orders = runArmyMovePlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    provincesToVictory: snapshot.conquest.provincesToVictory,
  );
  emit('aiStageD');

  // Naval: suggest naval moves and missions; weight by military/expand.
  orders = runNavalPlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    colonial: snapshot.colonial,
  );
  emit('aiStageE');

  // Diplomacy follow-up (peace, alliance, overture — no duplicate declare war).
  orders = runDiplomacyPlannerWithResult(
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
    pass: DiplomacyPlannerPass.nonDeclareWarOnly,
  ).orders;
  emit('aiStageF');

  orders = runResearchPlanner(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: orders,
    config: config,
    primaryGoal: primaryGoal,
    suggestionAPI: suggestionAPI,
    researchSeed: seeds.researchSeed,
  );
  emit('aiStageG');

  return DomainPlannerOutcome(
    orders: orders,
    declaredWarTargetFactionId: declareWarResult.declaredWarTargetFactionId,
    conquestArmyMoveCount: conquestArmyMoveCount,
  );
}

Orders _runEconomyDomainPlanners({
  required Orders orders,
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  required EconomyPlan economyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
  required void Function(String phaseId) emit,
}) {
  var result = orders;
  final domainWeights = getDomainWeightsForLeader(config.personalityId);

  emit('suggestionPools');
  final workCandidates = suggestionAPI.suggestWorkOrders(
    view,
    game,
    topology,
    result,
    tileMapByRegion: tileMapByRegion,
  );
  final buildCandidates = suggestionAPI.suggestBuildOrders(
    view,
    game,
    topology,
    result,
  );
  final hasSpyWork = workCandidates.any(
    (o) =>
        o.target == kWorkTargetStealTech || o.target == kWorkTargetCounterSpy,
  );
  final workThreshold =
      40 - (hasSpyWork ? getAgendaSpyOrderModifier(config.hiddenAgendaId) : 0);
  final runFullAiCivilianWork =
      primaryGoal == StrategicGoal.expand ||
      domainWeights.economy >= workThreshold ||
      snapshot.colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
      snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty ||
      snapshot.colonial.newWorldProvincesOwned > 0;
  _log.d(
    'work eval nationId=$nationId workThreshold=$workThreshold '
    'domainWeights.economy=${domainWeights.economy} primaryGoal=$primaryGoal '
    'workCandidatesCount=${workCandidates.length}',
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
      result = result.appendWorkOrders(nationId, selection.workOrders);
    }
  } else if (workCandidates.isNotEmpty) {
    _log.d('work skipped nationId=$nationId weight below threshold');
  }
  emit('aiStageA');

  var buildThreshold = 30 - getAgendaBuildOrderModifier(config.hiddenAgendaId);
  if (snapshot.conquest.oldWorldProvincesOwned <=
      kStalledOldWorldProvinceThreshold) {
    buildThreshold = math.min(buildThreshold, 15);
  }
  _log.d(
    'build eval nationId=$nationId buildThreshold=$buildThreshold '
    'buildCandidatesCount=${buildCandidates.length}',
  );
  if (buildCandidates.isNotEmpty && domainWeights.economy >= buildThreshold) {
    final chosen = pickBuildOrder(
      buildCandidates: buildCandidates,
      cargoPreference: economyPlan.cargoPreference,
      primaryGoal: primaryGoal,
      config: config,
      seed: seeds.economySeed + 1,
      nationId: nationId,
      provincesToVictory: snapshot.conquest.provincesToVictory,
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
    );
    if (chosen != null) {
      _log.i('build chosen nationId=$nationId unitType=${chosen.unitType}');
      result = result.appendBuildOrders(nationId, [chosen]);
    }
  } else if (buildCandidates.isNotEmpty) {
    _log.d('build skipped nationId=$nationId weight below threshold');
  }
  emit('aiStageB');
  return result;
}
