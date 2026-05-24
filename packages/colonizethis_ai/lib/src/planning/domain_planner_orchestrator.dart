import 'dart:math' as math;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'army_conquest_prep.dart';
import 'colonial_pressure.dart';
import 'phase_planner_conquest_filter.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_planner_expand_economy.dart';
import 'phase_planner_work_order_filter.dart';
import 'planning_imports.dart';
import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/orders_extensions.dart';
import 'build_planner.dart';
import 'conquest_planner.dart';
import 'diplomacy_planner.dart';
import 'domain_planner_outcome.dart';
import 'move_planner.dart';
import 'naval_planner.dart';
import 'planner_context.dart';
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
  Orders? sameTurnPriorDiplomaticOrders,
}) {
  void emit(String phaseId) => onStagedPlannerProgress?.call(phaseId);

  final phasePlan = runPhasePlanners(
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
  );

  ctx = _runEconomyDomainPlanners(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: phasePlan,
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    emit: emit,
  );

  ctx = ctx.withOrders(runMovePlanner(ctx: ctx));
  emit('aiStageC');

  final peaceBeforeConquestResult = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.nonDeclareWarOnly,
    phasePlan: phasePlan,
  );
  ctx = ctx.withOrders(peaceBeforeConquestResult.orders);

  final declareWarResult = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.declareWarOnly,
    phasePlan: phasePlan,
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
    phasePlan: phasePlan,
  );
  final conquestDeclaredWarTarget = stalledConquestDeclaredWarTarget(
    game: ctx.game,
    nationId: nationId,
    snapshot: snapshot,
    declaredThisTurn: declareWarResult.declaredWarTargetFactionId,
  );
  final conquestPasses = extraPassesActive ? kStalledConquestArmyMovePasses : 1;
  for (var pass = 0; pass < conquestPasses; pass++) {
    final movesBeforePass =
        ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
    ctx = ctx.withOrders(
      runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: conquestDeclaredWarTarget,
        phasePlan: phasePlan,
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

  ctx = ctx.withOrders(
    runNavalPlanner(ctx: ctx, snapshot: snapshot, phasePlan: phasePlan),
  );
  emit('aiStageE');

  // Late peace pass undoes same-turn declare-war on the OW frontier blocker
  // (observer seed-42 gp5/gp6; Refs #2509).
  ctx = ctx.withOrders(
    runDiplomacyPlannerWithResult(
      ctx: ctx,
      snapshot: snapshot,
      pass: DiplomacyPlannerPass.nonDeclareWarOnly,
      phasePlan: phasePlan,
    ).orders,
  );
  emit('aiStageF');

  ctx = ctx.withOrders(runResearchPlanner(ctx: ctx));
  emit('aiStageG');

  return DomainPlannerOutcome(
    orders: ctx.orders,
    declaredWarTargetFactionId: declareWarResult.declaredWarTargetFactionId,
    conquestArmyMoveCount: conquestArmyMoveCount,
  );
}

PlannerContext _runEconomyDomainPlanners({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
  required EconomyPlan economyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
  required void Function(String phaseId) emit,
}) {
  var result = ctx.orders;
  final domainWeights = ctx.domainWeights;

  emit('suggestionPools');
  var workCandidates = ctx.suggestionAPI.suggestWorkOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    result,
    tileMapByRegion: tileMapByRegion,
  );
  workCandidates = workCandidates
      .where((w) => !shouldSuppressWorkOrderFromPhasePlan(w, phasePlan))
      .toList();
  final buildCandidates = ctx.suggestionAPI.suggestBuildOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    result,
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
  if (developPhase) {
    workThreshold = math.min(workThreshold, kDevelopCivilianWorkThresholdCap);
  } else if (colonialPressure || snapshot.colonial.newWorldProvincesOwned > 0) {
    workThreshold = math.min(workThreshold, kColonialCivilianWorkThresholdCap);
  }
  final runFullAiCivilianWork =
      developPhase ||
      ctx.primaryGoal == StrategicGoal.expand ||
      domainWeights.economy >= workThreshold ||
      colonialPressure ||
      snapshot.colonial.newWorldProvincesOwned > 0;
  _log.d(
    'work eval nationId=${ctx.nationId} workThreshold=$workThreshold '
    'domainWeights.economy=${domainWeights.economy} primaryGoal=${ctx.primaryGoal} '
    'workCandidatesCount=${workCandidates.length}',
  );
  if (runFullAiCivilianWork) {
    final selection = selectFullAiCivilianWorkOrders(
      workSuggestions: workCandidates,
      view: ctx.view,
      game: ctx.game,
      tileMapByRegion: tileMapByRegion,
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
      result = result.appendWorkOrders(ctx.nationId, selection.workOrders);
    }
  } else if (workCandidates.isNotEmpty) {
    _log.d('work skipped nationId=${ctx.nationId} weight below threshold');
  }
  emit('aiStageA');

  result = _appendEconomyBuildOrders(
    ctx: ctx,
    snapshot: snapshot,
    phasePlan: phasePlan,
    economyPlan: economyPlan,
    orders: result,
    colonialPressure: colonialPressure,
    buildCandidates: buildCandidates,
    domainEconomyWeight: domainWeights.economy,
  );
  emit('aiStageB');
  return ctx.withOrders(result);
}

