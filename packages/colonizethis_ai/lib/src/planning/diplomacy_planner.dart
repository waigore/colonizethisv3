import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
import 'observer_goal_phase.dart';
export 'colonial_pressure.dart'
    show
        consolidateGainsSoleGpPeaceTarget,
        criticalOwHoldPeaceTargets,
        hasUninvadedOldWorldMinor,
        isOldWorldGpOnlyInvadableFrontier,
        isStalledOldWorldGpBlockerFocus,
        primaryInvadableOldWorldGpBlocker,
        quotaMetBelowQuotaAtWarPeaceTargets,
        quotaMetFutileBelowQuotaGpPeaceTargets,
        stalledBelowQuotaGpLeadPeaceTargets,
        belowQuotaPeerGpPeaceTargets,
        defaultStartGpPeaceTargets,
        defaultStartFutileMinorPeaceTargets,
        nearQuotaHoldPeaceTargets,
        unwinnableSoleGpFrontierPeaceTarget;
import 'planner_context.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';
import 'diplomacy_planner_declare_war_targets.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_peace_targets.dart';
import 'diplomacy_planner_result.dart';
import 'phase_planner_declare_war_targets.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_peace_targets.dart';

export 'diplomacy_planner_declare_war_targets.dart';
export 'diplomacy_planner_peace_targets.dart';
export 'diplomatic_candidate_scoring.dart'
    show computeDiplomaticCandidateScores;
export 'war_desire_calculator.dart' show computeWarDesireScore;
export 'diplomacy_planner_result.dart'
    show DiplomacyPlannerPass, DiplomacyPlannerResult;

final _log = packageLogger();

// Top-level declare-war target helpers live in
// `diplomacy_planner_declare_war_targets.dart` and are re-exported by this
// file so existing callers (and tests) keep their import paths unchanged
// (Refs #2509). Kept here only as a comment marker for the prior content.

Orders runDiplomacyPlanner({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
}) => runDiplomacyPlannerWithResult(ctx: ctx, snapshot: snapshot).orders;

int _resolveDiplomacyPlannerWeight({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  var weight = ctx.resolveDiplomacyBaseWeight();
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.provincesToVictory >
          kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 25) {
    weight = 25;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kFewOldWorldProvincesDefendThreshold &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 20) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 20;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      snapshot.conquest.oldWorldProvincesOwned <=
          kStalledOldWorldProvinceThreshold &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 15) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 15;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty &&
      weight < kDiplomacyDeclareWarMinWeightWhenStalled + 20) {
    weight = kDiplomacyDeclareWarMinWeightWhenStalled + 20;
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      hasColonialAcquisitionTargets(snapshot.colonial) &&
      weight < kDiplomacyDeclareWarMinWeightWhenColonialPressure) {
    weight = kDiplomacyDeclareWarMinWeightWhenColonialPressure;
  }
  if (pass != DiplomacyPlannerPass.declareWarOnly &&
      (stalledOwExpansionNeedsPeacePass(game: ctx.game, snapshot: snapshot) ||
          multiFrontNonBlockerGpPeaceTargets(
            game: ctx.game,
            snapshot: snapshot,
          ).isNotEmpty) &&
      weight < 25) {
    weight = 25;
  }
  return weight;
}

List<DiplomaticOrder> _suggestDiplomacyCandidates({
  required PlannerContext ctx,
  required DiplomacyPlannerPass pass,
}) => pass == DiplomacyPlannerPass.declareWarOnly
    ? ctx.suggestionAPI.suggestDeclareWarOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.orders,
      )
    : ctx.suggestionAPI.suggestDiplomaticOrders(
        ctx.view,
        ctx.game,
        ctx.topology,
        ctx.orders,
      );

