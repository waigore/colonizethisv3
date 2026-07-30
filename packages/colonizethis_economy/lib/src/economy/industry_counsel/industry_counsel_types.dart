/// Industry counsel recommendation DTOs and reason keys.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

enum IndustryCounselReasonKey {
  outputShortage,
  chainLuxury,
  labourDeficit,
  luxuryShortage,
  feedstockBlocked,
}

enum IndustryCounselRecommendationKind {
  produceRecipe,
  trainWorker,
  unblockFeedstock,
}

/// Deep-link metadata for feedstock unblock recommendations.
final class UnblockFeedstockDeepLink {
  const UnblockFeedstockDeepLink({
    required this.commodityId,
    this.highlightTileKey,
  });

  final String commodityId;
  final String? highlightTileKey;
}

/// One ranked industry counsel recommendation (≤3 per turn).
final class IndustryCounselRecommendation {
  const IndustryCounselRecommendation({
    required this.recommendationId,
    required this.kind,
    required this.rankScore,
    required this.briefReasonKey,
    required this.detailReasonKeys,
    this.recipeId,
    this.suggestedDesiredOutput,
    this.trainTier,
    this.feedstockDeepLink,
  });

  final String recommendationId;
  final IndustryCounselRecommendationKind kind;
  final double rankScore;
  final IndustryCounselReasonKey briefReasonKey;
  final List<IndustryCounselReasonKey> detailReasonKeys;
  final String? recipeId;
  final int? suggestedDesiredOutput;
  final WorkerTier? trainTier;
  final UnblockFeedstockDeepLink? feedstockDeepLink;
}
