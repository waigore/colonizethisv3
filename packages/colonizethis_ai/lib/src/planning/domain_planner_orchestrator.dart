import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart'
    show BuildUnitCategory, buildUnitCategoryForUnitType;
import 'package:colonizethis_logic/ai_api.dart' show canAffordRecruitWorker;
import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'army_conquest_prep.dart';
import 'domain_gate_data.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_planner_expand_economy.dart';
import 'phase_planner_work_order_filter.dart';
import 'phase_priority_weights.dart' show kPhasePriorityNwTreasuryRecoveryFloor;
import 'planning_imports.dart';
import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/orders_builder.dart';
import '../util/orders_extensions.dart';
import 'build_planner.dart';
import 'growth_stage.dart';
import 'conquest_planner.dart';
import 'growth_stage_builder_relocation.dart';
import 'growth_stage_work_priorities.dart';
import 'diplomacy_planner.dart';
import 'domain_planner_outcome.dart';
import 'move_planner.dart';
import 'naval_planner.dart';
import 'planner_context.dart';
import 'research_planner.dart';
import 'treasury_planner.dart';

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
  PhasePlanOutcome? phasePlan,
  bool recomputeTradeOrdersWithPendingCosts = false,
  Map<String, ExtractionTotals>? extractionById,
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
    phasePlan: phasePlan,
    recomputeTradeOrdersWithPendingCosts: recomputeTradeOrdersWithPendingCosts,
    extractionById: extractionById,
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
  Map<String, TileMapResult>? tileMapByRegion,
  void Function(String phaseId)? onStagedPlannerProgress,
  Orders? sameTurnPriorDiplomaticOrders,
  PhasePlanOutcome? phasePlan,
  bool recomputeTradeOrdersWithPendingCosts = false,
  bool growthStagePlannerEnabled = kGrowthStagePlannerEnabled,
  Map<String, ExtractionTotals>? extractionById,
}) {
  void emit(String phaseId) => onStagedPlannerProgress?.call(phaseId);

  final resolvedPhasePlan =
      phasePlan ??
      runPhasePlanners(
        game: game,
        snapshot: snapshot,
        personalityId: config.personalityId,
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
    sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
    growthStagePlannerEnabled: growthStagePlannerEnabled,
  );

  final economyResult = _runEconomyDomainPlanners(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: resolvedPhasePlan,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    emit: emit,
  );
  ctx = economyResult.ctx;
  final economyGate = economyResult.gate;

  ctx = ctx.withOrders(runMovePlanner(ctx: ctx));
  emit('aiStageC');

  final peaceBeforeConquestResult = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.nonDeclareWarOnly,
    phasePlan: resolvedPhasePlan,
  );
  ctx = ctx.withOrders(peaceBeforeConquestResult.orders);

  final declareWarResult = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.declareWarOnly,
    phasePlan: resolvedPhasePlan,
  );
  ctx = ctx.withOrders(declareWarResult.orders);
  final armyMovesBeforeConquest =
      ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  // Refs #2509 S5: derive the extra-conquest-passes / relocation-skip
  // gate from the dispatched phase plan instead of recomputing the
  // legacy compound `isStalledOldWorldExpansion(ow) ||
  // isBelowObserverConquestQuota(ow)`. The two `colonizethis_data`
  // predicates are equivalent for integer `ow` (both reduce to
  // `ow <= 9`) and field-equal to `phase ∈ {EXPAND, COLONIAL-lite}`
  // because both phases require `oldWorldProvincesOwned <
  // kObserverConquestMinOwProvincesPerGp` at entry via
  // `observerGoalPhaseFor`. Routing the gate through the dispatched
  // `phasePlan` eliminates two per-player-turn predicate recomputes
  // and preserves the prior extra-passes / relocation-skip behaviour
  // exactly (see `SPEC/ai/phase-planner-dispatch.md` § Orchestrator
  // conquest extra-passes slice).
  final extraPassesActive = resolvePhaseConquestExtraPassesActive(
    phasePlan: resolvedPhasePlan,
  );
  final conquestDeclaredWarTarget = stalledConquestDeclaredWarTarget(
    game: ctx.game,
    nationId: nationId,
    snapshot: snapshot,
    declaredThisTurn: declareWarResult.declaredWarTargetFactionId,
  );
  final conquestPasses = extraPassesActive ? kStalledConquestArmyMovePasses : 1;
  var conquestArmyMovePlannerRan = false;
  for (var pass = 0; pass < conquestPasses; pass++) {
    conquestArmyMovePlannerRan = true;
    final movesBeforePass =
        ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
    ctx = ctx.withOrders(
      runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: conquestDeclaredWarTarget,
        phasePlan: resolvedPhasePlan,
      ),
    );
    final movesAfterPass =
        ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
    if (movesAfterPass == movesBeforePass) {
      break;
    }
  }
  final conquestArmyMoveCount =
      (ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0) -
      armyMovesBeforeConquest;
  // Stalled GPs must not run the relocation pass: it undoes frontier marches.
  if (!extraPassesActive) {
    ctx = ctx.withOrders(
      runArmyMovePlanner(
        ctx: ctx,
        provincesToVictory: snapshot.conquest.provincesToVictory,
      ),
    );
  }
  emit('aiStageD');

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
  ctx = ctx.withOrders(
    runDiplomacyPlannerWithResult(
      ctx: ctx,
      snapshot: snapshot,
      pass: DiplomacyPlannerPass.nonDeclareWarOnly,
      phasePlan: resolvedPhasePlan,
    ).orders,
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
  if (recomputeTradeOrdersWithPendingCosts) {
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
            tileMapByRegion: tileMapByRegion,
            topology: topology,
            currentOrders: ctx.orders,
            extractionById: extractionById,
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
    declaredWarTargetFactionId: declareWarResult.declaredWarTargetFactionId,
    conquestArmyMoveCount: conquestArmyMoveCount,
    phasePlan: resolvedPhasePlan,
    domainGateData: domainGateData,
  );
}