List<DiplomaticOrder> _filterDiplomacyCandidatesForPass({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required List<DiplomaticOrder> candidates,
}) {
  var filtered = candidates;
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final atWarWithGp = snapshot.threats.atWarWith.any(
      (id) => ctx.game.playerById(id) != null,
    );
    if (atWarWithGp) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                !ctx.game.tribes.any((t) => t.id == o.targetFactionId),
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    final provinceOwner = getProvinceOwnerMap(ctx.game);
    final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) {
        final owner = provinceOwner[pid];
        return owner != null && ctx.game.minorNations.any((m) => m.id == owner);
      },
    );
    if (minorsOwnInvadable) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                !ctx.game.tribes.any((t) => t.id == o.targetFactionId),
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final gpWars = snapshot.threats.atWarWith
        .where((id) => ctx.game.playerById(id) != null)
        .toList();
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: ctx.game,
      snapshot: snapshot,
    );
    final consolidateGpFronts =
        gpWars.length > 1 ||
        (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
            gpWars.isNotEmpty);
    final gpOnlyFrontier = isOldWorldGpOnlyInvadableFrontier(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (blocker != null && gpOnlyFrontier) {
      final mutualPlateauBlocker = isMutualBelowQuotaPlateauPeer(
        ownOw: snapshot.conquest.oldWorldProvincesOwned,
        partnerOw: provinceCountOwnedBy(ctx.game, blocker),
      );
      if (!mutualPlateauBlocker) {
        filtered = filtered
            .where(
              (o) =>
                  o.type != DiplomaticOrderType.declareWar ||
                  o.targetFactionId == blocker,
            )
            .toList();
      }
    } else if (blocker != null && consolidateGpFronts) {
      filtered = filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar ||
                ctx.game.playerById(o.targetFactionId) == null ||
                o.targetFactionId == blocker,
          )
          .toList();
    }
  }
  if (pass == DiplomacyPlannerPass.nonDeclareWarOnly &&
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
    final blocker = primaryInvadableOldWorldGpBlocker(
      game: ctx.game,
      snapshot: snapshot,
    );
    final allowBlockerPeace =
        blocker != null &&
        unwinnableSoleGpFrontierPeaceTarget(
              game: ctx.game,
              snapshot: snapshot,
            ) ==
            blocker;
    filtered = filtered
        .where(
          (o) =>
              o.type != DiplomaticOrderType.alliance &&
              !(o.type == DiplomaticOrderType.offerPeace &&
                  o.targetFactionId == blocker &&
                  !allowBlockerPeace),
        )
        .toList();
  }
  final existingThisTurn =
      ctx.orders.diplomaticOrdersByPlayerId[ctx.nationId] ?? const [];
  final declaredThisTurn = <String>{
    for (final o in existingThisTurn)
      if (o.type == DiplomaticOrderType.declareWar) o.targetFactionId,
  };
  switch (pass) {
    case DiplomacyPlannerPass.declareWarOnly:
    case DiplomacyPlannerPass.all:
      return filtered;
    case DiplomacyPlannerPass.nonDeclareWarOnly:
      return filtered
          .where(
            (o) =>
                o.type != DiplomaticOrderType.declareWar &&
                !declaredThisTurn.contains(o.targetFactionId) &&
                !existingThisTurn.any(
                  (existing) =>
                      existing.type == o.type &&
                      existing.targetFactionId == o.targetFactionId,
                ),
          )
          .toList();
  }
}

DiplomacyPlannerResult? _forcedInvadableGpDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required String? Function({
    required Game game,
    required AIWorldSnapshot snapshot,
  })
  targetFor,
  required String logLabel,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final target = targetFor(game: ctx.game, snapshot: snapshot);
  if (target == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    '$logLabel=$target',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: target,
      ),
    ]),
    declaredWarTargetFactionId: target,
  );
}

DiplomacyPlannerResult? _plateauGpBlockerDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (hasUninvadedOldWorldMinor(game: ctx.game, snapshot: snapshot)) {
    return null;
  }
  if (!isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
    return null;
  }
  return _forcedInvadableGpDeclarePlannerResultIfNeeded(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    targetFor: stalledGpBlockerDeclareWarTarget,
    logLabel: 'gpBlocker',
  );
}

DiplomacyPlannerResult? _stalledInvadableGpOwnerDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) => _forcedInvadableGpDeclarePlannerResultIfNeeded(
  ctx: ctx,
  snapshot: snapshot,
  pass: pass,
  targetFor: stalledInvadableGpOwnerDeclareTarget,
  logLabel: 'stalledInvadableGp',
);

DiplomacyPlannerResult? _defaultStartOwMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = defaultStartOwMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    'defaultStartMinor=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: minorTarget,
      ),
    ]),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _belowQuotaUninvadedMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = belowQuotaUninvadedMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    'belowQuotaMinor=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: minorTarget,
      ),
    ]),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _plateauOwMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = plateauOwMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    'plateauMinor=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: minorTarget,
      ),
    ]),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _criticalWeakMinorDeclarePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final minorTarget = criticalWeakUninvadedMinorDeclareTarget(
    game: ctx.game,
    snapshot: snapshot,
  );
  if (minorTarget == null) {
    return null;
  }
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} target=$minorTarget',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: minorTarget,
      ),
    ]),
    declaredWarTargetFactionId: minorTarget,
  );
}

