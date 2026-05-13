import 'package:colonizethis_models/colonizethis_models.dart';

const int defaultResearchSlots = 3;

// --- Research points (RP) per turn and treasury cost per turn. SPEC/game/tech-tree.md, research-resolution. ---

const int researchPointsLow = 100;
const int researchPointsMedium = 300;
const int researchPointsHigh = 800;

/// Maximum funding has 2.5x efficiency bonus.
const int researchPointsMaximum = 2500;

const int researchTreasuryCostLow = 50;
const int researchTreasuryCostMedium = 150;
const int researchTreasuryCostHigh = 400;
const int researchTreasuryCostMaximum = 1000;

/// Research-funding lookup: returns both the research points awarded per turn
/// and the treasury cost per turn for a given funding level (Refs #2391 AC2).
({int points, int cost}) fundingStats(ResearchFundingLevel level) {
  switch (level) {
    case ResearchFundingLevel.none:
      return (points: 0, cost: 0);
    case ResearchFundingLevel.low:
      return (points: researchPointsLow, cost: researchTreasuryCostLow);
    case ResearchFundingLevel.medium:
      return (points: researchPointsMedium, cost: researchTreasuryCostMedium);
    case ResearchFundingLevel.high:
      return (points: researchPointsHigh, cost: researchTreasuryCostHigh);
    case ResearchFundingLevel.maximum:
      return (points: researchPointsMaximum, cost: researchTreasuryCostMaximum);
  }
}

int pointsForFunding(ResearchFundingLevel level) => fundingStats(level).points;

int treasuryCostForFunding(ResearchFundingLevel level) =>
    fundingStats(level).cost;
