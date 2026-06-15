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

/// Whether [ctx]'s player has stalled Old World expansion this turn, i.e. owns
/// at most `kStalledOldWorldProvinceThreshold` Old World provinces. Counts the
/// player's Old World holdings from the player view (same scan perception uses
/// in `_buildConquestSummary`); evaluated lazily only when the stalled cap
/// could bind. Refs #3472 (Stalled-expansion cap).
bool _isStalledExpansion(PlannerContext ctx) {
  var owned = 0;
  for (final p in ctx.view.provincesById.entries) {
    if (p.value.ownerId != ctx.view.playerId) continue;
    if (ProvinceId.regionIdFrom(p.key) != kOldWorldRegionId) continue;
    owned++;
  }
  return isStalledOldWorldExpansion(owned);
}

/// Resolved new-slot target plus whether the at-war / stalled-expansion caps
/// were binding constraints, for the multi-slot research decision trace
/// (Refs #3472 AC10).
class _SlotTarget {
  const _SlotTarget({
    required this.target,
    required this.atWarCapApplied,
    required this.stalledExpansionCapApplied,
  });

  final int target;
  final bool atWarCapApplied;
  final bool stalledExpansionCapApplied;
}

/// Target number of **new** (non-in-progress) slots to fill this turn.
///
/// Scales by goal / aggression / research weight, then applies the at-war cap
/// ([kResearchSlotFillCapWhenAtWar]) and the stalled-expansion cap
/// ([kResearchSlotFillCapWhenStalledExpansion]) unconditionally — including the
/// `primaryGoal == tech` fill-all path. Both caps apply together; the smaller
/// binding cap wins. SPEC/ai/ai-architecture.md § Research planner.
_SlotTarget _targetNewSlotCount({
  required PlannerContext ctx,
  required PersonalityThresholds thresholds,
  required int emptyCount,
}) {
  if (emptyCount <= 0) {
    return const _SlotTarget(
      target: 0,
      atWarCapApplied: false,
      stalledExpansionCapApplied: false,
    );
  }

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
  var atWarCapApplied = false;
  if (kResearchSlotFillCapWhenAtWar < capped && _isAtWar(ctx)) {
    capped = kResearchSlotFillCapWhenAtWar;
    atWarCapApplied = true;
  }
  var stalledExpansionCapApplied = false;
  if (kResearchSlotFillCapWhenStalledExpansion < capped &&
      _isStalledExpansion(ctx)) {
    capped = kResearchSlotFillCapWhenStalledExpansion;
    stalledExpansionCapApplied = true;
  }
  return _SlotTarget(
    target: capped.clamp(0, emptyCount),
    atWarCapApplied: atWarCapApplied,
    stalledExpansionCapApplied: stalledExpansionCapApplied,
  );
}

/// Outcome of [_packResearchFunding]: the funded orders plus the packing
/// metadata the multi-slot decision trace needs (Refs #3472 AC10).
class _FundingPack {
  const _FundingPack({
    required this.orders,
    required this.tierIdx,
    required this.capIdx,
    required this.droppedNewCount,
  });

  final List<ResearchOrder> orders;
  final int tierIdx;
  final int capIdx;
  final int droppedNewCount;
}

