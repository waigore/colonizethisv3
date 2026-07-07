// Deterministic per-slot research turn-preview for the GAME40001 Technology
// panel (Refs #3512). Mirrors the research-phase resolver
// (`packages/colonizethis_turn/.../research_resolver.dart`) so the slot card
// shows the same RP/gold effect the next End Turn will apply, without
// duplicating the funding rate table (single source of truth — Refs #3472).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show effectiveResearchPointsForTechAllocation, fundingStats;

/// Immutable preview of one assigned research slot's effect on the next turn.
///
/// All values are computed from the player's current treasury snapshot and
/// the slot's funding level. The treasury check mirrors the resolver's
/// per-order `nextTreasury < -maxDebt` early-return (see
/// [computeResearchSlotTurnPreview]); the preview evaluates the slot against
/// the current `player.treasury` snapshot rather than the cumulative treasury
/// after other slots in the same turn (a deterministic UI simplification
/// documented in SPEC/ui/technology-panel.md § Slot turn preview).
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
  /// spend is debt-blocked, otherwise the effective RP/turn.
  final int anticipatedRpPerTurn;

  /// Treasury (gold) cost per turn for [funding] (0 for None).
  final int goldCostPerTurn;

  /// Gold actually spent next turn: `0` when debt-blocked or None, otherwise
  /// [goldCostPerTurn].
  final int goldSpentThisTurn;

  /// True when funding [goldCostPerTurn] would push treasury below the allowed
  /// research debt floor, so the resolver applies 0 RP / 0 spend to this slot.
  final bool debtBlocked;

  /// Effective RP/turn = base + industrial bonus, independent of the debt block.
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

/// Computes the [ResearchSlotTurnPreview] for [tech] assigned at [funding] with
/// [committedProgress] RP already accrued, given [player]'s current treasury
/// and unlocked techs.
///
/// Mirrors `research_resolver.dart`:
/// - `funding.cost <= 0` (None) → no spend, 0 RP.
/// - `nextTreasury = player.treasury - funding.cost`; when
///   `nextTreasury < -researchMaxDebtForUnlocked(player.techUnlocked)` the
///   slot is debt-blocked → 0 RP, 0 spend.
/// - Otherwise RP applied = `effectiveResearchPointsForTechAllocation` (base
///   funding points plus the +20% military/naval industrial bonus).
ResearchSlotTurnPreview computeResearchSlotTurnPreview({
  required Player player,
  required TechDefinition tech,
  required int committedProgress,
  required ResearchFundingLevel funding,
}) {
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
  final int nextTreasury = player.treasury - goldCost;
  final bool debtBlocked = goldCost > 0 && nextTreasury < -maxDebt;
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
  );
}