/// Economy-phase orchestrator slice carrying both the post-pass
/// [PlannerContext] and the [EconomyGateRecord] required to populate
/// `thresholds.domainGates` in the AI trace (Refs #2832).
class _EconomyDomainPlannersResult {
  const _EconomyDomainPlannersResult({required this.ctx, required this.gate});

  final PlannerContext ctx;
  final EconomyGateRecord gate;
}

/// Captures the resolved civilian-work and build gate decisions of one
/// [_runEconomyDomainPlanners] pass.
class EconomyGateRecord {
  const EconomyGateRecord({
    required this.workPlannerRan,
    required this.buildPlannerRan,
    required this.workThreshold,
    required this.buildThreshold,
  });

  final bool workPlannerRan;
  final bool buildPlannerRan;
  final int workThreshold;
  final int buildThreshold;
}

_EconomyDomainPlannersResult _runEconomyDomainPlanners({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
  required EconomyPlan economyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
  required void Function(String phaseId) emit,
}) {
  final growthStagePlannerEnabled = ctx.growthStagePlannerEnabled;
  // Refs #3288: accumulate the orchestrator-emitted economy families (work,
  // recruit, build) into a single mutable [OrdersBuilder] and freeze once,
  // replacing the prior chained `Orders.copyWith` appends that allocated an
  // intermediate immutable [Orders] per family. Read-only suggestion calls
  // observe the accumulated state via the builder's cached snapshot.
  final ordersBuilder = OrdersBuilder.from(ctx.orders);
  final domainWeights = ctx.domainWeights;

  emit('suggestionPools');
  var workCandidates = ctx.suggestionAPI.suggestWorkOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ordersBuilder.build(),
    tileMapByRegion: tileMapByRegion,
  );
  workCandidates = workCandidates
      .where((w) => !shouldSuppressWorkOrderFromPhasePlan(w, phasePlan))
      .toList();
  final buildCandidates = ctx.suggestionAPI.suggestBuildOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ordersBuilder.build(),
  );
  final hasSpyWork = workCandidates.any(
    (o) =>
        o.target == kWorkTargetStealTech || o.target == kWorkTargetCounterSpy,
  );
  var workThreshold =
      40 -
      (hasSpyWork ? getAgendaSpyOrderModifier(ctx.config.hiddenAgendaId) : 0);
  // Refs #2509 S5: derive the DEVELOP-phase economy gate from the
  // dispatched phase plan instead of recomputing
  // `isObserverDevelopPhase` (which itself recomputes
  // `observerGoalPhaseFor`) per player turn. The phase dispatcher
  // already resolved `observerGoalPhaseFor` once via
  // `runPhasePlanners`, so `resolvePhaseEconomyDevelopActive` mirrors
  // `resolvePhaseEconomyColonialPressureActive` (this file) and
  // `resolvePhaseDiplomacyDeclareWarDevelopSuppressionActive`
  // (`phase_planner_diplomacy_filter.dart`) by routing the DEVELOP
  // gate off the dispatched value. Phase-derived `true/false` is
  // field-equal to the legacy compute across every
  // [ObserverGoalPhase] value, preserving the prior workThreshold cap
  // / `runFullAiCivilianWork` behaviour exactly under DEVELOP.
  final developPhase = resolvePhaseEconomyDevelopActive(phasePlan: phasePlan);
  // Refs #2509 S5: derive colonial economy pressure from the dispatched
  // phase plan instead of the legacy three-predicate compute. The phase
  // dispatcher already resolved `observerGoalPhaseFor` once per player turn;
  // this resolver mirrors `resolvePhaseConquestColonialPressureActive` and
  // enables the colonial economy boost only under COLONIAL — structurally
  // suppressed under EXPAND, COLONIAL-lite, and DEVELOP per
  // `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy slice.
  // The tagalong `newWorldProvincesOwned > 0` guards below still
  // independently trigger the colonial workThreshold cap and
  // `runFullAiCivilianWork` so GPs that already own NW provinces keep
  // running civilian planning under EXPAND / COLONIAL-lite.
  final colonialPressure = resolvePhaseEconomyColonialPressureActive(
    phasePlan: phasePlan,
  );
  // Refs #2847 Phase 3 economy civilian-work threshold cap wiring: the
  // colonial-pressure civilian-work cap now scales continuously with the
  // soft-phase NW acquisition weight instead of stepping to the hard
  // `kColonialCivilianWorkThresholdCap` only under the COLONIAL boolean.
  // `economyColonialPressureCivilianWorkThresholdCap` is identity-equal to
  // the legacy uncapped threshold at weight 0.0 and to the hard colonial
  // cap at weight 1.0 (see `SPEC/ai/phase-planner-architecture.md`
  // § Phase 3 consumer wiring — economy civilian-work threshold cap). The
  // `newWorldProvincesOwned > 0` tagalong remains a hard cap so a GP that
  // already holds NW land keeps the full colonial civilian-work bar.
  final colonialPressureWeight = resolvePhaseEconomyColonialPressureWeight(
    phasePlan: phasePlan,
  );
  if (developPhase) {
    workThreshold = math.min(workThreshold, kDevelopCivilianWorkThresholdCap);
  } else {
    workThreshold = math.min(
      workThreshold,
      economyColonialPressureCivilianWorkThresholdCap(
        colonialPressureWeight: colonialPressureWeight,
        uncappedThreshold: workThreshold,
      ),
    );
    if (snapshot.colonial.newWorldProvincesOwned > 0) {
      workThreshold = math.min(
        workThreshold,
        kColonialCivilianWorkThresholdCap,
      );
    }
  }
  // Refs #3371: growth-stage economy scoring coexists with H8 civilian-work
  // feedstock routing until AC9 replaces it with priority-vector scoring.
  final growthStage = growthStagePlannerEnabled
      ? GrowthStage.compute(ctx.game, ctx.nationId, snapshot: snapshot)
      : null;
  final feedstockExtractionActive =
      regimentBuildInputFeedstockExtractionResourceIds(
        ctx.game,
        ctx.nationId,
      ).isNotEmpty ||
      supplierImprovementInputFeedstockExtractionResourceIds(
        ctx.game,
        ctx.nationId,
      ).isNotEmpty;
  final growthStageCivilianWork = growthStage != null;
  final runFullAiCivilianWork =
      developPhase ||
      ctx.primaryGoal == StrategicGoal.expand ||
      domainWeights.economy >= workThreshold ||
      colonialPressure ||
      snapshot.colonial.newWorldProvincesOwned > 0 ||
      feedstockExtractionActive ||
      growthStageCivilianWork;
  _log.d(
    'work eval nationId=${ctx.nationId} workThreshold=$workThreshold '
    'domainWeights.economy=${domainWeights.economy} primaryGoal=${ctx.primaryGoal} '
    'workCandidatesCount=${workCandidates.length}',
  );
  if (runFullAiCivilianWork) {
    final prioritizedWorkCandidates = growthStage != null
        ? prioritizeWorkOrdersForGrowthStage(
            workCandidates: workCandidates,
            game: ctx.game,
            playerId: ctx.nationId,
            stage: growthStage,
          )
        : workCandidates;
    // Refs #3371 AC1/AC2: route bootstrap/infrastructure Builders onto fabric
    // (then infrastructure) feedstock tiles inside the per-unit selection. The
    // candidate reorder above is re-sorted lexicographically per unit by the
    // selector, so the binding signal is the feedstock resource-id preference
    // threaded into the build-improvement scoring below.
    final feedstockPreference = growthStage != null
        ? growthStageFeedstockPreference(
            game: ctx.game,
            playerId: ctx.nationId,
            stage: growthStage,
            growthStagePlannerEnabled: growthStagePlannerEnabled,
          )
        : GrowthStageFeedstockPreference.none;
    if (growthStage != null) {
      final relocation = suggestGrowthStageBuilderFeedstockRelocation(
        game: ctx.game,
        view: ctx.view,
        topology: ctx.topology,
        currentOrders: ordersBuilder.build(),
        suggestionAPI: ctx.suggestionAPI,
        stage: growthStage,
        feedstockPreference: feedstockPreference,
        growthStagePlannerEnabled: growthStagePlannerEnabled,
      );
      if (relocation != null) {
        _log.i(
          'growth_stage_builder_relocate nationId=${ctx.nationId} '
          'unitId=${relocation.unitId} '
          'destinationTileKey=${relocation.destinationTileKey}',
        );
        ordersBuilder.appendMoveOrders(ctx.nationId, [relocation]);
        final movedUnitIds = {relocation.unitId};
        workCandidates = workCandidates
            .where((w) => !movedUnitIds.contains(w.unitId))
            .toList();
      }
    }
    final selection = selectFullAiCivilianWorkOrders(
      workSuggestions: prioritizedWorkCandidates,
      view: ctx.view,
      game: ctx.game,
      tileMapByRegion: tileMapByRegion,
      growthStageFabricFeedstockResourceIds:
          feedstockPreference.fabricFeedstockResourceIds,
      growthStageInfraFeedstockResourceIds:
          feedstockPreference.infraFeedstockResourceIds,
    );
    for (final w in selection.workOrders) {
      final unitType = ctx.view.ownUnitsById[w.unitId]?.type ?? 'unknown';
      _log.i(
        'civilian_work_assigned nationId=${ctx.nationId} unitId=${w.unitId} '
        'unitType=$unitType target=${w.target} targetTileKey=${w.targetTileKey}',
      );
    }
    for (final idle in selection.idleEvents) {
      _log.i(
        'civilian_work_idle nationId=${ctx.nationId} unitId=${idle.unitId} '
        'unitType=${idle.unitType} reason=${idle.reason}',
      );
    }
    if (selection.workOrders.isNotEmpty) {
      ordersBuilder.appendWorkOrders(ctx.nationId, selection.workOrders);
    }
  } else if (workCandidates.isNotEmpty) {
    _log.d('work skipped nationId=${ctx.nationId} weight below threshold');
  }
  emit('aiStageA');

  _appendEconomyPeasantRecruit(
    ctx: ctx,
    phasePlan: phasePlan,
    growthStage: growthStage,
    growthStagePlannerEnabled: growthStagePlannerEnabled,
    ordersBuilder: ordersBuilder,
  );

  final buildResult = _appendEconomyBuildOrders(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: phasePlan,
    economyPlan: economyPlan,
    ordersBuilder: ordersBuilder,
    colonialPressure: colonialPressure,
    buildCandidates: buildCandidates,
    domainEconomyWeight: domainWeights.economy,
  );
  emit('aiStageB');
  return _EconomyDomainPlannersResult(
    ctx: ctx.withOrders(ordersBuilder.build()),
    gate: EconomyGateRecord(
      workPlannerRan: runFullAiCivilianWork,
      buildPlannerRan: buildResult.buildPlannerRan,
      workThreshold: workThreshold,
      buildThreshold: buildResult.buildThreshold,
    ),
  );
}

