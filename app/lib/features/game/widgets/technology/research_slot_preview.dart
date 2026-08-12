// Deterministic per-slot and multi-slot research turn-preview for the
// GAME40001 Technology panel (Refs #3512, #4335). Mirrors the research-phase
// resolver (`packages/colonizethis_turn/.../research_resolver.dart`) so slot
// cards and the empire-wide funding header show the same RP/gold effect the
// next End Turn will apply, without duplicating the funding rate table (single
// source of truth — Refs #3472).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show effectiveResearchPointsForTechAllocation, fundingStats;

/// One occupied research slot's inputs for [computeResearchSlotsTurnPreview].
class ResearchSlotPreviewInput {
  const ResearchSlotPreviewInput({
    required this.slotIndex,
    required this.tech,
    required this.committedProgress,
    required this.funding,
  });

  final int slotIndex;
  final TechDefinition tech;
  final int committedProgress;
  final ResearchFundingLevel funding;
}

/// Aggregate research funding for the current turn after a sequential slot walk.
class ResearchSlotsTurnPreview {
  const ResearchSlotsTurnPreview({
    required this.bySlotIndex,
    required this.totalGoldSpent,
    required this.totalRp,
  });

  final Map<int, ResearchSlotTurnPreview> bySlotIndex;
  final int totalGoldSpent;
  final int totalRp;

  /// True when at least one slot will spend gold or apply RP next turn.
  bool get hasSpend => totalGoldSpent > 0 || totalRp > 0;
}

/// Immutable preview of one assigned research slot's effect on the next turn.
///
/// Values are computed from the slot's position in the resolver's ascending
/// slot-index walk. [treasuryBeforeSlot] is the residual treasury after earlier
/// successful spends in the same turn (defaults to [Player.treasury] for a
/// single-slot preview).
class ResearchSlotTurnPreview {
  const ResearchSlotTurnPreview({
    required this.funding,
    required this.committedProgress,
    required this.cost,
    required this.baseRpPerTurn,
    required this.industrialBonusRpPerTurn,
    required this.anticipatedRpPerTurn,
    required this.goldCostPerTurn,
    required this.goldSpentThisTurn,
    required this.debtBlocked,
    this.sequentialBlocked = false,
    this.treasuryBeforeSlot,
  });

  /// The slot's funding level.
  final ResearchFundingLevel funding;

  /// RP already committed to this tech (`Player.researchProgressByTechId`).
  final int committedProgress;

  /// Total RP cost of the assigned tech.
  final int cost;

  /// Base RP/turn for [funding] before the industrial bonus (0 for None).
  final int baseRpPerTurn;

  /// Extra RP/turn from Industrial Funding of Research (+20%, military/naval
  /// only); `0` when the bonus does not apply.
  final int industrialBonusRpPerTurn;

  /// RP actually applied to progress next turn: `0` when funding is None or the
  /// spend is blocked, otherwise the effective RP/turn.
  final int anticipatedRpPerTurn;

  /// Treasury (gold) cost per turn for [funding] (0 for None).
  final int goldCostPerTurn;

  /// Gold actually spent next turn: `0` when blocked or None, otherwise
  /// [goldCostPerTurn].
  final int goldSpentThisTurn;

  /// True when funding [goldCostPerTurn] would push [treasuryBeforeSlot] below
  /// the allowed research debt floor, so the resolver applies 0 RP / 0 spend.
  final bool debtBlocked;

  /// True when [debtBlocked] because earlier slots in the same turn already
  /// consumed treasury (residual treasury is below [startingTreasury]).
  final bool sequentialBlocked;

  /// Treasury snapshot used to evaluate this slot (residual after earlier
  /// spends when part of a multi-slot walk).
  final int? treasuryBeforeSlot;

  /// Effective RP/turn = base + industrial bonus, independent of blocks.
  int get effectiveRpPerTurn => baseRpPerTurn + industrialBonusRpPerTurn;

  /// Whether the +20% industrial bonus contributes to this slot.
  bool get hasIndustrialBonus => industrialBonusRpPerTurn > 0;

  /// Whether funding is None (no spend, no preview delta).
  bool get isNoneFunding => funding == ResearchFundingLevel.none;

  /// Whether the anticipated (segment B) preview should render.
  bool get showsAnticipatedSegment => anticipatedRpPerTurn > 0;

  /// Committed fraction of the progress bar, clamped to `[0, 1]`.
  double get committedFraction =>
      cost > 0 ? (committedProgress / cost).clamp(0.0, 1.0) : 0.0;

