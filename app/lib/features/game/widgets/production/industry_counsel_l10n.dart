import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodity_ui_helpers.dart';

String industryCounselBriefForReason(
  AppLocalizations l10n,
  IndustryCounselReasonKey key,
) {
  switch (key) {
    case IndustryCounselReasonKey.outputShortage:
      return l10n.industryCounsel_reason_outputShortage_brief;
    case IndustryCounselReasonKey.chainLuxury:
      return l10n.industryCounsel_reason_chainLuxury_brief;
    case IndustryCounselReasonKey.labourDeficit:
      return l10n.industryCounsel_reason_labourDeficit_brief;
    case IndustryCounselReasonKey.luxuryShortage:
      return l10n.industryCounsel_reason_luxuryShortage_brief;
    case IndustryCounselReasonKey.feedstockBlocked:
      return l10n.industryCounsel_reason_feedstockBlocked_brief;
  }
}

String industryCounselDetailForReason(
  AppLocalizations l10n,
  IndustryCounselReasonKey key,
) {
  switch (key) {
    case IndustryCounselReasonKey.outputShortage:
      return l10n.industryCounsel_reason_outputShortage_detail;
    case IndustryCounselReasonKey.chainLuxury:
      return l10n.industryCounsel_reason_chainLuxury_detail;
    case IndustryCounselReasonKey.labourDeficit:
      return l10n.industryCounsel_reason_labourDeficit_detail;
    case IndustryCounselReasonKey.luxuryShortage:
      return l10n.industryCounsel_reason_luxuryShortage_detail;
    case IndustryCounselReasonKey.feedstockBlocked:
      return l10n.industryCounsel_reason_feedstockBlocked_detail;
  }
}

String industryCounselTitleForRecommendation(
  AppLocalizations l10n,
  IndustryCounselRecommendation recommendation,
) {
  switch (recommendation.kind) {
    case IndustryCounselRecommendationKind.produceRecipe:
      final recipeId = recommendation.recipeId;
      if (recipeId == null) return l10n.industryCounsel_title_produce;
      final recipe = ProductionRecipesCatalog.byId[recipeId];
      if (recipe == null) return l10n.industryCounsel_title_produce;
      return l10n.industryCounsel_title_produceRecipe(
        commodityDisplayName(l10n, recipe.outputCommodityId),
      );
    case IndustryCounselRecommendationKind.trainWorker:
      final tier = recommendation.trainTier;
      if (tier == null) return l10n.industryCounsel_title_train;
      return l10n.industryCounsel_title_trainWorker(tier.displayName);
    case IndustryCounselRecommendationKind.unblockFeedstock:
      final commodityId = recommendation.feedstockDeepLink?.commodityId;
      if (commodityId == null) return l10n.industryCounsel_title_feedstock;
      return l10n.industryCounsel_title_unblockFeedstock(
        commodityDisplayName(l10n, commodityId),
      );
  }
}

extension on WorkerTier {
  String get displayName {
    switch (this) {
      case WorkerTier.peasant:
        return 'Peasant';
      case WorkerTier.apprentice:
        return 'Apprentice';
      case WorkerTier.journeyman:
        return 'Journeyman';
      case WorkerTier.master:
        return 'Master';
    }
  }
}
