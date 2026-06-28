import 'package:colonizethis_data/colonizethis_data.dart'
    show researchFundingTreasuryCost;
import 'package:colonizethis_models/colonizethis_models.dart';

const int defaultResearchSlots = 3;

// --- Research points (RP) per turn and treasury cost per turn. SPEC/game/tech-tree.md, research-resolution. ---

const int researchPointsLow = 100;
const int researchPointsMedium = 300;
const int researchPointsHigh = 800;

/// Maximum funding has 2.5x efficiency bonus.
const int researchPointsMaximum = 2500;

// Treasury cost presets are owned by `colonizethis_data` (research_funding.dart)
// so the resolver and the Full-AI research planner read one source of truth.
// Refs #3472.

/// Research-funding lookup: returns both the research points awarded per turn
/// and the treasury cost per turn for a given funding level (Refs #2391 AC2).
({int points, int cost}) fundingStats(ResearchFundingLevel level) {
  final cost = researchFundingTreasuryCost(level);
  return switch (level) {
    ResearchFundingLevel.none => (points: 0, cost: cost),
    ResearchFundingLevel.low => (points: researchPointsLow, cost: cost),
    ResearchFundingLevel.medium => (points: researchPointsMedium, cost: cost),
    ResearchFundingLevel.high => (points: researchPointsHigh, cost: cost),
    ResearchFundingLevel.maximum => (points: researchPointsMaximum, cost: cost),
  };
}

int pointsForFunding(ResearchFundingLevel level) => fundingStats(level).points;

int treasuryCostForFunding(ResearchFundingLevel level) =>
    fundingStats(level).cost;
