import 'dart:math' as math;

import 'goal_manager.dart';
import 'planner_context.dart';
import 'planning_imports.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

/// Computes the research planner threshold the same way [runResearchPlanner]
/// does: `40 - getAgendaResearchModifier(hiddenAgendaId)`.
///
/// Pure and deterministic — identical inputs always yield identical
/// outputs. Used by the orchestrator (Refs #2832 trace
/// decision-provenance) to populate `thresholds.domainGates.thresholds.research`
/// and to scale non-tech slot-fill aggression.
int computeResearchThreshold({required PlannerContext ctx}) =>
    40 - getAgendaResearchModifier(ctx.config.hiddenAgendaId);

/// Whether the research planner treats research as a primary intent this turn.
///
/// Mirrors the gate the planner uses to decide full-slot fill: research is a
/// primary intent when `primaryGoal == tech` **or** `domainWeights.research >=
/// computeResearchThreshold(ctx)`. The planner now runs **every** turn (it may
/// emit zero orders); this predicate drives the trace `researchPlannerRan` gate
/// and is retained for decision-provenance.
///
/// Pure and deterministic — identical inputs always yield identical outputs.
bool researchPlannerWillRun({required PlannerContext ctx}) {
  if (ctx.primaryGoal == StrategicGoal.tech) {
    return true;
  }
  return ctx.domainWeights.research >= computeResearchThreshold(ctx: ctx);
}

/// Funding tier index (in [ResearchFundingLevel.values]) the configured
/// aggression maps to. 0 = none, 4 = maximum.
int _capTierIndexForAggression(int aggression) {
  final a = aggression.clamp(0, 100);
  if (a >= 80) return ResearchFundingLevel.maximum.index;
  if (a >= 60) return ResearchFundingLevel.high.index;
  if (a >= 35) return ResearchFundingLevel.medium.index;
  if (a >= 15) return ResearchFundingLevel.low.index;
  return ResearchFundingLevel.none.index;
}

/// Highest tier index in `[low .. capIdx]` whose uniform per-turn gold cost for
/// [count] slots keeps `treasury - count*cost >= floor`. Returns 0 (none) when
/// no tier at or above Low is affordable.
int _affordableUniformTierIndex({
  required int count,
  required int capIdx,
  required int treasury,
  required int floor,
}) {
  for (var t = capIdx; t >= ResearchFundingLevel.low.index; t--) {
    final cost =
        researchFundingTreasuryCost(ResearchFundingLevel.values[t]) * count;
    if (treasury - cost >= floor) return t;
  }
  return ResearchFundingLevel.none.index;
}

/// Whether [ctx]'s player has any active war this turn.
bool _isAtWar(PlannerContext ctx) => ctx.game.diplomacyRelations.any(
  (r) => r.involvesNation(ctx.nationId) && r.atWar,
);

/// Target number of **new** (non-in-progress) slots to fill this turn.
///
/// Scales by goal / aggression / research weight, then applies the at-war cap
/// ([kResearchSlotFillCapWhenAtWar]) unconditionally — including the
/// `primaryGoal == tech` fill-all path. SPEC/ai/ai-architecture.md § Research.
int _targetNewSlotCount({
  required PlannerContext ctx,
  required PersonalityThresholds thresholds,
  required int emptyCount,
}) {
  if (emptyCount <= 0) return 0;

  final int target;
  if (ctx.primaryGoal == StrategicGoal.tech) {
    target = emptyCount;
  } else {
    final fill = thresholds.researchSlotFillAggression.clamp(0, 100);
    var scaled = (emptyCount * fill / 100).ceil();
    final threshold = computeResearchThreshold(ctx: ctx);
    final research = ctx.domainWeights.research;
    if (research < threshold) {
      final denom = threshold <= 0 ? 1 : threshold;
      scaled = (scaled * research / denom).floor();
    }
    target = scaled;
  }

  var capped = target;
  if (_isAtWar(ctx)) {
    capped = math.min(capped, kResearchSlotFillCapWhenAtWar);
  }
  return capped.clamp(0, emptyCount);
}

