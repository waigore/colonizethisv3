// Shared Counsel Industry tab fixtures and golden hosts (Refs #4191).

import 'package:colonizethis_app/features/game/screens/counsel/counsel_industry_tab_body.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

const Size kCounselPanelGoldenViewport = Size(360, 720);

IndustryCounselRecommendation counselTestProduceRecommendation({
  String recipeId = 'lumber_from_timber',
}) {
  return IndustryCounselRecommendation(
    recommendationId: 'produce:$recipeId',
    kind: IndustryCounselRecommendationKind.produceRecipe,
    rankScore: 20,
    briefReasonKey: IndustryCounselReasonKey.outputShortage,
    detailReasonKeys: const [IndustryCounselReasonKey.outputShortage],
    recipeId: recipeId,
    suggestedDesiredOutput: 2,
  );
}

IndustryCounselRecommendation counselTestTrainRecommendation({
  WorkerTier tier = WorkerTier.peasant,
}) {
  return IndustryCounselRecommendation(
    recommendationId: 'train:${tier.name}',
    kind: IndustryCounselRecommendationKind.trainWorker,
    rankScore: 15,
    briefReasonKey: IndustryCounselReasonKey.labourDeficit,
    detailReasonKeys: const [IndustryCounselReasonKey.labourDeficit],
    trainTier: tier,
  );
}

IndustryCounselRecommendation counselTestFeedstockRecommendation({
  String commodityId = 'timber',
}) {
  return IndustryCounselRecommendation(
    recommendationId: 'unblock:$commodityId',
    kind: IndustryCounselRecommendationKind.unblockFeedstock,
    rankScore: 12,
    briefReasonKey: IndustryCounselReasonKey.feedstockBlocked,
    detailReasonKeys: const [IndustryCounselReasonKey.feedstockBlocked],
    feedstockDeepLink: UnblockFeedstockDeepLink(commodityId: commodityId),
  );
}

List<IndustryCounselRecommendation> counselTestDefaultRecommendations() {
  return [
    counselTestProduceRecommendation(),
    counselTestTrainRecommendation(),
    counselTestFeedstockRecommendation(),
  ];
}

/// Mirrors the Industry tab column inside [CounselScreen] for golden captures.
Widget counselIndustryTabGoldenHost({
  required List<IndustryCounselRecommendation> recommendations,
  String? highlightRecommendationId,
  bool canEdit = true,
  CounselIndustryCallbacks callbacks = const CounselIndustryCallbacks(),
  Size viewport = kCounselPanelGoldenViewport,
}) {
  final l10n = lookupAppLocalizations(const Locale('en'));
  return SizedBox(
    width: viewport.width,
    height: viewport.height,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(
            l10n.industryCounsel_tabIndustry,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: CounselIndustryTabBody(
            recommendations: recommendations,
            highlightRecommendationId: highlightRecommendationId,
            l10n: l10n,
            canEdit: canEdit,
            callbacks: callbacks,
          ),
        ),
      ],
    ),
  );
}
