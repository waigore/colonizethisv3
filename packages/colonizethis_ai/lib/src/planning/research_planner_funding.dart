import 'dart:math' as math;

import 'goal_manager.dart';
import 'planner_context.dart';
import 'planning_imports.dart';

/// Research slot-target and treasury-packing helpers (Refs #4104 Slice B).
int researchCapTierIndexForAggression(int aggression) {
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
int researchAffordableUniformTierIndex({
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
bool researchPlannerIsAtWar(PlannerContext ctx) => ctx.game.diplomacyRelations
    .any((r) => r.involvesNation(ctx.nationId) && r.atWar);

/// Whether [ctx]'s player has stalled Old World expansion this turn, i.e. owns
/// at most `kStalledOldWorldProvinceThreshold` Old World provinces. Counts the
/// player's Old World holdings from the player view (same scan perception uses
/// in `buildConquestSummary`); evaluated lazily only when the stalled cap
/// could bind. Refs #3472 (Stalled-expansion cap).
bool researchPlannerIsStalledExpansion(PlannerContext ctx) {
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
class ResearchSlotTarget {
  const ResearchSlotTarget({
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
ResearchSlotTarget researchTargetNewSlotCount({
  required PlannerContext ctx,
  required PersonalityThresholds thresholds,
  required int emptyCount,
}) {
  if (emptyCount <= 0) {
    return const ResearchSlotTarget(
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
    final threshold = 40 - getAgendaResearchModifier(ctx.config.hiddenAgendaId);
    final research = ctx.domainWeights.research;
    if (research < threshold) {
      final denom = threshold <= 0 ? 1 : threshold;
      scaled = (scaled * research / denom).floor();
    }
    target = scaled;
  }

  var capped = target;
  var atWarCapApplied = false;
  if (kResearchSlotFillCapWhenAtWar < capped && researchPlannerIsAtWar(ctx)) {
    capped = kResearchSlotFillCapWhenAtWar;
    atWarCapApplied = true;
  }
  var stalledExpansionCapApplied = false;
  if (kResearchSlotFillCapWhenStalledExpansion < capped &&
      researchPlannerIsStalledExpansion(ctx)) {
    capped = kResearchSlotFillCapWhenStalledExpansion;
    stalledExpansionCapApplied = true;
  }
  return ResearchSlotTarget(
    target: capped.clamp(0, emptyCount),
    atWarCapApplied: atWarCapApplied,
    stalledExpansionCapApplied: stalledExpansionCapApplied,
  );
}

/// Outcome of [_packResearchFunding]: the funded orders plus the packing
/// metadata the multi-slot decision trace needs (Refs #3472 AC10).
class ResearchFundingPack {
  const ResearchFundingPack({
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
ResearchFundingPack packResearchFunding({
  required PlannerContext ctx,
  required PersonalityThresholds thresholds,
  required List<ResearchOrder> mustKeep,
  required List<ResearchOrder> selectedNew,
}) {
  final player = ctx.view.player;
  final treasury = player.treasury;
  final floor = -researchMaxDebtForUnlocked(player.techUnlocked);

  var capIdx = researchCapTierIndexForAggression(
    thresholds.researchFundingAggression,
  );
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
    final t = researchAffordableUniformTierIndex(
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

  return ResearchFundingPack(
    orders: [
      for (final o in kept)
        ResearchOrder(slotIndex: o.slotIndex, techId: o.techId, funding: tier),
    ],
    tierIdx: tierIdx,
    capIdx: capIdx,
    droppedNewCount: selectedNew.length - newCount,
  );
}
