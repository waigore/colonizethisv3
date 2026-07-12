part of 'domain_planner_orchestrator.dart';

class _BuildPassResult {
  const _BuildPassResult({
    required this.buildPlannerRan,
    required this.buildThreshold,
  });

  final bool buildPlannerRan;
  final int buildThreshold;
}

/// Bundles inputs for [_appendEconomyBuildOrders] (Refs #3977 AC5).
final class EconomyBuildPassInput {
  const EconomyBuildPassInput({
    required this.ctx,
    required this.snapshot,
    required this.phasePlan,
    required this.economyPhaseGates,
    required this.economyPlan,
    required this.ordersBuilder,
    required this.colonialPressure,
    required this.buildCandidates,
    required this.civilianScoring,
    required this.domainEconomyWeight,
  });

  final PlannerContext ctx;
  final AIWorldSnapshot snapshot;
  final PhasePlanOutcome phasePlan;
  final EconomyPhaseGates economyPhaseGates;
  final EconomyPlan economyPlan;
  final OrdersBuilder ordersBuilder;
  final bool colonialPressure;
  final List<BuildUnitOrder> buildCandidates;
  final CivilianBuildScoringInput? civilianScoring;
  final int domainEconomyWeight;
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
  required EconomyPhaseGates economyPhaseGates,
  required bool expandQuotaPressure,
}) {
  var buildThreshold =
      30 - getAgendaBuildOrderModifier(ctx.config.hiddenAgendaId);
  if (expandQuotaPressure) {
    buildThreshold = math.min(buildThreshold, 15);
  }
  if (expandQuotaPressure && economyPhaseGates.expandGpBlockerFocusActive) {
    buildThreshold = math.min(buildThreshold, 8);
  }
  final colonialBuildCap = economyPhaseGates.colonialBuildOrderThresholdCap;
  if (colonialBuildCap != null) {
    buildThreshold = math.min(buildThreshold, colonialBuildCap);
  }
  return buildThreshold;
}

typedef _RegimentFloorContext = ({
  bool atWarWithGpBlocker,
  String? gpBlocker,
  bool criticallyWeakNoGpWar,
  bool criticallyWeakBelowQuota,
  bool needRegimentsToExpand,
  bool belowQuotaZeroRegimentsRebuild,
});

/// Computes the stalled-expansion minimum regiment floor for the build pass.
///
/// Extracted from [_appendEconomyBuildOrders] to keep that orchestrator slice
/// within the repo function-size budget; behaviour is unchanged (the floor is
/// raised for an at-war GP blocker province deficit and the critically-weak /
/// below-quota rebuild bands, then pinned to 1 on a zero-regiment rebuild).
int _computeMinRegimentFloor({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required _RegimentFloorContext floorContext,
}) {
  var minRegimentFloor = floorContext.atWarWithGpBlocker
      ? kStalledMinRegimentCountWhenGpBlockerAtWar
      : kStalledMinRegimentCountWhenAtWar;
  if (floorContext.atWarWithGpBlocker && floorContext.gpBlocker != null) {
    final deficit = oldWorldProvinceLeadOver(
      game: ctx.game,
      snapshot: snapshot,
      factionId: floorContext.gpBlocker!,
    );
    if (deficit > 0) {
      minRegimentFloor +=
          deficit * kStalledMinRegimentCountPerProvinceDeficitVsBlocker;
    }
  }
  if (floorContext.criticallyWeakNoGpWar &&
      snapshot.threats.atWarWith.isNotEmpty &&
      minRegimentFloor < kStalledMinRegimentCountWhenCriticallyWeakNoGpWar) {
    minRegimentFloor = kStalledMinRegimentCountWhenCriticallyWeakNoGpWar;
  }
  if (floorContext.criticallyWeakBelowQuota &&
      (snapshot.threats.atWarWith.isNotEmpty ||
          floorContext.needRegimentsToExpand) &&
      minRegimentFloor < kStalledMinRegimentCountWhenCriticallyWeakBelowQuota) {
    minRegimentFloor = kStalledMinRegimentCountWhenCriticallyWeakBelowQuota;
  }
  if (floorContext.belowQuotaZeroRegimentsRebuild) {
    minRegimentFloor = 1;
  }
  return minRegimentFloor;
}