/// Applies a uniform balanced funding tier across [assigned], stepping the tier
/// down uniformly and then dropping the highest-index **new** slots until the
/// set fits the research debt floor. In-progress slots in [mustKeepTechIds] are
/// never dropped: when nothing at or above Low is affordable they are emitted
/// at `none` to preserve accumulated progress without spending. Refs #3472.
List<ResearchOrder> _packResearchFunding({
  required PlannerContext ctx,
  required PersonalityThresholds thresholds,
  required List<ResearchOrder> mustKeep,
  required List<ResearchOrder> selectedNew,
}) {
  final player = ctx.view.player;
  final treasury = player.treasury;
  final floor = -researchMaxDebtForUnlocked(player.techUnlocked);

  var capIdx = _capTierIndexForAggression(thresholds.researchFundingAggression);
  if (ctx.primaryGoal == StrategicGoal.tech) {
    capIdx = math.max(capIdx, kResearchMinFundingWhenPrimaryGoalTech.index);
  }
  if (treasury <= 0) {
    capIdx = math.min(capIdx, kResearchMaxFundingWhenBroke.index);
  }

  var newCount = selectedNew.length;
  var tierIdx = ResearchFundingLevel.none.index;
  while (true) {
    final n = mustKeep.length + newCount;
    if (n == 0) break;
    final t = _affordableUniformTierIndex(
      count: n,
      capIdx: capIdx,
      treasury: treasury,
      floor: floor,
    );
    if (t >= ResearchFundingLevel.low.index) {
      tierIdx = t;
      break;
    }
    if (newCount > 0) {
      newCount--;
      continue;
    }
    break; // only in-progress remain; emit them at none to preserve progress.
  }

  final tier = ResearchFundingLevel.values[tierIdx];
  final kept = <ResearchOrder>[...mustKeep, ...selectedNew.take(newCount)]
    ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

  return [
    for (final o in kept)
      ResearchOrder(slotIndex: o.slotIndex, techId: o.techId, funding: tier),
  ];
}

/// Full-AI research planner: every turn, fills empty research slots with
/// distinct techs and assigns a uniform treasury-aware balanced funding tier.
///
/// Preserves in-progress research, targets all empty slots when
/// `primaryGoal == tech` (else scales by `researchSlotFillAggression` and the
/// research domain weight), and packs funding by uniform downgrade then
/// highest-index drop within the research debt floor.
/// SPEC/ai/ai-architecture.md § Research; SPEC/program/order-suggestions.md.
Orders runResearchPlanner({required PlannerContext ctx}) {
  final thresholds = resolveThresholds(
    ctx.config.personalityId,
    overrides: ctx.config.parameterOverrides,
  );

  final suggestions = ctx.suggestionAPI.suggestResearchOrders(
    ctx.view,
    ctx.game,
    ctx.topology,
    ctx.orders,
    researchNavalWeight: thresholds.researchNaval,
    researchMilitaryWeight: thresholds.researchMilitary,
    researchEconomicWeight: thresholds.researchEconomic,
    researchExplorationWeight: thresholds.researchExploration,
    researchSeed: ctx.seeds.researchSeed,
    categoryDiversifyWeight: kResearchCategoryDiversifyWeight,
  );
  if (suggestions.isEmpty) return ctx.orders;

  final progress =
      ctx.view.player.researchProgressByTechId ?? const <String, int>{};
  bool isInProgress(ResearchOrder o) => (progress[o.techId] ?? 0) > 0;

  final mustKeep = suggestions.where(isInProgress).toList();
  final newCandidates = suggestions.where((o) => !isInProgress(o)).toList()
    ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

  final targetNew = _targetNewSlotCount(
    ctx: ctx,
    thresholds: thresholds,
    emptyCount: newCandidates.length,
  );
  final selectedNew = newCandidates.take(targetNew).toList();

  if (mustKeep.isEmpty && selectedNew.isEmpty) return ctx.orders;

  final funded = _packResearchFunding(
    ctx: ctx,
    thresholds: thresholds,
    mustKeep: mustKeep,
    selectedNew: selectedNew,
  );
  if (funded.isEmpty) return ctx.orders;

  _log.i(
    'research chosen nationId=${ctx.nationId} slots=${funded.length} '
    'funding=${funded.isEmpty ? "none" : funded.first.funding.name} '
    'inProgress=${mustKeep.length}',
  );
  return ctx.orders.appendResearchOrders(ctx.nationId, funded);
}
