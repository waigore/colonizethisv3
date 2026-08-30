/// Human Industry Counsel ranking API. SPEC/program/industry-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'industry_counsel_ranking_feedstock.dart';
import 'industry_counsel_ranking_ids.dart';
import 'order_suggestion_recruit_worker.dart';

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
        recommendationId: industryCounselRecommendationStableId(
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
        recommendationId: industryCounselRecommendationStableId(
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

  final feedstock = industryCounselMaybeFeedstockRecommendation(
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
    final kindCmp = industryCounselRecommendationKindPrecedence(
      a.kind,
    ).compareTo(industryCounselRecommendationKindPrecedence(b.kind));
    if (kindCmp != 0) return kindCmp;
    return a.recommendationId.compareTo(b.recommendationId);
  });

  if (candidates.length <= industryCounselMaxRecommendations) {
    return candidates;
  }
  return candidates.sublist(0, industryCounselMaxRecommendations);
}