/// Resolved gate state for the economy build pass (Refs #3977 AC6).
final class _EconomyBuildPassGate {
  const _EconomyBuildPassGate({
    required this.buildThreshold,
    required this.forceRegimentRebuild,
    required this.firstNavalTransportBootstrap,
    required this.candidatesForBuild,
    required this.colonialPressureWeight,
    required this.atWarWithGpBlocker,
    required this.brokeBelowQuotaAtPeace,
    required this.belowQuotaZeroRegimentsRebuild,
    required this.belowQuotaPeaceInsufficientRegiments,
    required this.observerQuotaPressure,
    required this.regimentCount,
    required this.expandEconomy,
    required this.skipWithoutRunning,
  });

  final int buildThreshold;
  final bool forceRegimentRebuild;
  final bool firstNavalTransportBootstrap;
  final List<BuildUnitOrder> candidatesForBuild;
  final double colonialPressureWeight;
  final bool atWarWithGpBlocker;
  final bool brokeBelowQuotaAtPeace;
  final bool belowQuotaZeroRegimentsRebuild;
  final bool belowQuotaPeaceInsufficientRegiments;
  final bool observerQuotaPressure;
  final int regimentCount;
  final ExpandEconomyPlan expandEconomy;
  final bool skipWithoutRunning;
}

