import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import '../util/orders_builder.dart';
import 'build_planner.dart';
import 'domain_planner_orchestrator_economy_build.dart';
import 'domain_planner_orchestrator_economy_civilian_work.dart';
import 'domain_planner_orchestrator_economy_recruit.dart';
import 'economy_phase_gates.dart';
import 'growth_stage.dart';
import 'goal_manager.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_planner_work_order_filter.dart';
import 'planner_context.dart';
import 'planning_helpers.dart'
    show
        isAtWarWithAnyGreatPower,
        isPursuingTechStealPosture;
import 'planning_imports.dart';

export 'domain_planner_orchestrator_economy_recruit.dart'
    show appendEconomyPeasantRecruit;

final _log = packageLogger('domain_planner_orchestrator_economy');

/// Economy-phase orchestrator slice carrying both the post-pass
/// [PlannerContext] and the [EconomyGateRecord] required to populate
/// `thresholds.domainGates` in the AI trace (Refs #2832).
class EconomyDomainPlannersResult {
  const EconomyDomainPlannersResult({required this.ctx, required this.gate});

  final PlannerContext ctx;
  final EconomyGateRecord gate;
}

/// Captures the resolved civilian-work and build gate decisions of one
/// [runEconomyDomainPlanners] pass.
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

EconomyDomainPlannersResult runEconomyDomainPlanners({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
  required EconomyPlan economyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
  required void Function(String phaseId) emit,
}) {
  final economyPhaseGates = EconomyPhaseGates.fromPhasePlan(
    phasePlan: phasePlan,
    snapshot: snapshot,
  );
  final growthStagePlannerEnabled = ctx.growthStagePlannerEnabled;
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
    includeCivilianBuilds: ctx.civilianBuildPlannerEnabled,
  );
  final spyDemand =
      isAtWarWithAnyGreatPower(ctx.game, snapshot) ||
      isPursuingTechStealPosture(ctx.game, ctx.nationId);
  final civilianScoring = buildCivilianBuildScoringInput(
    ctx: ctx,
    phaseName: phasePlan.phase.name,
    spyDemand: spyDemand,
    phaseProgress: phasePlan.priorityWeights.newWorldCivilian,
  );
  final hasSpyWork = workCandidates.any(
    (o) => o.target == kWorkTargetCounterSpy,
  );
  var workThreshold =
      40 -
      (hasSpyWork ? getAgendaSpyOrderModifier(ctx.config.hiddenAgendaId) : 0);
  final developPhase = economyPhaseGates.developActive;
  final colonialPressure = economyPhaseGates.colonialPressureActive;
  final colonialPressureWeight = economyPhaseGates.colonialPressureWeight;
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
    runEconomyCivilianWorkPass(
      ctx: ctx,
      economyPhaseGates: economyPhaseGates,
      ordersBuilder: ordersBuilder,
      workCandidates: workCandidates,
      growthStage: growthStage,
      growthStagePlannerEnabled: growthStagePlannerEnabled,
      tileMapByRegion: tileMapByRegion,
    );
  } else if (workCandidates.isNotEmpty) {
    _log.d('work skipped nationId=${ctx.nationId} weight below threshold');
  }
  emit('aiStageA');

  appendEconomyPeasantRecruit(
    ctx: ctx,
    expandEconomy: economyPhaseGates.expandEconomy,
    growthStage: growthStage,
    growthStagePlannerEnabled: growthStagePlannerEnabled,
    ordersBuilder: ordersBuilder,
  );

  final buildResult = appendEconomyBuildOrders(
    EconomyBuildPassInput(
      ctx: ctx,
      snapshot: snapshot,
      phasePlan: phasePlan,
      economyPhaseGates: economyPhaseGates,
      economyPlan: economyPlan,
      ordersBuilder: ordersBuilder,
      colonialPressure: colonialPressure,
      buildCandidates: buildCandidates,
      civilianScoring: civilianScoring,
      domainEconomyWeight: domainWeights.economy,
    ),
  );
  emit('aiStageB');
  return EconomyDomainPlannersResult(
    ctx: ctx.withOrders(ordersBuilder.build()),
    gate: EconomyGateRecord(
      workPlannerRan: runFullAiCivilianWork,
      buildPlannerRan: buildResult.buildPlannerRan,
      workThreshold: workThreshold,
      buildThreshold: buildResult.buildThreshold,
    ),
  );
}
