library;

import 'dart:math' as math;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'army_conquest_prep.dart';
import 'domain_gate_data.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_planner_work_order_filter.dart';
import 'phase_priority_weights.dart' show kPhasePriorityNwTreasuryRecoveryFloor;
import 'planning_helpers.dart'
    show
        isAtWarWithAnyGreatPower,
        isPursuingTechStealPosture,
        oldWorldProvinceLeadOver;
import 'planning_imports.dart';
import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/orders_builder.dart';
import '../util/orders_extensions.dart';
import 'build_planner.dart';
import 'growth_stage.dart';
import 'conquest_planner.dart';
import 'expand_phase_planner.dart' show ExpandEconomyPlan;
import 'growth_stage_builder_relocation.dart';
import 'growth_stage_work_priorities.dart';
import 'diplomacy_planner.dart';
import 'domain_planner_outcome.dart';
import 'economy_phase_gates.dart';
import 'move_planner.dart';
import 'orchestrator_options.dart';
import 'naval_planner.dart';
import 'planner_context.dart';
import 'research_planner.dart';
import 'treasury_planner.dart';

part 'domain_planner_orchestrator_economy.dart';
part 'domain_planner_orchestrator_military.dart';
part 'domain_planner_orchestrator_diplomacy.dart';

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
  OrchestratorOptions options = OrchestratorOptions.defaults,
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
    options: options,
  ).orders;
}