_EconomyBuildPassGate _resolveEconomyBuildPassGate(
  EconomyBuildPassInput input,
) {
  final ctx = input.ctx;
  final snapshot = input.snapshot;
  final phasePlan = input.phasePlan;
  final economyPhaseGates = input.economyPhaseGates;
  final buildCandidates = input.buildCandidates;
  final domainEconomyWeight = input.domainEconomyWeight;

  final growthStagePlannerEnabled = ctx.growthStagePlannerEnabled;
  final growthStage = growthStagePlannerEnabled
      ? GrowthStage.compute(ctx.game, ctx.nationId, snapshot: snapshot)
      : null;
  final suppressMilitaryBuilds =
      growthStage != null && growthStageSuppressesMilitaryBuilds(growthStage);

  final expandQuotaPressure = economyPhaseGates.expandQuotaPressure;
  final expandEconomy = economyPhaseGates.expandEconomy;
  final firstNavalTransportBootstrap =
      resolvePhaseFirstNavalTransportBootstrapActive(
        game: ctx.game,
        snapshot: snapshot,
        expandEconomyPlan: expandEconomy,
        playerId: ctx.nationId,
      );

  var buildThreshold = _computeBaseBuildThreshold(
    ctx: ctx,
    economyPhaseGates: economyPhaseGates,
    expandQuotaPressure: expandQuotaPressure,
  );
  final regimentCount = regimentCountForPlayer(ctx.game, ctx.nationId);
  final observerQuotaPressure = expandQuotaPressure;
  final atWarWithAnyGreatPower = isAtWarWithAnyGreatPower(ctx.game, snapshot);
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
  final belowQuotaPeaceInsufficientRegiments = economyPhaseGates
      .belowQuotaPeaceInsufficientRegiments(
        regimentCount: regimentCount,
        atWarWithAnyGreatPower: atWarWithAnyGreatPower,
        hasInvadableProvinces:
            snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty,
      );
  final belowQuotaZeroRegimentsRebuild = economyPhaseGates
      .belowQuotaPeaceZeroRegimentsRebuild(
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
      !isAtWarWithAnyGreatPower(ctx.game, snapshot);
  final gpBlocker = expandPrimaryInvadableGpBlockerFromPhasePlan(
    phasePlan: phasePlan,
  );
  final atWarWithGpBlocker =
      gpBlocker != null && snapshot.threats.atWarWith.contains(gpBlocker);
  final minRegimentFloor = _computeMinRegimentFloor(
    ctx: ctx,
    snapshot: snapshot,
    floorContext: (
      atWarWithGpBlocker: atWarWithGpBlocker,
      gpBlocker: gpBlocker,
      criticallyWeakNoGpWar: criticallyWeakNoGpWar,
      criticallyWeakBelowQuota: criticallyWeakBelowQuota,
      needRegimentsToExpand: needRegimentsToExpand,
      belowQuotaZeroRegimentsRebuild: belowQuotaZeroRegimentsRebuild,
    ),
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

  _EconomyBuildPassGate skippedGate() => _EconomyBuildPassGate(
    buildThreshold: buildThreshold,
    forceRegimentRebuild: forceRegimentRebuild,
    firstNavalTransportBootstrap: firstNavalTransportBootstrap,
    candidatesForBuild: const [],
    colonialPressureWeight: 0,
    atWarWithGpBlocker: atWarWithGpBlocker,
    brokeBelowQuotaAtPeace: brokeBelowQuotaAtPeace,
    belowQuotaZeroRegimentsRebuild: belowQuotaZeroRegimentsRebuild,
    belowQuotaPeaceInsufficientRegiments: belowQuotaPeaceInsufficientRegiments,
    observerQuotaPressure: observerQuotaPressure,
    regimentCount: regimentCount,
    expandEconomy: expandEconomy,
    skipWithoutRunning: true,
  );

  if (candidatesForGate.isEmpty ||
      (domainEconomyWeight < buildThreshold && !forceRegimentRebuild)) {
    if (candidatesForGate.isNotEmpty) {
      _log.d('build skipped nationId=${ctx.nationId} weight below threshold');
    }
    return skippedGate();
  }
  var candidatesForBuild = candidatesForGate;
  if (suppressMilitaryBuilds && candidatesForBuild.isEmpty) {
    _log.d(
      'build suppressed nationId=${ctx.nationId} '
      'militaryPriority=${growthStage.militaryPriority.toStringAsFixed(2)}',
    );
    return skippedGate();
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
  var colonialPressureWeight = economyPhaseGates.colonialPressureWeight;
  if (firstNavalTransportBootstrap &&
      colonialPressureWeight < kPhasePriorityNwTreasuryRecoveryFloor) {
    colonialPressureWeight = kPhasePriorityNwTreasuryRecoveryFloor;
  }
  return _EconomyBuildPassGate(
    buildThreshold: buildThreshold,
    forceRegimentRebuild: forceRegimentRebuild,
    firstNavalTransportBootstrap: firstNavalTransportBootstrap,
    candidatesForBuild: candidatesForBuild,
    colonialPressureWeight: colonialPressureWeight,
    atWarWithGpBlocker: atWarWithGpBlocker,
    brokeBelowQuotaAtPeace: brokeBelowQuotaAtPeace,
    belowQuotaZeroRegimentsRebuild: belowQuotaZeroRegimentsRebuild,
    belowQuotaPeaceInsufficientRegiments: belowQuotaPeaceInsufficientRegiments,
    observerQuotaPressure: observerQuotaPressure,
    regimentCount: regimentCount,
    expandEconomy: expandEconomy,
    skipWithoutRunning: false,
  );
}

_BuildPassResult _appendEconomyBuildOrders(EconomyBuildPassInput input) {
  final ctx = input.ctx;
  final snapshot = input.snapshot;
  final economyPlan = input.economyPlan;
  final ordersBuilder = input.ordersBuilder;
  final colonialPressure = input.colonialPressure;
  final civilianScoring = input.civilianScoring;

  final gate = _resolveEconomyBuildPassGate(input);
  if (gate.skipWithoutRunning) {
    return _BuildPassResult(
      buildPlannerRan: false,
      buildThreshold: gate.buildThreshold,
    );
  }

  final chosen = pickBuildOrder(
    ctx: ctx,
    input: BuildPickInput(
      buildCandidates: gate.candidatesForBuild,
      cargoPreference: economyPlan.cargoPreference,
      provincesToVictory: snapshot.conquest.provincesToVictory,
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
      colonialPressure: colonialPressure,
      colonialPressureWeight: gate.colonialPressureWeight,
      civilianScoring: civilianScoring,
      militaryRebuildCrisis:
          !gate.firstNavalTransportBootstrap &&
          (gate.forceRegimentRebuild ||
              gate.expandEconomy.forceCheapestRegimentBuild) &&
          (gate.atWarWithGpBlocker ||
              gate.brokeBelowQuotaAtPeace ||
              gate.belowQuotaZeroRegimentsRebuild ||
              gate.belowQuotaPeaceInsufficientRegiments ||
              gate.expandEconomy.forceCheapestRegimentBuild ||
              (gate.regimentCount <= kStalledMilitaryRebuildCrisisRegimentCap &&
                  !(gate.observerQuotaPressure &&
                      snapshot.conquest.oldWorldProvincesOwned >
                          kFewOldWorldProvincesDefendThreshold))),
    ),
  );
  if (chosen == null) {
    return _BuildPassResult(
      buildPlannerRan: true,
      buildThreshold: gate.buildThreshold,
    );
  }
  _log.i('build chosen nationId=${ctx.nationId} unitType=${chosen.unitType}');
  ordersBuilder.appendBuildOrders(ctx.nationId, [chosen]);
  return _BuildPassResult(
    buildPlannerRan: true,
    buildThreshold: gate.buildThreshold,
  );
}
