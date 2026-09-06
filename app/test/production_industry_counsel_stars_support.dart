// Shared fixtures for Production industry counsel star widget tests (Refs #4734 Slice G).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter/material.dart';

IndustryCounselRecommendation productionIndustryCounselProduceRecommendation(
  String recipeId, {
  int suggestedDesiredOutput = 2,
}) {
  return IndustryCounselRecommendation(
    recommendationId: 'produce:$recipeId',
    kind: IndustryCounselRecommendationKind.produceRecipe,
    rankScore: 20,
    briefReasonKey: IndustryCounselReasonKey.outputShortage,
    detailReasonKeys: const [IndustryCounselReasonKey.outputShortage],
    recipeId: recipeId,
    suggestedDesiredOutput: suggestedDesiredOutput,
  );
}

const productionIndustryCounselLumberStarKey =
    ValueKey<String>('production_industry_counsel_star_lumber_from_timber');

const productionIndustryCounselThreeStarRecipeIds = [
  'lumber_from_timber',
  'paper_from_timber',
  'cigars_from_tobacco',
];
