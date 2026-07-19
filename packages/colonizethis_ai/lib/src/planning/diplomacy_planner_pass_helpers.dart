import '../perception/perception_snapshot.dart';
import '../util/ai_random_utils.dart';
import '../util/faction_query.dart';
import '../util/orders_extensions.dart';
import 'diplomacy_planner_declare_war_targets.dart';
import 'diplomacy_planner_result.dart';
import 'expand_peace_frontier_helpers.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_declare_war_targets.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_peace_targets.dart';
import 'planner_context.dart';
import 'planning_imports.dart';

final _log = packageLogger('diplomacy_planner_pass_helpers');

typedef DeclareWarTargetSelector =
    String? Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

typedef DeclareWarShortcutPreGate =
    bool Function({
      required Game game,
      required AIWorldSnapshot snapshot,
    });

final class DeclareWarShortcut {
  const DeclareWarShortcut({
    required this.targetFor,
    required this.logLabel,
    this.preGate,
  });

  final DeclareWarTargetSelector targetFor;
  final String logLabel;
  final DeclareWarShortcutPreGate? preGate;
}

bool plateauGpBlockerDeclarePreGate({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return false;
  }
  if (hasUninvadedOldWorldMinor(
    game: game,
    snapshot: snapshot,
  )) {
    return false;
  }
  return isOldWorldGpOnlyInvadableFrontier(
    game: game,
    snapshot: snapshot,
  );
}

const legacyMinorDeclareWarShortcuts = <DeclareWarShortcut>[
  DeclareWarShortcut(
    targetFor: defaultStartOwMinorDeclareTarget,
    logLabel: 'defaultStartMinor',
  ),
  DeclareWarShortcut(
    targetFor: plateauOwMinorDeclareTarget,
    logLabel: 'plateauMinor',
  ),
  DeclareWarShortcut(
    targetFor: belowQuotaUninvadedMinorDeclareTarget,
    logLabel: 'belowQuotaMinor',
  ),
  DeclareWarShortcut(
    targetFor: criticalWeakUninvadedMinorDeclareTarget,
    logLabel: 'target',
  ),
];

const legacyGpBlockerDeclareWarShortcut = DeclareWarShortcut(
  targetFor: stalledGpBlockerDeclareWarTarget,
  logLabel: 'gpBlocker',
  preGate: plateauGpBlockerDeclarePreGate,
);

const legacyStalledGpDeclareWarShortcut = DeclareWarShortcut(
  targetFor: stalledInvadableGpOwnerDeclareTarget,
  logLabel: 'stalledInvadableGp',
);

DiplomacyPlannerResult? legacyDeclareWarShortcutResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required DeclareWarShortcut shortcut,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  if (shortcut.preGate != null &&
      !shortcut.preGate!(
        game: ctx.game,
        snapshot: snapshot,
      )) {
    return null;
  }
  final target = shortcut.targetFor(game: ctx.game, snapshot: snapshot);
  if (target == null) {
    return null;
  }
  return forcedDeclareWarPlannerResult(
    ctx: ctx,
    target: target,
    logLabel: shortcut.logLabel,
  );
}

DiplomacyPlannerResult? forcedDeclareWarPlannerResult({
  required PlannerContext ctx,
  required String target,
  required String logLabel,
}) {
  if (_log.infoEnabled) {
    _log.i(
      'diplomacy forced declareWar nationId=${ctx.nationId} '
      '$logLabel=$target',
    );
  }
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
DiplomacyPlannerResult? phasePlannerDeclareWarPlannerResultIfNeeded({
  required PlannerContext ctx,
  required DiplomacyPlannerPass pass,
  PhasePlanOutcome? phasePlan,
}) {
  if (pass != DiplomacyPlannerPass.declareWarOnly || phasePlan == null) {
    return null;
  }
  final expandTarget = gpExpandDeclareWarTargetFromPhasePlan(phasePlan);
  if (expandTarget != null) {
    return forcedDeclareWarPlannerResult(
      ctx: ctx,
      target: expandTarget,
      logLabel: 'phaseExpand',
    );
  }
  final colonialTarget = gpColonialDeclareWarTargetFromPhasePlan(phasePlan);
  if (colonialTarget != null) {
    return forcedDeclareWarPlannerResult(
      ctx: ctx,
      target: colonialTarget,
      logLabel: 'phaseColonial',
    );
  }
  return null;
}

DiplomacyPlannerResult? stalledPeacePlannerResultIfNeeded({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  PhasePlanOutcome? phasePlan,
}) {
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    return null;
  }
  // When a phase plan is threaded through (the canonical post-S5 production
  // path) the GP-only `planExpandPeace` adapter drops every survival /
  // expand-ratchet / peer-stalled peace decider the no-`phasePlan`
  // `collectStalledGreatPowerPeaceTargets` fallback emits. Union the full
  // fallback back in via [productionPeaceTargetsFromPhasePlan] (Refs #2509
  // S5; #2847 § H5 tribe-distraction + § H6 ratchet/survival restoration).
  final peaceTargets = phasePlan != null
      ? productionPeaceTargetsFromPhasePlan(
          game: ctx.game,
          snapshot: snapshot,
          phasePlan: phasePlan,
        )
      : collectStalledGreatPowerPeaceTargets(
          game: ctx.game,
          snapshot: snapshot,
        ).toList()
        ..sort();
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
  if (_log.infoEnabled) {
    _log.i(
      'diplomacy forced offerPeace nationId=${ctx.nationId} '
      'targets=${peaceOrders.map((o) => o.targetFactionId).toList()}',
    );
  }
  return DiplomacyPlannerResult(
    orders: ctx.orders.appendDiplomaticOrders(ctx.nationId, peaceOrders),
  );
}

/// Best declare-war candidate targeting an OW minor (EXPAND minor-first).
///
/// Prefers positive scores; when all minor scores are zero, picks the stable
/// lowest [DiplomaticOrder.targetFactionId] among minor targets.
int? pickMinorDeclareCandidateIndex({
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
    if (!isMinorFaction(ctx.game, order.targetFactionId)) {
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

DiplomaticOrder? chooseDiplomaticOrder({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  required DiplomacyPlannerPass pass,
  required List<DiplomaticOrder> candidates,
  required List<int> scores,
}) {
  if (pass == DiplomacyPlannerPass.declareWarOnly) {
    if (isOldWorldGpOnlyInvadableFrontier(
          game: ctx.game,
          snapshot: snapshot,
        ) &&
        hasUninvadedOldWorldMinor(
          game: ctx.game,
          snapshot: snapshot,
        )) {
      final minorIdx = pickMinorDeclareCandidateIndex(
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
      final idx = pickHighestScoreIndex(scores);
      return idx == null ? null : candidates[idx];
    }
  }
  return selectWeightedCandidate(
    candidates: candidates,
    scores: scores,
    seed: ctx.seeds.diplomacySeed,
  );
}

/// Deterministic tie-break: lowest candidate index wins equal scores.
int? pickHighestScoreIndex(List<int> scores) {
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