/// Applies a uniform balanced funding tier across [selectedNew] + [mustKeep],
/// stepping the tier down uniformly and then dropping the highest-index **new**
/// slots until the set fits the research debt floor. In-progress slots in
/// [mustKeep] are never dropped: when nothing at or above Low is affordable they
/// are emitted at `none` to preserve accumulated progress without spending.
/// Refs #3472.
_FundingPack _packResearchFunding({
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

  return _FundingPack(
    orders: [
      for (final o in kept)
        ResearchOrder(slotIndex: o.slotIndex, techId: o.techId, funding: tier),
    ],
    tierIdx: tierIdx,
    capIdx: capIdx,
    droppedNewCount: selectedNew.length - newCount,
  );
}

/// One emitted research slot in the multi-slot decision trace (Refs #3472
/// AC10): the assigned slot index, tech id, and uniform funding tier.
class ResearchSlotDecision {
  const ResearchSlotDecision({
    required this.slotIndex,
    required this.techId,
    required this.funding,
  });

  final int slotIndex;
  final String techId;
  final ResearchFundingLevel funding;

  Map<String, Object?> toJson() => <String, Object?>{
    'slotIndex': slotIndex,
    'techId': techId,
    'funding': funding.name,
  };
}

/// Multi-slot Full-AI research decision provenance for the AI trace
/// (Refs #3472 AC10). Emitted under `thresholds.domainGates.research`;
/// see SPEC/ai/turn-trace-interpretation.md § Domain activation.
///
/// Pure runtime observation of the planner's slot-fill / treasury-packing
/// arithmetic; carries no side effects and is deterministic for fixed inputs.
class ResearchPlannerDecision {
  const ResearchPlannerDecision({
    required this.emptySlotCount,
    required this.targetSlotCount,
    required this.atWarCapApplied,
    required this.stalledExpansionCapApplied,
    required this.fundingTier,
    required this.slots,
    required this.droppedSlotIndices,
    required this.constraintReason,
  });

  /// Empty active slots that had a candidate tech this turn.
  final int emptySlotCount;

  /// New slots targeted after aggression scaling and the slot-fill caps.
  final int targetSlotCount;

  /// Whether the at-war cap reduced the target below its pre-cap value.
  final bool atWarCapApplied;

  /// Whether the stalled-expansion cap reduced the target below its running
  /// value (applied after the at-war cap).
  final bool stalledExpansionCapApplied;

  /// Uniform funding tier applied to every emitted order.
  final ResearchFundingLevel fundingTier;

  /// Emitted slots (in-progress + new), sorted by `slotIndex`.
  final List<ResearchSlotDecision> slots;

  /// New slot indices dropped by treasury packing, highest-index first.
  final List<int> droppedSlotIndices;

  /// Primary binding constraint, by precedence: `treasuryDrop` >
  /// `stalledExpansionCap` > `atWarCap` > `uniformDowngrade` > `none`.
  final String constraintReason;

  Map<String, Object?> toJson() => <String, Object?>{
    'emptySlotCount': emptySlotCount,
    'targetSlotCount': targetSlotCount,
    'atWarCapApplied': atWarCapApplied,
    'stalledExpansionCapApplied': stalledExpansionCapApplied,
    'fundingTier': fundingTier.name,
    'slots': [for (final s in slots) s.toJson()],
    'droppedSlotIndices': droppedSlotIndices,
    'constraintReason': constraintReason,
  };
}

/// Research planner output plus the multi-slot decision record for the trace.
///
/// [decision] is `null` when the planner emitted no research orders (no
/// suggestions, no targeted/in-progress slots, or an empty funded set), so the
/// trace omits `thresholds.domainGates.research` for that turn.
class ResearchPlannerResult {
  const ResearchPlannerResult({required this.orders, this.decision});

  final Orders orders;
  final ResearchPlannerDecision? decision;
}

/// Full-AI research planner: every turn, fills empty research slots with
/// distinct techs and assigns a uniform treasury-aware balanced funding tier.
///
/// Preserves in-progress research, targets all empty slots when
/// `primaryGoal == tech` (else scales by `researchSlotFillAggression` and the
/// research domain weight), and packs funding by uniform downgrade then
/// highest-index drop within the research debt floor.
/// SPEC/ai/ai-architecture.md § Research; SPEC/program/order-suggestions.md.
Orders runResearchPlanner({required PlannerContext ctx}) =>
    runResearchPlannerWithDecision(ctx: ctx).orders;

/// As [runResearchPlanner], but also returns the multi-slot decision record
/// for the AI trace (Refs #3472 AC10). The orchestrator uses this entry to
/// populate `thresholds.domainGates.research`.
ResearchPlannerResult runResearchPlannerWithDecision({
  required PlannerContext ctx,
}) {
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
  if (suggestions.isEmpty) return ResearchPlannerResult(orders: ctx.orders);

  final progress =
      ctx.view.player.researchProgressByTechId ?? const <String, int>{};
  bool isInProgress(ResearchOrder o) => (progress[o.techId] ?? 0) > 0;

  final mustKeep = suggestions.where(isInProgress).toList();
  final newCandidates = suggestions.where((o) => !isInProgress(o)).toList()
    ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

  final slotTarget = _targetNewSlotCount(
    ctx: ctx,
    thresholds: thresholds,
    emptyCount: newCandidates.length,
  );
  final selectedNew = newCandidates.take(slotTarget.target).toList();

  if (mustKeep.isEmpty && selectedNew.isEmpty) {
    return ResearchPlannerResult(orders: ctx.orders);
  }

  final pack = _packResearchFunding(
    ctx: ctx,
    thresholds: thresholds,
    mustKeep: mustKeep,
    selectedNew: selectedNew,
  );
  final funded = pack.orders;
  if (funded.isEmpty) return ResearchPlannerResult(orders: ctx.orders);

  final decision = _buildDecision(
    emptySlotCount: newCandidates.length,
    slotTarget: slotTarget,
    selectedNew: selectedNew,
    pack: pack,
    funded: funded,
  );

  _log.i(
    'research chosen nationId=${ctx.nationId} slots=${funded.length} '
    'funding=${funded.first.funding.name} inProgress=${mustKeep.length} '
    'constraint=${decision.constraintReason}',
  );
  return ResearchPlannerResult(
    orders: ctx.orders.appendResearchOrders(ctx.nationId, funded),
    decision: decision,
  );
}

/// Assembles the [ResearchPlannerDecision] from the resolved slot target and
/// treasury-packing outcome. `constraintReason` follows the documented
/// precedence (treasuryDrop > atWarCap > uniformDowngrade > none).
ResearchPlannerDecision _buildDecision({
  required int emptySlotCount,
  required _SlotTarget slotTarget,
  required List<ResearchOrder> selectedNew,
  required _FundingPack pack,
  required List<ResearchOrder> funded,
}) {
  final keptNewCount = selectedNew.length - pack.droppedNewCount;
  final droppedSlotIndices = <int>[
    for (final o in selectedNew.skip(keptNewCount)) o.slotIndex,
  ].reversed.toList();

  final String constraintReason;
  if (pack.droppedNewCount > 0) {
    constraintReason = 'treasuryDrop';
  } else if (slotTarget.stalledExpansionCapApplied) {
    constraintReason = 'stalledExpansionCap';
  } else if (slotTarget.atWarCapApplied) {
    constraintReason = 'atWarCap';
  } else if (pack.tierIdx < pack.capIdx) {
    constraintReason = 'uniformDowngrade';
  } else {
    constraintReason = 'none';
  }

  return ResearchPlannerDecision(
    emptySlotCount: emptySlotCount,
    targetSlotCount: slotTarget.target,
    atWarCapApplied: slotTarget.atWarCapApplied,
    stalledExpansionCapApplied: slotTarget.stalledExpansionCapApplied,
    fundingTier: ResearchFundingLevel.values[pack.tierIdx],
    slots: [
      for (final o in funded)
        ResearchSlotDecision(
          slotIndex: o.slotIndex,
          techId: o.techId,
          funding: o.funding,
        ),
    ],
    droppedSlotIndices: droppedSlotIndices,
    constraintReason: constraintReason,
  );
}
