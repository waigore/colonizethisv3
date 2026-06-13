import 'dart:math' as math;

import 'goal_manager.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

/// Computes the research planner threshold the same way [runResearchPlanner]
/// does: `40 - getAgendaResearchModifier(hiddenAgendaId)`.
///
/// Pure and deterministic — identical inputs always yield identical
/// outputs. Used by the orchestrator (Refs #2832 trace
/// decision-provenance) to populate `thresholds.domainGates.thresholds.research`
/// without re-running the planner.
int computeResearchThreshold({required PlannerContext ctx}) =>
    40 - getAgendaResearchModifier(ctx.config.hiddenAgendaId);

/// Whether the research planner would execute weighted-pick selection
/// instead of short-circuiting on its threshold gate.
///
/// Mirrors the predicate inside [runResearchPlanner]: research runs when
/// `primaryGoal == tech` **or** `domainWeights.research >=
/// computeResearchThreshold(ctx)`. The presence of research candidates
/// is checked separately by callers because the suggestion API is a
/// side-effecting call this helper does not re-issue.
///
/// Pure and deterministic — identical inputs always yield identical
/// outputs.
bool researchPlannerWillRun({required PlannerContext ctx}) {
  if (ctx.primaryGoal == StrategicGoal.tech) {
    return true;
  }
  return ctx.domainWeights.research >= computeResearchThreshold(ctx: ctx);
}

Orders runResearchPlanner({required PlannerContext ctx}) {
  final researchCandidates = ctx.suggestionAPI.suggestResearchOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  final researchThreshold = computeResearchThreshold(ctx: ctx);
  if (researchCandidates.isEmpty ||
      (ctx.primaryGoal != StrategicGoal.tech &&
          ctx.domainWeights.research < researchThreshold)) {
    if (researchCandidates.isNotEmpty) {
      _log.d(
        'research skipped nationId=${ctx.nationId} threshold not met or no candidates',
      );
    }
    return ctx.orders;
  }

  final thresholds = resolveThresholds(
    ctx.config.personalityId,
    overrides: ctx.config.parameterOverrides,
  );
  final chosen = selectWeightedCandidate(
    candidates: researchCandidates,
    seed: ctx.seeds.researchSeed,
    useIntRoll: true,
    score: (o) {
      final tech = techById(o.techId);
      final category = tech?.category ?? '';
      final w = category == 'transport'
          ? thresholds.researchNaval
          : category == 'military'
          ? thresholds.researchMilitary
          : category == 'gathering'
          ? thresholds.researchEconomic
          : thresholds.researchExploration;
      return math.max(1, w);
    },
  );
  _log.d(
    'research eval nationId=${ctx.nationId} researchThreshold=$researchThreshold '
    'candidateCount=${researchCandidates.length}',
  );
  if (chosen == null) return ctx.orders;

  _log.i(
    'research chosen nationId=${ctx.nationId} techId=${chosen.techId}',
  );
  return ctx.orders.appendResearchOrders(ctx.nationId, [chosen]);
}
