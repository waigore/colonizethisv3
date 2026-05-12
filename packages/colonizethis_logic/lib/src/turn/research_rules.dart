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

/// RP and treasury cost per turn for one slot at [level].
({int points, int cost}) fundingStatsForLevel(ResearchFundingLevel level) {
  return switch (level) {
    ResearchFundingLevel.none => (points: 0, cost: 0),
    ResearchFundingLevel.low => (
        points: researchPointsLow,
        cost: researchTreasuryCostLow,
      ),
    ResearchFundingLevel.medium => (
        points: researchPointsMedium,
        cost: researchTreasuryCostMedium,
      ),
    ResearchFundingLevel.high => (
        points: researchPointsHigh,
        cost: researchTreasuryCostHigh,
      ),
    ResearchFundingLevel.maximum => (
        points: researchPointsMaximum,
        cost: researchTreasuryCostMaximum,
      ),
  };
}

int pointsForFunding(ResearchFundingLevel level) =>
    fundingStatsForLevel(level).points;

int treasuryCostForFunding(ResearchFundingLevel level) =>
    fundingStatsForLevel(level).cost;

