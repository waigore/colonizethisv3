import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';
import 'expand_phase_planner.dart';
import 'observer_goal_phase.dart';
import 'planner_context.dart';
import '../util/orders_extensions.dart';
import 'diplomacy_planner_pass_helpers.dart';
import 'diplomatic_candidate_scoring.dart';
import 'diplomacy_planner_result.dart';
import 'phase_planner_dispatch.dart';
import 'diplomacy_planner_pass_filter.dart';

final _log = packageLogger('diplomacy_planner');

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

DiplomacyPlannerResult runDiplomacyPlannerWithResult({
  required PlannerContext ctx,
  required AIWorldSnapshot snapshot,
  DiplomacyPlannerPass pass = DiplomacyPlannerPass.all,
  PhasePlanOutcome? phasePlan,
}) {
  // Survival peace must run even when diplomacy weight is low or suggestion
  // APIs return no candidates (observer seed-42 gp3/gp6; Refs #2509).
  if (pass != DiplomacyPlannerPass.declareWarOnly) {
    final peaceResult = stalledPeacePlannerResultIfNeeded(
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
    final phaseDeclareResult = phasePlannerDeclareWarPlannerResultIfNeeded(
      ctx: ctx,
      pass: pass,
      phasePlan: phasePlan,
    );
    if (phaseDeclareResult != null) {
      return phaseDeclareResult;
    }
    // Legacy declare-war ratchet runs as a fallback when the
    // phase-planner adapter returns no target (Refs #2509 post-S5:
    // phase plan is authoritative when it surfaces a target, otherwise the
    // legacy ratchet preserves below-quota / GP-only frontier declare
    // behaviour pinned by `domain_planner_orchestrator_expand_gp_only_blocker_declare_test.dart`
    // and `war_declaration_target_scoring_warmonger_test.dart`; the legacy
    // `colonial_pressure.dart` host was deleted in S1, the surviving
    // helpers are canonical in `expand_phase_planner.dart`).
    for (final shortcut in legacyMinorDeclareWarShortcuts) {
      final shortcutResult = legacyDeclareWarShortcutResultIfNeeded(
        ctx: ctx,
        snapshot: snapshot,
        pass: pass,
        shortcut: shortcut,
      );
      if (shortcutResult != null) {
        return shortcutResult;
      }
    }
    if (isOldWorldGpOnlyInvadableFrontier(game: ctx.game, snapshot: snapshot)) {
      final blockerDeclareResult = legacyDeclareWarShortcutResultIfNeeded(
        ctx: ctx,
        snapshot: snapshot,
        pass: pass,
        shortcut: legacyGpBlockerDeclareWarShortcut,
      );
      if (blockerDeclareResult != null) {
        return blockerDeclareResult;
      }
    }
    final stalledGpDeclareResult = legacyDeclareWarShortcutResultIfNeeded(
      ctx: ctx,
      snapshot: snapshot,
      pass: pass,
      shortcut: legacyStalledGpDeclareWarShortcut,
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
    if (_log.debugEnabled) {
      _log.d('diplomacy skipped nationId=${ctx.nationId} weight=$weight < 25');
    }
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final filtered = filterDiplomacyCandidatesForPass(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    candidates: _suggestDiplomacyCandidates(ctx: ctx, pass: pass),
  );
  if (filtered.isEmpty) {
    return DiplomacyPlannerResult(orders: ctx.orders);
  }

  final scores = computeDiplomaticCandidateScores(
    DiplomaticCandidateScoringInput(
      candidates: filtered,
      nationId: ctx.nationId,
      game: ctx.game,
      snapshot: snapshot,
      config: ctx.config,
      primaryGoal: ctx.primaryGoal,
      sameTurnPriorDiplomaticOrders: ctx.sameTurnPriorDiplomaticOrders,
      phasePlan: phasePlan,
    ),
  );

  if (_log.debugEnabled) {
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
  }

  final chosen = chooseDiplomaticOrder(
    ctx: ctx,
    snapshot: snapshot,
    pass: pass,
    candidates: filtered,
    scores: scores,
  );
  if (chosen == null) return DiplomacyPlannerResult(orders: ctx.orders);
  if (_log.infoEnabled) {
    _log.i(
      'diplomacy chosen nationId=${ctx.nationId} '
      'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""}',
    );
  }
  final nextOrders = ctx.orders.appendDiplomaticOrders(ctx.nationId, [chosen]);
  final declaredTarget = chosen.type == DiplomaticOrderType.declareWar
      ? chosen.targetFactionId
      : null;
  return DiplomacyPlannerResult(
    orders: nextOrders,
    declaredWarTargetFactionId: declaredTarget,
  );
}