/// Appends a single peasant recruit-worker order into [ordersBuilder] when the
/// growth-stage worker-growth priority (Refs #3371) or the legacy castIron
/// labour expand boost authorizes it and the GP can afford it.
///
/// Extracted verbatim from [_runEconomyDomainPlanners] to keep that
/// orchestrator slice within the repo function-size budget; behaviour is
/// unchanged.
void _appendEconomyPeasantRecruit({
  required PlannerContext ctx,
  required PhasePlanOutcome phasePlan,
  required GrowthStage? growthStage,
  required bool growthStagePlannerEnabled,
  required OrdersBuilder ordersBuilder,
}) {
  final expandEconomy = expandEconomyPlanFromPhasePlan(phasePlan);
  final growthStagePeasantRecruit =
      growthStage != null && growthStage.workerGrowthPriority > 0.1;
  if (growthStagePeasantRecruit ||
      (!growthStagePlannerEnabled &&
          expandEconomy.boostCastIronLabourPeasantRecruitment)) {
    final recruitCandidates = ctx.suggestionAPI.suggestRecruitWorkerOrders(
      ctx.view,
      ctx.game,
      ctx.topology,
      ordersBuilder.build(),
    );
    RecruitWorkerOrder? peasantRecruit;
    for (final candidate in recruitCandidates) {
      if (candidate.targetTier == WorkerTier.peasant) {
        peasantRecruit = candidate;
        break;
      }
    }
    if (peasantRecruit != null) {
      final player = ctx.game.playerById(ctx.nationId);
      final affordable =
          player != null &&
          canAffordRecruitWorker(
            player,
            peasantRecruit,
            player.workerPool,
            player.stockpile,
            player.treasury,
          ).canAfford;
      if (affordable) {
        _log.i(
          growthStagePeasantRecruit
              ? 'growth-stage peasant recruit nationId=${ctx.nationId} '
                    'workerGrowth=${growthStage.workerGrowthPriority.toStringAsFixed(2)}'
              : 'castIron labour peasant recruit nationId=${ctx.nationId} '
                    'targetTier=${peasantRecruit.targetTier.name}',
        );
        ordersBuilder.appendRecruitWorkerOrders(ctx.nationId, [peasantRecruit]);
      } else {
        _log.d(
          growthStagePeasantRecruit
              ? 'growth-stage peasant recruit deferred nationId=${ctx.nationId} '
                    'reason=unaffordable'
              : 'castIron labour peasant recruit deferred nationId=${ctx.nationId} '
                    'reason=fabric_short',
        );
      }
    }
  }
}

