import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const int defaultResearchSlots = 3;

int pointsForFunding(ResearchFundingLevel level) {
  switch (level) {
    case ResearchFundingLevel.none:
      return 0;
    case ResearchFundingLevel.low:
      return 100;
    case ResearchFundingLevel.medium:
      return 300;
    case ResearchFundingLevel.high:
      return 800;
    case ResearchFundingLevel.maximum:
      // Maximum funding has 2.5x efficiency bonus
      return 2500;
  }
}

int treasuryCostForFunding(ResearchFundingLevel level) {
  switch (level) {
    case ResearchFundingLevel.none:
      return 0;
    case ResearchFundingLevel.low:
      return 50;
    case ResearchFundingLevel.medium:
      return 150;
    case ResearchFundingLevel.high:
      return 400;
    case ResearchFundingLevel.maximum:
      return 1000;
  }
}