Orders _appendEconomyBuildOrders({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required PhasePlanOutcome phasePlan,
  required EconomyPlan economyPlan,
  required Orders orders,
  required bool colonialPressure,
  required List<BuildUnitOrder> buildCandidates,
  required int domainEconomyWeight,
}) {
  // Refs #2509 S5: derive below-quota OW build-pass routing from the
  // dispatched phase plan instead of recomputing
  // `isStalledOldWorldExpansion(ow)` / `isBelowObserverConquestQuota(ow)`
  // per build pass. Field-equal to `phase ∈ {EXPAND, COLONIAL-lite}` via
  // `resolvePhaseEconomyExpandQuotaPressureActive` (see
  // `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy build
  // slice). The EXPAND regiment-rebuild directive comes from
  // `expandEconomyPlanFromPhasePlan` (already computed once in
  // `runPhasePlanners`).
  final expandQuotaPressure = resolvePhaseEconomyExpandQuotaPressureActive(
    phasePlan: phasePlan,
  );
  final expandEconomy = expandEconomyPlanFromPhasePlan(phasePlan);

  var buildThreshold =
      30 - getAgendaBuildOrderModifier(ctx.config.hiddenAgendaId);
  if (expandQuotaPressure) {
    buildThreshold = math.min(buildThreshold, 15);
  }
  if (expandQuotaPressure &&
      isStalledOldWorldGpBlockerFocus(game: ctx.game, snapshot: snapshot)) {
    buildThreshold = math.min(buildThreshold, 8);
  }
  // Refs #2509 S5: derive the colonial build-order threshold cap from
  // the dispatched phase plan instead of calling
  // `colonialBuildOrderThresholdCap(snapshot.colonial)` (the
  // `colonial_pressure.dart` helper). The legacy helper had two arms
  // keyed on `hasColonialAcquisitionTargets(colonial)`, but the
  // orchestrator only invoked it inside the outer `if (colonialPressure)`
  // guard, where `colonialPressure` is the dispatched
  // `resolvePhaseEconomyColonialPressureActive` (active only under
  // COLONIAL). COLONIAL phase entry is itself gated on
  // `hasColonialAcquisitionTargets` via `observerGoalPhaseFor`, so the
  // first legacy arm was the only reachable arm — the second
  // `kColonialBuildOrderThresholdWhenOwnedNw` arm requires
  // `!hasColonialAcquisitionTargets`, which is structurally unreachable
  // inside the orchestrator's COLONIAL-pressure branch. The phase-derived
  // `int?` is therefore field-equal to the legacy compute at this call
  // site across every reachable `(ObserverGoalPhase, ColonialSummary)`
  // pair (see `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy
  // build colonial-cap slice).
  final colonialBuildCap = resolvePhaseEconomyColonialBuildOrderThresholdCap(
    phasePlan: phasePlan,
    colonial: snapshot.colonial,
  );
  if (colonialBuildCap != null) {
    buildThreshold = math.min(buildThreshold, colonialBuildCap);
  }
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
  final belowQuotaPeaceInsufficientRegiments =
      expandQuotaPressure &&
      isBelowQuotaPeaceInsufficientRegiments(
        oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
        regimentCount: regimentCount,
        atWarWithAnyGreatPower: atWarWithAnyGreatPower,
        hasInvadableProvinces:
            snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty,
      );
  final belowQuotaZeroRegimentsRebuild =
      expandQuotaPressure &&
      isBelowQuotaPeaceZeroRegimentsRebuild(
        oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
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
  final gpBlocker =
      expandQuotaPressure &&
          isStalledOldWorldGpBlockerFocus(game: ctx.game, snapshot: snapshot)
      ? primaryInvadableOldWorldGpBlocker(game: ctx.game, snapshot: snapshot)
      : null;
  final atWarWithGpBlocker =
      gpBlocker != null && snapshot.threats.atWarWith.contains(gpBlocker);
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
  final forceRegimentRebuild =
      (expandQuotaPressure || criticallyWeakBelowQuota) &&
      (snapshot.threats.atWarWith.isNotEmpty ||
          needRegimentsToExpand ||
          brokeBelowQuotaAtPeace ||
          belowQuotaPeaceInsufficientRegiments ||
          belowQuotaZeroRegimentsRebuild ||
          expandEconomy.forceCheapestRegimentBuild) &&
      regimentCount < minRegimentFloor;
  if (forceRegimentRebuild ||
      atWarWithGpBlocker ||
      expandEconomy.forceCheapestRegimentBuild) {
    buildThreshold = 0;
  }
  _log.d(
    'build eval nationId=${ctx.nationId} buildThreshold=$buildThreshold '
    'buildCandidatesCount=${buildCandidates.length} '
    'regimentCount=$regimentCount forceRegimentRebuild=$forceRegimentRebuild',
  );
  if (buildCandidates.isEmpty ||
      (domainEconomyWeight < buildThreshold && !forceRegimentRebuild)) {
    if (buildCandidates.isNotEmpty) {
      _log.d('build skipped nationId=${ctx.nationId} weight below threshold');
    }
    return orders;
  }
  var candidatesForBuild = buildCandidates;
  if (forceRegimentRebuild) {
    final regimentsOnly = buildCandidates
        .where((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType))
        .toList();
    if (regimentsOnly.isNotEmpty) {
      candidatesForBuild = regimentsOnly;
    }
  }
  final chosen = pickBuildOrder(
    ctx: ctx,
    input: BuildPickInput(
      buildCandidates: candidatesForBuild,
      cargoPreference: economyPlan.cargoPreference,
      provincesToVictory: snapshot.conquest.provincesToVictory,
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
      colonialPressure: colonialPressure,
      militaryRebuildCrisis:
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
    return orders;
  }
  _log.i('build chosen nationId=${ctx.nationId} unitType=${chosen.unitType}');
  return orders.appendBuildOrders(ctx.nationId, [chosen]);
}