/// Build pass outcome plus the resolved build-threshold gate decision.
class _BuildPassResult {
  const _BuildPassResult({
    required this.buildPlannerRan,
    required this.buildThreshold,
  });

  final bool buildPlannerRan;
  final int buildThreshold;
}

/// Appends the chosen economy build order (if any) into [ordersBuilder] and
/// returns the build-gate decision. Refs #3288 (mutable orders accumulation).
/// Computes the base economy build-order threshold for the build pass.
///
/// Extracted from [_appendEconomyBuildOrders] to keep that orchestrator slice
/// within the repo function-size budget; behaviour is unchanged. The threshold
/// starts from the agenda-adjusted base, tightens under EXPAND quota pressure
/// (and the GP-blocker focus sub-cap), then applies the dispatched colonial
/// build-order cap when present.
///
/// Refs #2509 S5: the colonial cap is derived from the dispatched phase plan
/// instead of the legacy `colonialBuildOrderThresholdCap(snapshot.colonial)`.
/// COLONIAL phase entry is itself gated on `hasColonialAcquisitionTargets` via
/// `observerGoalPhaseFor`, so the phase-derived `int?` is field-equal to the
/// legacy single reachable arm (see `SPEC/ai/phase-planner-dispatch.md`
/// § Orchestrator economy build colonial-cap slice).
int _computeBaseBuildThreshold({
  required PlannerContext ctx,
  required PhasePlanOutcome phasePlan,
  required AIWorldSnapshot snapshot,
  required bool expandQuotaPressure,
}) {
  var buildThreshold =
      30 - getAgendaBuildOrderModifier(ctx.config.hiddenAgendaId);
  if (expandQuotaPressure) {
    buildThreshold = math.min(buildThreshold, 15);
  }
  if (expandQuotaPressure &&
      resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: phasePlan)) {
    buildThreshold = math.min(buildThreshold, 8);
  }
  final colonialBuildCap = resolvePhaseEconomyColonialBuildOrderThresholdCap(
    phasePlan: phasePlan,
    colonial: snapshot.colonial,
  );
  if (colonialBuildCap != null) {
    buildThreshold = math.min(buildThreshold, colonialBuildCap);
  }
  return buildThreshold;
}

