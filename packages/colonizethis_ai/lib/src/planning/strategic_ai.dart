import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        PlayerView,
        TurnTraceAiSection,
        cargoHoldsForHomeFleet,
        computeExtractionTotalsForTradeForecast;
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_orchestrator.dart';
import 'economy_planner.dart';
import 'orchestrator_options.dart';
import 'strategic_ai_goal_prep.dart';
import 'strategic_planning_input.dart';
import 'phase_planner_dispatch.dart';
import 'ai_order_reporting.dart';
import 'ai_trace_builder.dart';
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
    StrategicPlanningInput(
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
    ),
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

StrategicOrderTraceResult generateStrategicOrdersWithTrace(
  StrategicPlanningInput input,
) {
  final prep = prepareStrategicAiGoalAndArmy(input);
  final turn = prep.turn;
  _log.i('generateStrategicOrders nationId=${input.nationId} turn=$turn');
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
    game: prep.planningGame,
    snapshot: prep.planningSnapshot,
    personalityId: input.config.personalityId,
  );
  // Refs #3517 Cluster 4: the treasury planner forecasts overseas trade-cargo
  // capacity via `computeExtraction`, an O(players × connected-tiles) scan.
  // `runTreasuryPlanner` is potentially invoked more than once per AI player
  // turn (the `runEconomyPlanner` pass below plus the orchestrator tail
  // re-invocation when `recomputeTradeOrdersWithPendingCosts` is set), so the
  // extraction map is hoisted and computed **once** here and threaded into
  // both call sites instead of being recomputed on every invocation
  // (`colonizethis-turn-resolution-budget.mdc` § duplicate global scans). AI
  // planning is read-only over `game` (`PlannerContext.withOrders` reuses the
  // same `game` object across every step), so a single map is safe to reuse
  // across the invocations within one planning pass. The compute is gated on a
  // present tile map and a non-zero home fleet (the same precondition
  // `tradeCargoCapacityForGreatPower` short-circuits on) so a player with no
  // home fleet never pays for an extraction scan it would not consume.
  final tradeForecastExtractionById =
      (input.tileMapByRegion != null &&
          input.tileMapByRegion!.isNotEmpty &&
          cargoHoldsForHomeFleet(prep.planningGame, input.nationId) > 0)
      ? computeExtractionTotalsForTradeForecast(
          game: prep.planningGame,
          tileMapByRegion: input.tileMapByRegion!,
          topology: input.topology,
        )
      : null;
  // Refs #3122 orchestrator wiring: the production strategic-AI entry
  // skips trade-order generation inside [runEconomyPlanner] so the
  // orchestrator can re-invoke [runTreasuryPlanner] after every other
  // domain planner has had a chance to emit pending orders. That way
  // pending build / recruit / research treasury costs feed the
  // `pendingTreasuryCostsForTurn` projector and the bid budget reflects
  // the real treasury the matcher will see at phase 13.
  final economyPlan = runEconomyPlanner(
    game: prep.planningGame,
    view: prep.planningView,
    config: input.config,
    seeds: input.seeds,
    colonial: prep.snapshot.colonial,
    snapshot: prep.planningSnapshot,
    phasePlan: phasePlan,
    tileMapByRegion: input.tileMapByRegion,
    topology: input.topology,
    skipTradeOrderGeneration: true,
    growthStagePlannerEnabled: input.growthStagePlannerEnabled,
    extractionById: tradeForecastExtractionById,
  );
  final plannerOutcome = runDomainPlannersWithOutcome(
    DomainPlannerInput(
      game: prep.planningGame,
      topology: input.topology,
      nationId: input.nationId,
      view: prep.planningView,
      snapshot: prep.planningSnapshot,
      config: input.config,
      primaryGoal: prep.primaryGoal,
      seeds: input.seeds,
      suggestionAPI: input.suggestionAPI,
      economyPlan: economyPlan,
      options: OrchestratorOptions(
        tileMapByRegion: input.tileMapByRegion,
        onStagedPlannerProgress: input.onStagedPlannerProgress,
        sameTurnPriorDiplomaticOrders: input.sameTurnPriorDiplomaticOrders,
        phasePlan: phasePlan,
        recomputeTradeOrdersWithPendingCosts: true,
        growthStagePlannerEnabled: input.growthStagePlannerEnabled,
        extractionById: tradeForecastExtractionById,
      ),
    ),
  );
  // Trade orders are merged into [Orders.tradeOrdersByPlayerId] inside the
  // domain orchestrator (Refs #2994 F7) so all orchestrator callers see the
  // same merged output. Keep this read-only here.
  final orders = plannerOutcome.orders;
  final moveCount = orders.moveOrdersByPlayerId[input.nationId]?.length ?? 0;
  final armyMoveCount =
      orders.armyMoveOrdersByPlayerId[input.nationId]?.length ?? 0;
  final buildCount =
      orders.buildUnitOrdersByPlayerId[input.nationId]?.length ?? 0;
  final workCount = orders.workOrdersByPlayerId[input.nationId]?.length ?? 0;
  final researchCount =
      orders.researchOrdersByPlayerId[input.nationId]?.length ?? 0;
  final tradeCount = orders.tradeOrdersByPlayerId[input.nationId]?.length ?? 0;
  _log.i(
    'generated orders nationId=${input.nationId} move=$moveCount armyMove=$armyMoveCount '
    'build=$buildCount work=$workCount research=$researchCount trade=$tradeCount',
  );
  emitStrategicDialogueAndMood(
    config: input.config,
    seeds: input.seeds,
    onDialogue: input.onDialogue,
    onMood: input.onMood,
  );
  final result = StrategicOrderResult(orders: orders, economyPlan: economyPlan);
  final ordersByDomain = orderCountsByDomain(input.nationId, orders);
  final finalOrders = finalAggregatedOrders(input.nationId, orders);
  return StrategicOrderTraceResult(
    result: result,
    game: prep.planningGame,
    aiTraceSection: buildAiTraceSection(
      AiTraceBuildInput(
        nationId: input.nationId,
        turn: turn,
        config: input.config,
        seeds: input.seeds,
        snapshot: prep.snapshot,
        primaryGoal: prep.primaryGoal,
        goalScores: prep.goalScores,
        economyPlan: economyPlan,
        orders: orders,
        ordersByDomain: ordersByDomain,
        finalOrders: finalOrders,
        declaredWarTargetFactionId: plannerOutcome.declaredWarTargetFactionId,
        conquestArmyMoveCount: plannerOutcome.conquestArmyMoveCount,
        observerGoalPhase: prep.observerGoalPhase,
        phasePlan: plannerOutcome.phasePlan ?? phasePlan,
        domainGateData: plannerOutcome.domainGateData,
      ),
    ),
  );
}
