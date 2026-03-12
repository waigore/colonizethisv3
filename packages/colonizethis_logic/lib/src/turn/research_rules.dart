import 'package:colonizethis_data/colonizethis_data.dart';
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

int pointsForFunding(ResearchFundingLevel level) {
  switch (level) {
    case ResearchFundingLevel.none:
      return 0;
    case ResearchFundingLevel.low:
      return researchPointsLow;
    case ResearchFundingLevel.medium:
      return researchPointsMedium;
    case ResearchFundingLevel.high:
      return researchPointsHigh;
    case ResearchFundingLevel.maximum:
      return researchPointsMaximum;
  }
}

int treasuryCostForFunding(ResearchFundingLevel level) {
  switch (level) {
    case ResearchFundingLevel.none:
      return 0;
    case ResearchFundingLevel.low:
      return researchTreasuryCostLow;
    case ResearchFundingLevel.medium:
      return researchTreasuryCostMedium;
    case ResearchFundingLevel.high:
      return researchTreasuryCostHigh;
    case ResearchFundingLevel.maximum:
      return researchTreasuryCostMaximum;
  }
}