DiplomacyPlannerResult? _forcedDeclareWarPlannerResult({
  required PlannerContext ctx,
  required String target,
  required String logLabel,
}) {
  _log.i(
    'diplomacy forced declareWar nationId=${ctx.nationId} '
    '$logLabel=$target',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: target,
      ),
    ]),
    declaredWarTargetFactionId: target,
  );
}

/// When [phasePlan] is set, declare-war targets come only from the phase
/// planners via [gpExpandDeclareWarTargetFromPhasePlan] and
/// [gpColonialDeclareWarTargetFromPhasePlan] (Refs #2509 S5).
DiplomacyPlannerResult? _phasePlannerDeclareWarPlannerResultIfNeeded({
  required PlannerContext ctx,
  required DiplomacyPlannerPass pass,
  PhasePlanOutcome? phasePlan,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly || phasePlan == null) {
    return null;
  }
  final expandTarget = gpExpandDeclareWarTargetFromPhasePlan(phasePlan);
  if (expandTarget != null) {
    return _forcedDeclareWarPlannerResult(
      ctx: ctx,
      target: expandTarget,
      logLabel: 'phaseExpand',
    );
  }
  final colonialTarget = gpColonialDeclareWarTargetFromPhasePlan(phasePlan);
  if (colonialTarget != null) {
    return _forcedDeclareWarPlannerResult(
      ctx: ctx,
      target: colonialTarget,
      logLabel: 'phaseColonial',
    );
  }
  return null;
}

DiplomacyPlannerResult? _stalledPeacePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  PhasePlanOutcome? phasePlan,
}) {
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  final peaceTargets = phasePlan != null
      ? gpPeaceTargetsFromPhasePlan(phasePlan)
      : collectStalledGreatPowerPeaceTargets(
          game: ctx.game,
          snapshot: snapshot,
        );
  if (peaceTargets.isEmpty) {
    return null;
  }
  final peaceOrders = [
    for (final peaceTarget in peaceTargets)
      DiplomaticOrder(
        type: DiplomaticOrderType.offerPeace,
        targetFactionId: peaceTarget,
      ),
  ];
  _log.i(
    'diplomacy forced offerPeace nationId=${ctx.nationId} '
    'targets=${peaceOrders.map((o) => o.targetFactionId).toList()}',
  );
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, peaceOrders),
  );
}

/// Best declare-war candidate targeting an OW minor (EXPAND minor-first).
///
/// Prefers positive scores; when all minor scores are zero, picks the stable
/// lowest [DiplomaticOrder.targetFactionId] among minor targets.
int? _pickMinorDeclareCandidateIndex({
  required PlannerContext ctx,
  required List<DiplomaticOrder> candidates,
  required List<int> scores,
}) {
  var bestPositiveIdx = -1;
  var bestPositiveScore = 0;
  var bestZeroIdx = -1;
  String? bestZeroFactionId;
  for (var i = 0; i < candidates.length; i++) {
    final order = candidates[i];
    if (order.type != DiplomaticOrderType.declareWar) {
      continue;
    }
    if (!ctx.game.minorNations.any((m) => m.id == order.targetFactionId)) {
      continue;
    }
    final score = scores[i];
    if (score > 0) {
      if (score > bestPositiveScore || bestPositiveIdx < 0) {
        bestPositiveScore = score;
        bestPositiveIdx = i;
      }
      continue;
    }
    final factionId = order.targetFactionId;
    if (bestZeroFactionId == null ||
        factionId.compareTo(bestZeroFactionId) < 0) {
      bestZeroFactionId = factionId;
      bestZeroIdx = i;
    }
  }
  if (bestPositiveIdx >= 0) {
    return bestPositiveIdx;
  }
  return bestZeroIdx < 0 ? null : bestZeroIdx;
}

