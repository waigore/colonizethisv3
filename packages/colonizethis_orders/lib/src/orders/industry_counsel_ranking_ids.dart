/// Shared stable-id and sort helpers for Industry Counsel ranking.
/// SPEC/program/industry-counsel-ranking.md.
library;

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const int industryCounselMaxRecommendations = 3;

int industryCounselRecommendationKindPrecedence(
  IndustryCounselRecommendationKind kind,
) {
  switch (kind) {
    case IndustryCounselRecommendationKind.produceRecipe:
      return 0;
    case IndustryCounselRecommendationKind.trainWorker:
      return 1;
    case IndustryCounselRecommendationKind.unblockFeedstock:
      return 2;
  }
}

String industryCounselRecommendationStableId(
  IndustryCounselRecommendationKind kind, {
  String? recipeId,
  WorkerTier? tier,
  String? commodityId,
}) {
  switch (kind) {
    case IndustryCounselRecommendationKind.produceRecipe:
      return 'produce:$recipeId';
    case IndustryCounselRecommendationKind.trainWorker:
      return 'train:${tier!.name}';
    case IndustryCounselRecommendationKind.unblockFeedstock:
      return 'feedstock:$commodityId';
  }
}
