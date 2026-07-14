part of 'domain_planner_orchestrator.dart';

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
  final economyPhaseGates = EconomyPhaseGates.fromPhasePlan(
    phasePlan: phasePlan,
    snapshot: snapshot,
  );
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
    // Refs #3793 live wiring: enumerate civilian build candidates only when the
    // civilian build planner is enabled. Default-off keeps the candidate pool
    // byte-identical to the military+naval path (SPEC ACWire1).
    includeCivilianBuilds: ctx.civilianBuildPlannerEnabled,
  );
  // Refs #3793 live wiring: build the civilian scoring input once per turn so
  // the build pass can apply the min-cap floor, replacement urgency, phase
  // multiplier, and Spy demand boost. `null` when the planner is disabled,
  // leaving `pickBuildOrder` inert (SPEC § Live economy wiring).
  // Refs #3793 decision #10: the Spy demand boost fires when the GP is at war
  // OR pursuing a tech-steal posture (behind the most-advanced rival GP's
  // unlocked-tech count by `kCivilianBuildSpyTechStealDeficit`). This replaces
  // the prior war-posture-only approximation so passive spy RP value is reflected
  // even at peace (SPEC § Live economy wiring; AC4c). Inert unless
  // `civilianBuildPlannerEnabled` (buildCivilianBuildScoringInput returns null).
  final spyDemand =
      isAtWarWithAnyGreatPower(ctx.game, snapshot) ||
      isPursuingTechStealPosture(ctx.game, ctx.nationId);
  final civilianScoring = buildCivilianBuildScoringInput(
    ctx: ctx,
    phaseName: phasePlan.phase.name,
    spyDemand: spyDemand,
    // Refs #3793 slice 8 (decision #13): the dispatch's continuous
    // `newWorldCivilian` weight drives smooth phase-multiplier ramping
    // (hysteresis) so per-phase civilian priorities transition continuously
    // across the EXPAND→COLONIAL→DEVELOP boundary instead of hard-switching.
    phaseProgress: phasePlan.priorityWeights.newWorldCivilian,
  );
  final hasSpyWork = workCandidates.any(
    (o) => o.target == kWorkTargetCounterSpy,
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
  final developPhase = economyPhaseGates.developActive;
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
  final colonialPressure = economyPhaseGates.colonialPressureActive;
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
      spyDevelopPhase: developPhase,
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
    expandEconomy: economyPhaseGates.expandEconomy,
    growthStage: growthStage,
    growthStagePlannerEnabled: growthStagePlannerEnabled,
    ordersBuilder: ordersBuilder,
  );

  final buildResult = _appendEconomyBuildOrders(
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
  required ExpandEconomyPlan expandEconomy,
  required GrowthStage? growthStage,
  required bool growthStagePlannerEnabled,
  required OrdersBuilder ordersBuilder,
}) {
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