/// Computes the stalled-expansion minimum regiment floor for the build pass.
///
/// Extracted from [_appendEconomyBuildOrders] to keep that orchestrator slice
/// within the repo function-size budget; behaviour is unchanged (the floor is
/// raised for an at-war GP blocker province deficit and the critically-weak /
/// below-quota rebuild bands, then pinned to 1 on a zero-regiment rebuild).
int _computeMinRegimentFloor({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required bool atWarWithGpBlocker,
  required String? gpBlocker,
  required bool criticallyWeakNoGpWar,
  required bool criticallyWeakBelowQuota,
  required bool needRegimentsToExpand,
  required bool belowQuotaZeroRegimentsRebuild,
}) {
  var minRegimentFloor = atWarWithGpBlocker
      ? kStalledMinRegimentCountWhenGpBlockerAtWar
      : kStalledMinRegimentCountWhenAtWar;
  if (atWarWithGpBlocker && gpBlocker != null) {
    final deficit =
        provinceCountOwnedBy(ctx.game, gpBlocker) -
        snapshot.conquest.oldWorldProvincesOwned;
    if (deficit > 0) {
      minRegimentFloor +=
          deficit * kStalledMinRegimentCountPerProvinceDeficitVsBlocker;
    }
  }
  if (criticallyWeakNoGpWar &&
      snapshot.threats.atWarWith.isNotEmpty &&
      minRegimentFloor < kStalledMinRegimentCountWhenCriticallyWeakNoGpWar) {
    minRegimentFloor = kStalledMinRegimentCountWhenCriticallyWeakNoGpWar;
  }
  if (criticallyWeakBelowQuota &&
      (snapshot.threats.atWarWith.isNotEmpty || needRegimentsToExpand) &&
      minRegimentFloor < kStalledMinRegimentCountWhenCriticallyWeakBelowQuota) {
    minRegimentFloor = kStalledMinRegimentCountWhenCriticallyWeakBelowQuota;
  }
  if (belowQuotaZeroRegimentsRebuild) {
    minRegimentFloor = 1;
  }
  return minRegimentFloor;
}