DiplomaticOrder? _chooseDiplomaticOrder({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required List<DiplomaticOrder> candidates,
  required List<int> scores,
}) {
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    if (isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot) &&
        hasUninvadedOldWorldMinor(game: ctx.game, snapshot: snapshot)) {
      final minorIdx = _pickMinorDeclareCandidateIndex(
        ctx: ctx,
        candidates: candidates,
        scores: scores,
      );
      if (minorIdx != null) {
        return candidates[minorIdx];
      }
    }
    final forcedBlocker = stalledGpBlockerDeclareWarTarget(
      game: ctx.game,
      snapshot: snapshot,
    );
    if (forcedBlocker != null) {
      return DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: forcedBlocker,
      );
    }
    if (isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
        snapshot.conquest.provincesToVictory >
            kConquerScoreFloorProvincesToVictoryThreshold) {
      final idx = _pickHighestScoreIndex(scores);
      return idx == null ? null : candidates[idx];
    }
  }
  return selectWeightedCandidate(
    candidates: candidates,
    scores: scores,
    seed: ctx.seeds.diplomacySeed,
  );
}

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
  PhasePlanOutcome? phasePlan,
}) {
  // Survival peace must run even when diplomacy weight is low or suggestion
  // APIs return no candidates (observer seed-42 gp3/gp6; Refs #2509).
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    final peaceResult = _stalledPeacePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
      phasePlan: phasePlan,
    );
    if (peaceResult != null) {
      return peaceResult;
    }
  }
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    final phaseDeclareResult = _phasePlannerDeclareWarPlannerResultIfNeeded(
      ctx: ctx,
      pass: pass,
      phasePlan: phasePlan,
    );
    if (phaseDeclareResult != null) {
      return phaseDeclareResult;
    }
    // Legacy colonial_pressure declare-war ratchet runs as a fallback when
    // the phase-planner adapter returns no target (Refs #2509 S5 migration:
    // phase plan is authoritative when it surfaces a target, otherwise the
    // legacy ratchet preserves below-quota / GP-only frontier declare
    // behaviour pinned by `domain_planner_orchestrator_expand_gp_only_blocker_declare_test.dart`
    // and `war_declaration_target_scoring_warmonger_test.dart`; the legacy
    // helpers are retired structurally in S1).
    final defaultStartMinorResult =
        _defaultStartOwMinorDeclarePlannerResultIfNeeded(
          ctx: ctx,
          snapshot: snapshot,
          pass: pass,
        );
    if (defaultStartMinorResult != null) {
      return defaultStartMinorResult;
    }
    final plateauMinorResult = _plateauOwMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (plateauMinorResult != null) {
      return plateauMinorResult;
    }
    final belowQuotaMinorResult =
        _belowQuotaUninvadedMinorDeclarePlannerResultIfNeeded(
          ctx: ctx,
          snapshot: snapshot,
          pass: pass,
        );
    if (belowQuotaMinorResult != null) {
      return belowQuotaMinorResult;
    }
    final minorWarResult = _criticalWeakMinorDeclarePlannerResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
    );
    if (minorWarResult != null) {
      return minorWarResult;
    }
    if (isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
      final blockerDeclareResult =
          _plateauGpBlockerDeclarePlannerResultIfNeeded(
            ctx: ctx,
            snapshot: snapshot,
            pass: pass,
          );
      if (blockerDeclareResult != null) {
        return blockerDeclareResult;
      }
    }
    final stalledGpDeclareResult =
        _stalledInvadableGpOwnerDeclarePlannerResultIfNeeded(
          ctx: ctx,
          snapshot: snapshot,
          pass: pass,
        );
    if (stalledGpDeclareResult != null) {
      return stalledGpDeclareResult;
    }
  }
  final weight = _resolveDiplomacyPlannerWeight(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
  );
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=${ctx.nationId} weight=$weight < 25');
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final filtered = _filterDiplomacyCandidatesForPass(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    candidates: _suggestDiplomacyCandidates(ctx: ctx, pass: pass),
  );
  if (filtered.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final scores = computeDiplomaticCandidateScores(
    candidates: filtered,
    nationId: ctx.nationId,
    game: ctx.game,
    snapshot: snapshot,
    config: ctx.config,
    primaryGoal: ctx.primaryGoal,
    sameTurnPriorDiplomaticOrders: ctx.sameTurnPriorDiplomaticOrders,
    phasePlan: phasePlan,
  );

  final candidateDesc = filtered
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=${ctx.nationId} hiddenAgendaId=${ctx.config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final chosen = _chooseDiplomaticOrder(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    candidates: filtered,
    scores: scores,
  );
  if (chosen == null) return DiplomacyPlannerResult(orders: ctx.orders);
  _log.i(
    'diplomacy chosen nationId=${ctx.nationId} '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""}',
  );
  final nextOrders = ctx.orders.appendDiplomaticOrders(ctx.nationId, [chosen]);
  final declaredTarget = chosen.type == DiplomaticOrderType.declareWar
      ? chosen.targetFactionId
      : null;
  return DiplomacyPlannerResult(
    orders: nextOrders,
    declaredWarTargetFactionId: declaredTarget,
  );
}

/// Deterministic tie-break: lowest candidate index wins equal scores.
int? _pickHighestScoreIndex(List<int> scores) {
  var bestIdx = -1;
  var bestScore = 0;
  for (var i = 0; i < scores.length; i++) {
    final score = scores[i];
    if (score <= 0) continue;
    if (score > bestScore || bestIdx < 0) {
      bestScore = score;
      bestIdx = i;
    }
  }
  return bestIdx < 0 ? null : bestIdx;
}
