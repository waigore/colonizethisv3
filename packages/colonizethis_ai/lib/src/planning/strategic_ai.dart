import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show PlayerView, TurnTraceAiSection, buildPlayerView;
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_conquest_prep.dart';
import 'domain_planner_orchestrator.dart';
import 'economy_planner.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_goal_filter.dart';
import 'ai_order_reporting.dart';
import 'ai_trace_builder.dart';
import '../perception/perception_snapshot.dart';
import '../social/strategic_dialogue_emission.dart';

final _log = packageLogger();

/// Strategic order generation for full AI. SPEC/program/ai-systems-impl.md.
///
/// Returns valid [Orders] and [EconomyPlan] for [nationId] for the current turn
/// using [view] as the only source of visibility. Optionally emits dialogue and mood via callbacks.
StrategicOrderResult generateStrategicOrders({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
}) {
  return generateStrategicOrdersWithTrace(
    game: game,
    topology: topology,
    nationId: nationId,
    view: view,
    config: config,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onMood: onMood,
  ).result;
}

class StrategicOrderTraceResult {
  const StrategicOrderTraceResult({
    required this.result,
    required this.game,
    this.aiTraceSection,
  });

  final StrategicOrderResult result;

  /// [Game] after any in-turn army prep (e.g. Home Army split for conquest).
  final Game game;
  final TurnTraceAiSection? aiTraceSection;
}

StrategicOrderTraceResult generateStrategicOrdersWithTrace({
  required Game game,
  required MapTopology topology,
  required String nationId,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(DialogueEvent)? onDialogue,
  void Function(PortraitMoodEvent)? onMood,
  void Function(String phaseId)? onStagedPlannerProgress,
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  final turn = game.worldState.turnState.turnNumber;
  _log.i('generateStrategicOrders nationId=$nationId turn=$turn');
  final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
  final observerGoalPhase = observerGoalPhaseFor(
    snapshot: snapshot,
    game: game,
  );
  final suppressColonialPressure = resolvePhaseGoalSuppressColonialPressure(
    observerGoalPhase,
  );
  final goalScores = evaluateStrategicGoalScores(
    snapshot,
    config,
    observerGoalPhase: observerGoalPhase,
  );
  var primaryGoal = selectPrimaryGoal(
    snapshot,
    config,
    seeds.goalSeed,
    nationId: nationId,
    turn: turn,
    observerGoalPhase: observerGoalPhase,
  );
  if (suppressColonialPressure &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold) {
    primaryGoal = StrategicGoal.conquer;
  }
  _log.d('primaryGoal=$primaryGoal');
  final planningGame = prepareConquestFieldArmy(
    game: game,
    nationId: nationId,
    provincesToVictory: snapshot.conquest.provincesToVictory,
    oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
    primaryGoal: primaryGoal,
  );
  final planningView = planningGame == game
      ? view
      : buildPlayerView(planningGame, topology, nationId);
  final planningSnapshot = planningView == view
      ? snapshot
      : AIWorldSnapshot.fromPlayerView(planningView, topology: topology);
  // Refs #2509 S5: dispatch the phase plan once per AI player turn against
  // the planning-state inputs and thread the resolved `PhasePlanOutcome`
  // into both `runEconomyPlanner` and the orchestrator. The dispatch is
  // hoisted *above* `runEconomyPlanner` so the economy planner can derive
  // the EXPAND below-quota peace treasury-recovery cargo boost via the
  // phase-planner economy resolvers
  // (`resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive`
  // and `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`)
  // instead of recomputing `isBelowQuotaPeaceTreasuryRecovery` from
  // `colonial_pressure.dart`. The orchestrator continues to consume the
  // same plan so the dispatch runs exactly once per AI player turn against
  // the same `(planningGame, planningSnapshot, personalityId)` inputs.
  final phasePlan = runPhasePlanners(
    game: planningGame,
    snapshot: planningSnapshot,
    personalityId: config.personalityId,
  );
  final economyPlan = runEconomyPlanner(
    game: planningGame,
    view: planningView,
    config: config,
    seeds: seeds,
    colonial: snapshot.colonial,
    snapshot: planningSnapshot,
    phasePlan: phasePlan,
  );
  final plannerOutcome = runDomainPlannersWithOutcome(
    game: planningGame,
    topology: topology,
    nationId: nationId,
    view: planningView,
    snapshot: planningSnapshot,
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    onStagedPlannerProgress: onStagedPlannerProgress,
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
    phasePlan: phasePlan,
  );
  final orders = plannerOutcome.orders;
  final moveCount = orders.moveOrdersByPlayerId[nationId]?.length ?? 0;
  final armyMoveCount = orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  final buildCount = orders.buildUnitOrdersByPlayerId[nationId]?.length ?? 0;
  final workCount = orders.workOrdersByPlayerId[nationId]?.length ?? 0;
  final researchCount = orders.researchOrdersByPlayerId[nationId]?.length ?? 0;
  _log.i(
    'generated orders nationId=$nationId move=$moveCount armyMove=$armyMoveCount build=$buildCount work=$workCount research=$researchCount',
  );
  emitStrategicDialogueAndMood(
    config: config,
    seeds: seeds,
    onDialogue: onDialogue,
    onMood: onMood,
  );
  final result = StrategicOrderResult(orders: orders, economyPlan: economyPlan);
  final ordersByDomain = orderCountsByDomain(nationId, orders);
  final finalOrders = finalAggregatedOrders(nationId, orders);
  return StrategicOrderTraceResult(
    result: result,
    game: planningGame,
    aiTraceSection: buildAiTraceSection(
      nationId: nationId,
      turn: turn,
      config: config,
      seeds: seeds,
      snapshot: snapshot,
      primaryGoal: primaryGoal,
      goalScores: goalScores,
      economyPlan: economyPlan,
      orders: orders,
      ordersByDomain: ordersByDomain,
      finalOrders: finalOrders,
      declaredWarTargetFactionId: plannerOutcome.declaredWarTargetFactionId,
      conquestArmyMoveCount: plannerOutcome.conquestArmyMoveCount,
    ),
  );
}
