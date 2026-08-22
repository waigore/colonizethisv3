import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// One occupied research slot's inputs for [computeResearchSlotsTurnPreview].
class ResearchSlotPreviewInput {
  const ResearchSlotPreviewInput({
    required this.slotIndex,
    required this.tech,
    required this.committedProgress,
    required this.funding,
    this.qualifyingRivalGpCount = 0,
    this.qualifyingRivalDisplayNames = const [],
  });

  final int slotIndex;
  final TechDefinition tech;
  final int committedProgress;
  final ResearchFundingLevel funding;

  /// Distinct rival GPs that currently qualify for spy insight on [tech].
  final int qualifyingRivalGpCount;

  /// Display names for [qualifyingRivalGpCount] courts (never raw ids).
  final List<String> qualifyingRivalDisplayNames;
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
    this.spyInsightRpPerTurn = 0,
    this.spyInsightRivalCount = 0,
    this.spyInsightRivalNames = const [],
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

  /// Extra RP/turn from spy insight (0 when it does not apply or the slot
  /// will not spend). Applied after the industrial bonus, matching the resolver.
  final int spyInsightRpPerTurn;

  /// Qualifying rival GP count used for the spy multiplier (0 when blocked).
  final int spyInsightRivalCount;

  /// Display names of qualifying courts (empty when the spy row is omitted).
  final List<String> spyInsightRivalNames;

  /// Effective RP/turn = base + industrial + spy insight, independent of
  /// gold-cost display; spy extra is 0 when the slot will not spend.
  int get effectiveRpPerTurn =>
      baseRpPerTurn + industrialBonusRpPerTurn + spyInsightRpPerTurn;

  /// Whether the +20% industrial bonus contributes to this slot.
  bool get hasIndustrialBonus => industrialBonusRpPerTurn > 0;

  /// Whether spy insight contributes extra RP this turn.
  bool get hasSpyInsight => spyInsightRpPerTurn > 0 && spyInsightRivalCount > 0;

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
