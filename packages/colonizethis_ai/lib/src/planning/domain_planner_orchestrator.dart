import 'dart:math' as math;

import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'army_conquest_prep.dart';
import 'colonial_pressure.dart';
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
    economyPlan: economyPlan,
    tileMapByRegion: tileMapByRegion,
    emit: emit,
  );

  ctx = ctx.withOrders(runMovePlanner(ctx: ctx));
  emit('aiStageC');

  final skipGpOnlyBlockerPeace = shouldSkipBelowQuotaGpOnlyBlockerPeacePass(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (!skipGpOnlyBlockerPeace) {
    final peaceBeforeConquestResult = runDiplomacyPlannerWithResult(
      ctx: ctx,
      snapshot: snapshot,
      pass: DiplomacyPlannerPass.nonDeclareWarOnly,
    );
    ctx = ctx.withOrders(peaceBeforeConquestResult.orders);
  }

  final declareWarResult = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.declareWarOnly,
  );
  ctx = ctx.withOrders(declareWarResult.orders);
  final armyMovesBeforeConquest =
      ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
  final stalledOldWorldExpansion = isStalledOldWorldExpansion(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  final observerQuotaPressure = isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  final conquestDeclaredWarTarget = stalledConquestDeclaredWarTarget(
    game: ctx.game,
    nationId: nationId,
    snapshot: snapshot,
    declaredThisTurn: declareWarResult.declaredWarTargetFactionId,
  );
  final conquestPasses = stalledOldWorldExpansion || observerQuotaPressure
      ? kStalledConquestArmyMovePasses
      : 1;
  for (var pass = 0; pass < conquestPasses; pass++) {
    final movesBeforePass =
        ctx.orders.armyMoveOrdersByPlayerId[nationId]?.length ?? 0;
    ctx = ctx.withOrders(
      runConquestArmyMovePlanner(
        ctx: ctx,
        snapshot: snapshot,
        declaredWarTargetFactionId: conquestDeclaredWarTarget,
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
  if (!stalledOldWorldExpansion && !observerQuotaPressure) {
    ctx = ctx.withOrders(
      runArmyMovePlanner(
        ctx: ctx,
        provincesToVictory: snapshot.conquest.provincesToVictory,
      ),
    );
  }
  emit('aiStageD');

  ctx = ctx.withOrders(
    runNavalPlanner(ctx: ctx, colonial: snapshot.colonial),
  );
  emit('aiStageE');

  // Late peace pass undoes same-turn declare-war on the OW frontier blocker
  // (observer seed-42 gp5/gp6; Refs #2509).
  if (!skipGpOnlyBlockerPeace) {
    ctx = ctx.withOrders(
      runDiplomacyPlannerWithResult(
        ctx: ctx,
        snapshot: snapshot,
        pass: DiplomacyPlannerPass.nonDeclareWarOnly,
      ).orders,
    );
  }
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
  required EconomyPlan economyPlan,
  Map<String, TileMapResult>? tileMapByRegion,
  required void Function(String phaseId) emit,
}) {
  var result = ctx.orders;
  final domainWeights = ctx.domainWeights;

  emit('suggestionPools');
  final workCandidates = ctx.suggestionAPI.suggestWorkOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    result,
    tileMapByRegion: tileMapByRegion,
  );
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
      40 - (hasSpyWork ? getAgendaSpyOrderModifier(ctx.config.hiddenAgendaId) : 0);
  final colonialPressure = hasColonialAcquisitionTargets(snapshot.colonial) &&
      !isStalledOldWorldGpBlockerFocus(game: ctx.game, snapshot: snapshot);
  if (colonialPressure || snapshot.colonial.newWorldProvincesOwned > 0) {
    workThreshold = math.min(workThreshold, kColonialCivilianWorkThresholdCap);
  }
  final runFullAiCivilianWork =
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

  var buildThreshold = 30 - getAgendaBuildOrderModifier(ctx.config.hiddenAgendaId);
  if (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    buildThreshold = math.min(buildThreshold, 15);
  }
  if (isStalledOldWorldGpBlockerFocus(game: ctx.game, snapshot: snapshot)) {
    buildThreshold = math.min(buildThreshold, 8);
  }
  final colonialBuildCap = colonialBuildOrderThresholdCap(snapshot.colonial);
  if (colonialBuildCap != null) {
    buildThreshold = math.min(buildThreshold, colonialBuildCap);
  }
  final regimentCount = regimentCountForPlayer(ctx.game, ctx.nationId);
  final observerQuotaPressure = isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  final needRegimentsToExpand = observerQuotaPressure &&
      regimentCount == 0 &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  final zeroRegimentsAtWar = regimentCount == 0 &&
      snapshot.threats.atWarWith.isNotEmpty;
  final criticallyWeakBelowQuota = observerQuotaPressure &&
      (snapshot.conquest.oldWorldProvincesOwned <=
              kFewOldWorldProvincesDefendThreshold ||
          zeroRegimentsAtWar ||
          needRegimentsToExpand);
  final criticallyWeakNoGpWar =
      snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      !snapshot.threats.atWarWith.any(
        (id) => ctx.game.playerById(id) != null,
      );
  final gpBlocker = isStalledOldWorldGpBlockerFocus(
        game: ctx.game,
        snapshot: snapshot,
      )
      ? primaryInvadableOldWorldGpBlocker(game: ctx.game, snapshot: snapshot)
      : null;
  final atWarWithGpBlocker = gpBlocker != null &&
      snapshot.threats.atWarWith.contains(gpBlocker);
  var minRegimentFloor = atWarWithGpBlocker
      ? kStalledMinRegimentCountWhenGpBlockerAtWar
      : kStalledMinRegimentCountWhenAtWar;
  if (atWarWithGpBlocker && gpBlocker != null) {
    final deficit = provinceCountOwnedBy(ctx.game, gpBlocker) -
        snapshot.conquest.oldWorldProvincesOwned;
    if (deficit > 0) {
      minRegimentFloor += deficit * kStalledMinRegimentCountPerProvinceDeficitVsBlocker;
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
  final forceRegimentRebuild =
      (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) ||
          criticallyWeakBelowQuota) &&
      (snapshot.threats.atWarWith.isNotEmpty || needRegimentsToExpand) &&
      regimentCount < minRegimentFloor;
  if (forceRegimentRebuild || atWarWithGpBlocker) {
    buildThreshold = 0;
  }
  _log.d(
    'build eval nationId=${ctx.nationId} buildThreshold=$buildThreshold '
    'buildCandidatesCount=${buildCandidates.length} '
    'regimentCount=$regimentCount forceRegimentRebuild=$forceRegimentRebuild',
  );
  if (buildCandidates.isNotEmpty &&
      (domainWeights.economy >= buildThreshold || forceRegimentRebuild)) {
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
        militaryRebuildCrisis: forceRegimentRebuild &&
            (atWarWithGpBlocker ||
                (regimentCount <= kStalledMilitaryRebuildCrisisRegimentCap &&
                    !(observerQuotaPressure &&
                        snapshot.conquest.oldWorldProvincesOwned >
                            kFewOldWorldProvincesDefendThreshold))),
      ),
    );
    if (chosen != null) {
      _log.i('build chosen nationId=${ctx.nationId} unitType=${chosen.unitType}');
      result = result.appendBuildOrders(ctx.nationId, [chosen]);
    }
  } else if (buildCandidates.isNotEmpty) {
    _log.d('build skipped nationId=${ctx.nationId} weight below threshold');
  }
  emit('aiStageB');
  return ctx.withOrders(result);
}