  /// Anticipated (segment B) fraction, capped to the remaining bar width so the
  /// preview never overflows past 100%.
  double get anticipatedFraction {
    if (cost <= 0 || anticipatedRpPerTurn <= 0) {
      return 0.0;
    }
    final int remaining = (cost - committedProgress).clamp(0, cost);
    final int added = anticipatedRpPerTurn.clamp(0, remaining);
    final double frac = added / cost;
    final double headroom = (1.0 - committedFraction).clamp(0.0, 1.0);
    return frac.clamp(0.0, headroom);
  }
}

/// Computes per-slot previews in ascending slot-index order, threading residual
/// treasury exactly like `research_resolver.dart`, plus aggregate −£X / +Y RP.
ResearchSlotsTurnPreview computeResearchSlotsTurnPreview({
  required Player player,
  required List<ResearchSlotPreviewInput> occupiedSlots,
}) {
  final sorted = List<ResearchSlotPreviewInput>.from(occupiedSlots)
    ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));
  final int startingTreasury = player.treasury;
  var residualTreasury = startingTreasury;
  final bySlot = <int, ResearchSlotTurnPreview>{};
  var totalGold = 0;
  var totalRp = 0;

  for (final slot in sorted) {
    final preview = computeResearchSlotTurnPreview(
      player: player,
      tech: slot.tech,
      committedProgress: slot.committedProgress,
      funding: slot.funding,
      treasuryBeforeSlot: residualTreasury,
      startingTreasury: startingTreasury,
    );
    bySlot[slot.slotIndex] = preview;
    if (preview.goldSpentThisTurn > 0) {
      residualTreasury -= preview.goldSpentThisTurn;
      totalGold += preview.goldSpentThisTurn;
      totalRp += preview.anticipatedRpPerTurn;
    }
  }

  return ResearchSlotsTurnPreview(
    bySlotIndex: bySlot,
    totalGoldSpent: totalGold,
    totalRp: totalRp,
  );
}

/// Computes the [ResearchSlotTurnPreview] for [tech] assigned at [funding] with
/// [committedProgress] RP already accrued, given [player]'s unlocked techs and
/// the treasury snapshot for this slot's position in the turn walk.
///
/// Mirrors `research_resolver.dart`:
/// - `funding.cost <= 0` (None) → no spend, 0 RP.
/// - `nextTreasury = treasuryBeforeSlot - funding.cost`; when
///   `nextTreasury < -researchMaxDebtForUnlocked(player.techUnlocked)` the
///   slot is debt-blocked → 0 RP, 0 spend.
/// - Otherwise RP applied = `effectiveResearchPointsForTechAllocation` (base
///   funding points plus the +20% military/naval industrial bonus).
ResearchSlotTurnPreview computeResearchSlotTurnPreview({
  required Player player,
  required TechDefinition tech,
  required int committedProgress,
  required ResearchFundingLevel funding,
  int? treasuryBeforeSlot,
  int? startingTreasury,
}) {
  final int treasury = treasuryBeforeSlot ?? player.treasury;
  final int startTreasury = startingTreasury ?? player.treasury;
  final ({int points, int cost}) stats = fundingStats(funding);
  final int base = stats.points;
  final int effective = effectiveResearchPointsForTechAllocation(
    player,
    tech,
    base,
  );
  final int industrialBonus = (effective - base).clamp(0, effective);
  final int goldCost = stats.cost;
  final int maxDebt = researchMaxDebtForUnlocked(player.techUnlocked);
  final int nextTreasury = treasury - goldCost;
  final bool debtBlocked = goldCost > 0 && nextTreasury < -maxDebt;
  final bool sequentialBlocked = debtBlocked && treasury < startTreasury;
  final bool noSpend =
      funding == ResearchFundingLevel.none || debtBlocked || effective <= 0;
  final int anticipated = noSpend ? 0 : effective;
  final int goldSpent = (debtBlocked || goldCost <= 0) ? 0 : goldCost;
  return ResearchSlotTurnPreview(
    funding: funding,
    committedProgress: committedProgress,
    cost: tech.cost,
    baseRpPerTurn: base,
    industrialBonusRpPerTurn: industrialBonus,
    anticipatedRpPerTurn: anticipated,
    goldCostPerTurn: goldCost,
    goldSpentThisTurn: goldSpent,
    debtBlocked: debtBlocked,
    sequentialBlocked: sequentialBlocked,
    treasuryBeforeSlot: treasuryBeforeSlot ?? player.treasury,
  );
}
