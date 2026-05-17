import 'dart:math' as math;

import 'goal_manager.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runResearchPlanner({required PlannerContext ctx}) {
  final researchCandidates = ctx.suggestionAPI.suggestResearchOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
  );
  final researchThreshold =
      40 - getAgendaResearchModifier(ctx.config.hiddenAgendaId);
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

  final thresholds = getThresholdsForLeader(ctx.config.personalityId);
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
