// Deterministic per-slot and multi-slot research turn-preview for the
// GAME40001 Technology panel (Refs #3512, #4335, #4457). Mirrors the
// research-phase resolver (`packages/colonizethis_turn/.../research_resolver.dart`)
// so slot cards and the empire-wide funding header show the same RP/gold effect
// the next End Turn will apply, without duplicating the funding rate table
// (single source of truth — Refs #3472).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/program/research-resolution.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show
        applySpyResearchBoostToPoints,
        effectiveResearchPointsForTechAllocation,
        fundingStats;

import 'research_slot_preview_models.dart';

export 'research_slot_preview_models.dart';

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
      qualifyingRivalGpCount: slot.qualifyingRivalGpCount,
      qualifyingRivalDisplayNames: slot.qualifyingRivalDisplayNames,
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
/// - Otherwise RP applied = `applySpyResearchBoostToPoints` on
///   `effectiveResearchPointsForTechAllocation` (base funding points plus the
///   +20% military/naval industrial bonus, then +15% per qualifying rival).
ResearchSlotTurnPreview computeResearchSlotTurnPreview({
  required Player player,
  required TechDefinition tech,
  required int committedProgress,
  required ResearchFundingLevel funding,
  int? treasuryBeforeSlot,
  int? startingTreasury,
  int qualifyingRivalGpCount = 0,
  List<String> qualifyingRivalDisplayNames = const [],
}) {
  final int treasury = treasuryBeforeSlot ?? player.treasury;
  final int startTreasury = startingTreasury ?? player.treasury;
  final ({int points, int cost}) stats = fundingStats(funding);
  final int base = stats.points;
  final int industrialAdjusted = effectiveResearchPointsForTechAllocation(
    player,
    tech,
    base,
  );
  final int industrialBonus = (industrialAdjusted - base).clamp(
    0,
    industrialAdjusted,
  );
  final int spyBoosted = applySpyResearchBoostToPoints(
    basePoints: industrialAdjusted,
    qualifyingRivalGpCount: qualifyingRivalGpCount,
  );
  final int goldCost = stats.cost;
  final int maxDebt = researchMaxDebtForUnlocked(player.techUnlocked);
  final int nextTreasury = treasury - goldCost;
  final bool debtBlocked = goldCost > 0 && nextTreasury < -maxDebt;
  final bool sequentialBlocked = debtBlocked && treasury < startTreasury;
  final bool noSpend =
      funding == ResearchFundingLevel.none ||
      debtBlocked ||
      industrialAdjusted <= 0;
  final int anticipated = noSpend ? 0 : spyBoosted;
  final int spyInsightRp = noSpend ? 0 : (spyBoosted - industrialAdjusted);
  final int spyCount = spyInsightRp > 0 ? qualifyingRivalGpCount : 0;
  final List<String> spyNames = spyCount > 0
      ? qualifyingRivalDisplayNames
      : const <String>[];
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
    spyInsightRpPerTurn: spyInsightRp,
    spyInsightRivalCount: spyCount,
    spyInsightRivalNames: spyNames,
  );
}
