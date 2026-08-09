import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'domain_planner_orchestrator_economy_build_support.dart';
import 'expand_phase_planner_economy.dart';
import 'growth_stage.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_priority_weights.dart' show kPhasePriorityNwTreasuryRecoveryFloor;
import 'planning_helpers.dart' show isAtWarWithAnyGreatPower;
import 'planning_imports.dart';

final _log = packageLogger('domain_planner_orchestrator_economy_build_gate');


EconomyBuildPassGate resolveEconomyBuildPassGate(
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

  var buildThreshold = computeBaseBuildThreshold(
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
  final minRegimentFloor = computeMinRegimentFloor(
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

  EconomyBuildPassGate skippedGate() => EconomyBuildPassGate(
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
  return EconomyBuildPassGate(
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
