/// Canonical research funding treasury costs and the research debt floor.
///
/// Source of truth for the per-turn gold cost of each [ResearchFundingLevel]
/// (SPEC/game/tech-tree.md funding presets) and the post-spend treasury floor
/// (SPEC/program/research-resolution.md § Constraints). Both the turn resolver
/// (`colonizethis_turn`) and the Full-AI research planner (`colonizethis_ai`)
/// read these so funding/debt logic stays drift-free across packages. Refs
/// #3472.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'tech_ids.dart';

/// Per-turn treasury cost (gold) for the Low funding preset.
const int researchTreasuryCostLow = 50;

/// Per-turn treasury cost (gold) for the Medium funding preset.
const int researchTreasuryCostMedium = 150;

/// Per-turn treasury cost (gold) for the High funding preset.
const int researchTreasuryCostHigh = 400;

/// Per-turn treasury cost (gold) for the Maximum funding preset.
const int researchTreasuryCostMaximum = 1000;

/// Per-turn treasury cost (gold) for [level]. None costs 0.
int researchFundingTreasuryCost(ResearchFundingLevel level) => switch (level) {
  ResearchFundingLevel.none => 0,
  ResearchFundingLevel.low => researchTreasuryCostLow,
  ResearchFundingLevel.medium => researchTreasuryCostMedium,
  ResearchFundingLevel.high => researchTreasuryCostHigh,
  ResearchFundingLevel.maximum => researchTreasuryCostMaximum,
};

/// Maximum allowed debt (negative treasury) in gold for research spending,
/// derived from unlocked labour/economy techs:
///
/// - No qualifying tech → 0 (treasury cannot go negative for research).
/// - `money_lending` (without `banking`) → 500.
/// - `banking` → 1000.
///
/// SPEC/program/research-resolution.md § Constraints; SPEC/game/
/// tech-tree-labour-economy.md.
int researchMaxDebtForUnlocked(Map<String, bool>? techUnlocked) {
  final unlocked = techUnlocked ?? const <String, bool>{};
  if (unlocked[kTechIdMoneyLending] != true) return 0;
  if (unlocked[kTechIdBanking] == true) return 1000;
  return 500;
}