/// Runs the domain-planner pipeline for one AI-controlled player turn.
///
/// When [phasePlan] is provided the orchestrator threads it through every
/// phase-derived call site instead of recomputing it via [runPhasePlanners].
/// Callers that already resolved the dispatched plan once per AI turn
/// (e.g. [generateStrategicOrdersWithTrace]) pass it in here so the planning
/// pipeline does not duplicate the dispatch work for the same `(game,
/// snapshot, personalityId)` inputs. When [phasePlan] is `null` the
/// orchestrator falls back to the legacy internal compute so existing
/// callers (orchestrator-level tests, the alternate `runDomainPlanners`
/// entry without a hoisted plan) remain unchanged. Refs #2509 S5.
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
  OrchestratorOptions options = OrchestratorOptions.defaults,
}) {
  void emit(String phaseId) => options.onStagedPlannerProgress?.call(phaseId);

  final resolvedPhasePlan =
      options.phasePlan ??
      runPhasePlanners(
        game: game,
        snapshot: snapshot,
        personalityId: config.personalityId,
      );
  final economyPhaseGates = EconomyPhaseGates.fromPhasePlan(
    phasePlan: resolvedPhasePlan,
    snapshot: snapshot,
  );

  var ctx = PlannerContext(
    nationId: nationId,
    view: view,
    game: game,
    topology: topology,
    orders: const Orders(),
    config: config,
    primaryGoal: primaryGoal,
    seeds: seeds,
    suggestionAPI: suggestionAPI,
    sameTurnPriorDiplomaticOrders: options.sameTurnPriorDiplomaticOrders,
    growthStagePlannerEnabled: options.growthStagePlannerEnabled,
    civilianBuildPlannerEnabled: options.civilianBuildPlannerEnabled,
  );

  final economyResult = _runEconomyDomainPlanners(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: resolvedPhasePlan,
    economyPhaseGates: economyPhaseGates,
    economyPlan: economyPlan,
    tileMapByRegion: options.tileMapByRegion,
    emit: emit,
  );
  ctx = economyResult.ctx;
  final economyGate = economyResult.gate;

  ctx = ctx.withOrders(runMovePlanner(ctx: ctx));
  emit('aiStageC');

  final preConquestDiplomacy = _runPreConquestDiplomacyPlanners(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: resolvedPhasePlan,
  );
  ctx = preConquestDiplomacy.ctx;
  final declaredWarTargetFactionId =
      preConquestDiplomacy.declaredWarTargetFactionId;

  final militaryResult = _runMilitaryDomainPlanners(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: resolvedPhasePlan,
    nationId: nationId,
    declaredWarTargetFactionId: declaredWarTargetFactionId,
    emit: emit,
  );
  ctx = militaryResult.ctx;
  final conquestArmyMovePlannerRan = militaryResult.conquestArmyMovePlannerRan;
  final conquestPasses = militaryResult.conquestPasses;
  final conquestArmyMoveCount = militaryResult.conquestArmyMoveCount;

  final navalGate = computeNavalRunGate(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: resolvedPhasePlan,
  );
  ctx = ctx.withOrders(
    runNavalPlanner(ctx: ctx, snapshot: snapshot, phasePlan: resolvedPhasePlan),
  );
  emit('aiStageE');

  // Late peace pass undoes same-turn declare-war on the OW frontier blocker
  // (observer seed-42 gp5/gp6; Refs #2509).
  ctx = _runLatePeaceDiplomacyPlanner(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: resolvedPhasePlan,
  );
  emit('aiStageF');

  final researchThreshold = computeResearchThreshold(ctx: ctx);
  final researchWillRun = researchPlannerWillRun(ctx: ctx);
  final researchResult = runResearchPlannerWithDecision(ctx: ctx);
  ctx = ctx.withOrders(researchResult.orders);
  emit('aiStageG');

  // Refs #2994 F7 / Refs #3122 orchestrator wiring: merge treasury-planner
  // trade orders into the orchestrator output so every caller (strategic-AI
  // entry + the simpler [runDomainPlanners] test entrypoint) surfaces trade
  // alongside the other domain order families. When
  // [recomputeTradeOrdersWithPendingCosts] is set, the orchestrator
  // re-invokes [runTreasuryPlanner] at this tail position with
  // `currentOrders = ctx.orders` so the treasury budget subtracts the
  // pending build / recruit / research costs emitted earlier in this
  // pipeline (Refs #3122 pending-cost projector). Otherwise the
  // orchestrator falls back to the pre-baked `economyPlan.tradeOrders` so
  // existing callers and the F7 wiring contract stay behaviour-equal.
  // Skip the append when the resolved list is empty so
  // `tradeOrdersByPlayerId` stays absent for that player and existing
  // `MapEquality` assertions remain stable.
  final List<TradeOrder> resolvedTradeOrders;
  if (options.recomputeTradeOrdersWithPendingCosts) {
    final player = game.playerById(nationId);
    resolvedTradeOrders = player == null
        ? const <TradeOrder>[]
        : runTreasuryPlanner(
            game: game,
            playerId: nationId,
            stockpile: player.stockpile,
            productionAssignments: economyPlan.productionAssignments,
            treasury: player.treasury,
            snapshot: snapshot,
            tileMapByRegion: options.tileMapByRegion,
            topology: topology,
            currentOrders: ctx.orders,
            extractionById: options.extractionById,
          );
  } else {
    resolvedTradeOrders = economyPlan.tradeOrders;
  }
  final tradePlannerRan = resolvedTradeOrders.isNotEmpty;
  if (tradePlannerRan) {
    ctx = ctx.withOrders(
      ctx.orders.appendTradeOrders(nationId, resolvedTradeOrders),
    );
  }

  final domainGateData = DomainGateData(
    workPlannerRan: economyGate.workPlannerRan,
    buildPlannerRan: economyGate.buildPlannerRan,
    movePlannerRan: true,
    diplomacyPlannerRan: true,
    navalPlannerRan: navalGate.willRun,
    researchPlannerRan: researchWillRun,
    conquestArmyMovePlannerRan: conquestArmyMovePlannerRan,
    conquestPasses: conquestPasses,
    tradePlannerRan: tradePlannerRan,
    workThreshold: economyGate.workThreshold,
    buildThreshold: economyGate.buildThreshold,
    researchThreshold: researchThreshold,
    researchDecision: researchResult.decision,
  );

  return DomainPlannerOutcome(
    orders: ctx.orders,
    declaredWarTargetFactionId: declaredWarTargetFactionId,
    conquestArmyMoveCount: conquestArmyMoveCount,
    phasePlan: resolvedPhasePlan,
    domainGateData: domainGateData,
  );
}
