/// Feedstock-unblock candidate builder for Industry Counsel ranking.
/// SPEC/program/industry-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'industry_counsel_ranking_ids.dart';

IndustryCounselRecommendation? industryCounselMaybeFeedstockRecommendation({
  required Game game,
  required String playerId,
  required Stockpile stockpile,
  required int effectiveLabour,
  required Map<String, bool>? techUnlocked,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Orders currentOrders,
  required IndustryCounselGrowthStage? growthStage,
  required WorkerPool workers,
}) {
  var hasPositiveProduce = false;
  double maxBlockedScore = 0;
  String? blockingCommodityId;
  // ignore: disallowed_ast_ai_full_recipe_catalog_scan
  for (final recipe in ProductionRecipesCatalog.all) {
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    final score = kIndustryCounselGrowthStageEnabled && growthStage != null
        ? industryCounselStageScaledRecipeScore(
            recipe: recipe,
            stockpile: stockpile,
            workers: workers,
            agendaId: kIndustryCounselNeutralAgendaId,
            stage: growthStage!,
          )
        : industryCounselScoreRecipe(
            recipe: recipe,
            stockpile: stockpile,
            workers: workers,
            agendaId: kIndustryCounselNeutralAgendaId,
          );
    if (score <= 0) continue;
    hasPositiveProduce = true;
    if (!industryCounselRecipeIsInputStarved(
      recipe: recipe,
      stockpile: stockpile,
      remainingLabour: effectiveLabour,
    )) {
      return null;
    }
    if (score > maxBlockedScore) {
      maxBlockedScore = score;
      blockingCommodityId = industryCounselFirstShortInputCommodity(
        recipe,
        stockpile,
      );
    }
  }
  if (!hasPositiveProduce || blockingCommodityId == null || maxBlockedScore <= 0) {
    return null;
  }

  final highlightTileKey = industryCounselSmallestOwnedImprovableTileKey(
    game: game,
    playerId: playerId,
    commodityId: blockingCommodityId,
    tileMapByRegion: tileMapByRegion,
  );
  if (highlightTileKey == null) return null;

  return IndustryCounselRecommendation(
    recommendationId: industryCounselRecommendationStableId(
      IndustryCounselRecommendationKind.unblockFeedstock,
      commodityId: blockingCommodityId,
    ),
    kind: IndustryCounselRecommendationKind.unblockFeedstock,
    rankScore: maxBlockedScore,
    briefReasonKey: IndustryCounselReasonKey.feedstockBlocked,
    detailReasonKeys: [IndustryCounselReasonKey.feedstockBlocked],
    feedstockDeepLink: UnblockFeedstockDeepLink(
      commodityId: blockingCommodityId,
      highlightTileKey: highlightTileKey,
    ),
  );
}

bool industryCounselRecipeIsInputStarved({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required int remainingLabour,
}) {
  if (recipe.labourPerOutput > remainingLabour) return false;
  for (final entry in recipe.inputQuantities.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) return true;
  }
  return false;
}

String? industryCounselFirstShortInputCommodity(
  ProductionRecipe recipe,
  Stockpile stockpile,
) {
  for (final entry in recipe.inputQuantities.entries) {
    if (stockpile.quantityOf(entry.key) < entry.value) {
      return entry.key;
    }
  }
  return null;
}

String? industryCounselSmallestOwnedImprovableTileKey({
  required Game game,
  required String playerId,
  required String commodityId,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  String? best;
  for (final province in ownerCache.provincesOwnedBy(playerId)) {
    final counts = provinceImprovableResourceTileCounts(
      game: game,
      provinceId: province.id,
      ownerId: playerId,
      tileMapByRegion: tileMapByRegion,
      ownerTechUnlocked: game.playerById(playerId)?.techUnlocked,
    );
    final entry = counts[commodityId];
    if (entry == null || entry.tileKeys.isEmpty) continue;
    for (final tileKey in entry.tileKeys) {
      if (best == null || tileKey.compareTo(best) < 0) {
        best = tileKey;
      }
    }
  }
  return best;
}