_BuildPassResult _appendEconomyBuildOrders({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
  required EconomyPlan economyPlan,
  required OrdersBuilder ordersBuilder,
  required bool colonialPressure,
  required List<BuildUnitOrder> buildCandidates,
  required int domainEconomyWeight,
}) {
  final growthStagePlannerEnabled = ctx.growthStagePlannerEnabled;
  // Refs #2509 S5: derive below-quota OW build-pass routing from the
  // dispatched phase plan instead of recomputing
  // `isStalledOldWorldExpansion(ow)` / `isBelowObserverConquestQuota(ow)`
  // per build pass. Field-equal to `phase ∈ {EXPAND, COLONIAL-lite}` via
  // `resolvePhaseEconomyExpandQuotaPressureActive` (see
  // `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy build
  // slice). The EXPAND regiment-rebuild directive comes from
  // `expandEconomyPlanFromPhasePlan` (already computed once in
  // `runPhasePlanners`).
  final growthStage = growthStagePlannerEnabled
      ? GrowthStage.compute(ctx.game, ctx.nationId, snapshot: snapshot)
      : null;
  final suppressMilitaryBuilds =
      growthStage != null && growthStageSuppressesMilitaryBuilds(growthStage);

  final expandQuotaPressure = resolvePhaseEconomyExpandQuotaPressureActive(
    phasePlan: phasePlan,
  );
  final expandEconomy = expandEconomyPlanFromPhasePlan(phasePlan);
  final firstNavalTransportBootstrap =
      resolvePhaseFirstNavalTransportBootstrapActive(
        game: ctx.game,
        snapshot: snapshot,
        expandEconomyPlan: expandEconomy,
        playerId: ctx.nationId,
      );

  var buildThreshold = _computeBaseBuildThreshold(
    ctx: ctx,
    phasePlan: phasePlan,
    snapshot: snapshot,
    expandQuotaPressure: expandQuotaPressure,
  );
  final regimentCount = regimentCountForPlayer(ctx.game, ctx.nationId);
  final observerQuotaPressure = expandQuotaPressure;
  final atWarWithAnyGreatPower = snapshot.threats.atWarWith.any(
    (id) => ctx.game.playerById(id) != null,
  );
  final needRegimentsToExpand =
      observerQuotaPressure &&
      regimentCount == 0 &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  final brokeBelowQuotaAtPeace =
      observerQuotaPressure && regimentCount == 0 && !atWarWithAnyGreatPower;
  // Refs #2509 S5: derive the two `isBelowQuotaPeace*` rebuild-trap
  // signals from the dispatched phase plan instead of re-importing the
  // legacy `colonial_pressure.dart` helpers. The new resolvers fold the
  // prior `expandQuotaPressure &&` prefix into the phase gate (both
  // routes resolve to `phase ∈ {EXPAND, COLONIAL-lite}` and are
  // field-equal to `isBelowObserverConquestQuota(ow)` via
  // `observerGoalPhaseFor`) and evaluate the remaining per-turn arms
  // directly, so the orchestrator's last two direct call sites into
  // `colonial_pressure.dart` are gone from this file (the import is
  // removed too — see `SPEC/ai/phase-planner-dispatch.md` §
  // Orchestrator economy build rebuild-trap slice).
  final belowQuotaPeaceInsufficientRegiments =
      resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
        phasePlan: phasePlan,
        regimentCount: regimentCount,
        atWarWithAnyGreatPower: atWarWithAnyGreatPower,
        hasInvadableProvinces:
            snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty,
      );
  final belowQuotaZeroRegimentsRebuild =
      resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
        phasePlan: phasePlan,
        regimentCount: regimentCount,
        hasInvadableProvinces:
            snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty,
      );
  final zeroRegimentsAtWar =
      regimentCount == 0 && snapshot.threats.atWarWith.isNotEmpty;
  final criticallyWeakBelowQuota =
      observerQuotaPressure &&
      (snapshot.conquest.oldWorldProvincesOwned <=
              kFewOldWorldProvincesDefendThreshold ||
          zeroRegimentsAtWar ||
          needRegimentsToExpand);
  final criticallyWeakNoGpWar =
      snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      !snapshot.threats.atWarWith.any((id) => ctx.game.playerById(id) != null);
  final gpBlocker = expandPrimaryInvadableGpBlockerFromPhasePlan(
    phasePlan: phasePlan,
  );
  final atWarWithGpBlocker =
      gpBlocker != null && snapshot.threats.atWarWith.contains(gpBlocker);
  final minRegimentFloor = _computeMinRegimentFloor(
    ctx: ctx,
    snapshot: snapshot,
    atWarWithGpBlocker: atWarWithGpBlocker,
    gpBlocker: gpBlocker,
    criticallyWeakNoGpWar: criticallyWeakNoGpWar,
    criticallyWeakBelowQuota: criticallyWeakBelowQuota,
    needRegimentsToExpand: needRegimentsToExpand,
    belowQuotaZeroRegimentsRebuild: belowQuotaZeroRegimentsRebuild,
  );
  var forceRegimentRebuild =
      !suppressMilitaryBuilds &&
      (expandQuotaPressure || criticallyWeakBelowQuota) &&
      (snapshot.threats.atWarWith.isNotEmpty ||
          needRegimentsToExpand ||
          brokeBelowQuotaAtPeace ||
          belowQuotaPeaceInsufficientRegiments ||
          belowQuotaZeroRegimentsRebuild ||
          expandEconomy.forceCheapestRegimentBuild) &&
      regimentCount < minRegimentFloor;
  if (!suppressMilitaryBuilds &&
      (forceRegimentRebuild ||
          atWarWithGpBlocker ||
          expandEconomy.forceCheapestRegimentBuild)) {
    buildThreshold = 0;
  }
  _log.d(
    'build eval nationId=${ctx.nationId} buildThreshold=$buildThreshold '
    'buildCandidatesCount=${buildCandidates.length} '
    'regimentCount=$regimentCount forceRegimentRebuild=$forceRegimentRebuild',
  );
  var candidatesForGate = buildCandidates;
  if (growthStagePlannerEnabled) {
    final stage = GrowthStage.compute(
      ctx.game,
      ctx.nationId,
      snapshot: snapshot,
    );
    if (growthStageSuppressesMilitaryBuilds(stage)) {
      candidatesForGate = buildCandidates.where((order) {
        final category = buildUnitCategoryForUnitType(order.unitType);
        return category != BuildUnitCategory.military &&
            category != BuildUnitCategory.naval;
      }).toList();
      _log.d(
        'growth_stage military build suppressed nationId=${ctx.nationId} '
        'militaryPriority=${stage.militaryPriority}',
      );
    }
  }

  if (candidatesForGate.isEmpty ||
      (domainEconomyWeight < buildThreshold && !forceRegimentRebuild)) {
    if (candidatesForGate.isNotEmpty) {
      _log.d('build skipped nationId=${ctx.nationId} weight below threshold');
    }
    return _BuildPassResult(
      buildPlannerRan: false,
      buildThreshold: buildThreshold,
    );
  }
  var candidatesForBuild = candidatesForGate;
  if (suppressMilitaryBuilds && candidatesForBuild.isEmpty) {
    _log.d(
      'build suppressed nationId=${ctx.nationId} '
      'militaryPriority=${growthStage.militaryPriority.toStringAsFixed(2)}',
    );
    return _BuildPassResult(
      buildPlannerRan: false,
      buildThreshold: buildThreshold,
    );
  }
  if (forceRegimentRebuild && !firstNavalTransportBootstrap) {
    final regimentsOnly = buildCandidates
        .where((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType))
        .toList();
    if (regimentsOnly.isNotEmpty) {
      candidatesForBuild = regimentsOnly;
    }
  }
  // Refs #2847 Phase 3 economy build-pick wiring: source the cargo
  // bonus activation/scale from the soft-phase NW acquisition weight
  // sitting on the dispatched phase plan instead of the legacy
  // `colonialPressure` boolean. The boolean is still passed through as
  // the null-weight fallback path, but `colonialPressureWeight` is the
  // production source of truth — at the early-sprint default curve
  // (newWorldAcquisition = 0.05 for OW <= 7) the cargo bonus
  // collapses to a token nudge (`+2.5 * 0.05 = +0.125`) so the OW
  // conquest sprint is not dominated by colonial pressure, while at
  // the COLONIAL plateau the bonus reaches `+2.5` identity-equal to
  // the legacy hard-phase path.
  var colonialPressureWeight = resolvePhaseEconomyColonialPressureWeight(
    phasePlan: phasePlan,
  );
  if (firstNavalTransportBootstrap &&
      colonialPressureWeight < kPhasePriorityNwTreasuryRecoveryFloor) {
    colonialPressureWeight = kPhasePriorityNwTreasuryRecoveryFloor;
  }
  final chosen = pickBuildOrder(
    ctx: ctx,
    input: BuildPickInput(
      buildCandidates: candidatesForBuild,
      cargoPreference: economyPlan.cargoPreference,
      provincesToVictory: snapshot.conquest.provincesToVictory,
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
      colonialPressure: colonialPressure,
      colonialPressureWeight: colonialPressureWeight,
      militaryRebuildCrisis:
          !firstNavalTransportBootstrap &&
          (forceRegimentRebuild || expandEconomy.forceCheapestRegimentBuild) &&
          (atWarWithGpBlocker ||
              brokeBelowQuotaAtPeace ||
              belowQuotaZeroRegimentsRebuild ||
              belowQuotaPeaceInsufficientRegiments ||
              expandEconomy.forceCheapestRegimentBuild ||
              (regimentCount <= kStalledMilitaryRebuildCrisisRegimentCap &&
                  !(observerQuotaPressure &&
                      snapshot.conquest.oldWorldProvincesOwned >
                          kFewOldWorldProvincesDefendThreshold))),
    ),
  );
  if (chosen == null) {
    return _BuildPassResult(
      buildPlannerRan: true,
      buildThreshold: buildThreshold,
    );
  }
  _log.i('build chosen nationId=${ctx.nationId} unitType=${chosen.unitType}');
  ordersBuilder.appendBuildOrders(ctx.nationId, [chosen]);
  return _BuildPassResult(
    buildPlannerRan: true,
    buildThreshold: buildThreshold,
  );
}
