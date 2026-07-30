/// Human Industry Counsel ranking API. SPEC/program/industry-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_suggestion_recruit_worker.dart';

const int _kMaxRecommendations = 3;

int _kindPrecedence(IndustryCounselRecommendationKind kind) {
  switch (kind) {
    case IndustryCounselRecommendationKind.produceRecipe:
      return 0;
    case IndustryCounselRecommendationKind.trainWorker:
      return 1;
    case IndustryCounselRecommendationKind.unblockFeedstock:
      return 2;
  }
}

String _stableIdForKind(
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

List<IndustryCounselRecommendation> rankIndustryCounselRecommendations({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final player = game.playerById(playerId);
  if (player == null) return const [];

  final stockpile = player.stockpile;
  final workers = player.workerPool;
  final effectiveLabour = effectiveLabourForWorkers(
    workers: workers,
    stockpile: stockpile,
  );
  final techUnlocked = player.techUnlocked;

  final growthStage = kIndustryCounselGrowthStageEnabled
      ? IndustryCounselGrowthStage.compute(game, playerId)
      : null;

  final coreAssignments = industryCounselAllocateLabourCore(
    stockpile: stockpile,
    workers: workers,
    effectiveLabour: effectiveLabour,
    techUnlocked: techUnlocked,
    growthStage: growthStage,
    growthStagePlannerEnabled: kIndustryCounselGrowthStageEnabled,
  );
  final coreAssignedLabour = industryCounselTotalAssignedLabour(coreAssignments);
  final sustainable = industryCounselSustainableTrainedCounts(
    stockpile: stockpile,
    productionAssignments: coreAssignments,
  );

  final candidates = <IndustryCounselRecommendation>[];

  // Produce recipe candidates from core allocation + high-score feasible recipes.
  final assignmentByRecipe = {
    for (final a in coreAssignments) a.recipeId: a,
  };
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
    final runs = industryCounselFeasibleRuns(
      recipe: recipe,
      stockpile: stockpile,
      remainingLabour: effectiveLabour,
    );
    if (runs <= 0) continue;

    final assignment = assignmentByRecipe[recipe.id];
    final desired = assignment != null
        ? industryCounselDesiredOutputForAssignment(assignment)
        : industryCounselFeasibleRuns(
            recipe: recipe,
            stockpile: stockpile,
            remainingLabour: effectiveLabour,
          );

    final reason = industryCounselPrimaryReasonForRecipeScore(
      recipe: recipe,
      stockpile: stockpile,
      workers: workers,
    );

    candidates.add(
      IndustryCounselRecommendation(
        recommendationId: _stableIdForKind(
          IndustryCounselRecommendationKind.produceRecipe,
          recipeId: recipe.id,
        ),
        kind: IndustryCounselRecommendationKind.produceRecipe,
        rankScore: score,
        briefReasonKey: reason,
        detailReasonKeys: [reason],
        recipeId: recipe.id,
        suggestedDesiredOutput: desired,
      ),
    );
  }

  // Train worker candidates from suggestion API + luxury caps.
  final view = buildPlayerView(game, topology, playerId);
  final recruitCandidates = suggestRecruitWorkerOrders(
    view,
    game,
    topology,
    currentOrders,
  );
  for (final order in recruitCandidates) {
    final tier = order.targetTier;
    if (tier != WorkerTier.peasant) {
      final luxuryId = industryCounselLuxuryCommodityForTier(tier);
      if (luxuryId != null) {
        final sustainableCount = sustainable[tier] ?? 0;
        final cap = industryCounselSoftLuxuryCapDeficitLimit(sustainableCount);
        if (stockpile.quantityOf(luxuryId) >= cap) continue;
      }
    }
    final score = industryCounselScoreTrainWorker(
      tier: tier,
      stockpile: stockpile,
      effectiveLabour: effectiveLabour,
      coreAssignedLabour: coreAssignedLabour,
      sustainableTrainedCounts: sustainable,
    );
    if (score <= 0) continue;
    final reason = tier == WorkerTier.peasant
        ? IndustryCounselReasonKey.labourDeficit
        : IndustryCounselReasonKey.luxuryShortage;
    candidates.add(
      IndustryCounselRecommendation(
        recommendationId: _stableIdForKind(
          IndustryCounselRecommendationKind.trainWorker,
          tier: tier,
        ),
        kind: IndustryCounselRecommendationKind.trainWorker,
        rankScore: score,
        briefReasonKey: reason,
        detailReasonKeys: [reason],
        trainTier: tier,
      ),
    );
  }

  // Optional feedstock unblock candidate.
  final feedstock = _maybeFeedstockRecommendation(
    game: game,
    playerId: playerId,
    stockpile: stockpile,
    effectiveLabour: effectiveLabour,
    techUnlocked: techUnlocked,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    currentOrders: currentOrders,
    growthStage: growthStage,
    workers: workers,
  );
  if (feedstock != null) {
    candidates.add(feedstock);
  }

  candidates.sort((a, b) {
    final scoreCmp = b.rankScore.compareTo(a.rankScore);
    if (scoreCmp != 0) return scoreCmp;
    final kindCmp =
        _kindPrecedence(a.kind).compareTo(_kindPrecedence(b.kind));
    if (kindCmp != 0) return kindCmp;
    return a.recommendationId.compareTo(b.recommendationId);
  });

  if (candidates.length <= _kMaxRecommendations) {
    return candidates;
  }
  return candidates.sublist(0, _kMaxRecommendations);
}

IndustryCounselRecommendation? _maybeFeedstockRecommendation({
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
    if (!_isInputStarved(
      recipe: recipe,
      stockpile: stockpile,
      remainingLabour: effectiveLabour,
    )) {
      return null;
    }
    if (score > maxBlockedScore) {
      maxBlockedScore = score;
      blockingCommodityId = _firstShortInputCommodity(recipe, stockpile);
    }
  }
  if (!hasPositiveProduce || blockingCommodityId == null || maxBlockedScore <= 0) {
    return null;
  }

  final highlightTileKey = _smallestOwnedImprovableTileKey(
    game: game,
    playerId: playerId,
    commodityId: blockingCommodityId,
    tileMapByRegion: tileMapByRegion,
  );
  if (highlightTileKey == null) return null;

  return IndustryCounselRecommendation(
    recommendationId: _stableIdForKind(
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

bool _isInputStarved({
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

String? _firstShortInputCommodity(
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

String? _smallestOwnedImprovableTileKey({
  required Game game,
  required String playerId,
  required String commodityId,
  required Map<String, TileMapResult> tileMapByRegion,
}) {
  final ownerCache = ProvinceOwnerCache.of(game.worldState);
  String? best;
  for (final province in game.worldState.allProvinces()) {
    if (ownerCache.ownerOf(province.id) != playerId) continue;
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
