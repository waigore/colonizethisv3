import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panel_session_revision.dart'
    show panelOrdersRevision, panelWorldRevision;

/// Synchronous open-path read model for `GAME20001` (Refs #4688 Slice 2).
class ProductionPanelOpenPathSnapshot {
  const ProductionPanelOpenPathSnapshot({
    required this.netDeltasByCommodity,
    required this.labourReadiness,
    required this.forcesFeeding,
  });

  final Map<String, int> netDeltasByCommodity;
  final LabourReadinessSnapshot labourReadiness;
  final ForceFeedingSnapshot forcesFeeding;
}

typedef ProductionPanelSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
  int ordersRevision,
  int desiredOutputRevision,
});

class ProductionPanelSessionCacheState {
  const ProductionPanelSessionCacheState({
    this.openPathRevision,
    this.openPath,
    this.counselRevision,
    this.starredProduceRecommendationsByRecipeId,
  });

  final ProductionPanelSessionRevision? openPathRevision;
  final ProductionPanelOpenPathSnapshot? openPath;
  final ProductionPanelSessionRevision? counselRevision;
  final Map<String, IndustryCounselRecommendation>?
      starredProduceRecommendationsByRecipeId;
}

/// Cross-visit cache for Production panel projections (Refs #4688 Slice 2).
class ProductionPanelSessionCache {
  ProductionPanelSessionCacheState state = const ProductionPanelSessionCacheState();

  void reset() {
    state = const ProductionPanelSessionCacheState();
  }

  void storeOpenPath({
    required ProductionPanelSessionRevision revision,
    required ProductionPanelOpenPathSnapshot openPath,
  }) {
    state = ProductionPanelSessionCacheState(
      openPathRevision: revision,
      openPath: openPath,
      counselRevision: state.counselRevision,
      starredProduceRecommendationsByRecipeId:
          state.starredProduceRecommendationsByRecipeId,
    );
  }

  void storeIndustryCounsel({
    required ProductionPanelSessionRevision revision,
    required Map<String, IndustryCounselRecommendation>
        starredProduceRecommendationsByRecipeId,
  }) {
    state = ProductionPanelSessionCacheState(
      openPathRevision: state.openPathRevision,
      openPath: state.openPath,
      counselRevision: revision,
      starredProduceRecommendationsByRecipeId:
          starredProduceRecommendationsByRecipeId,
    );
  }
}

final productionPanelSessionCacheProvider = Provider<ProductionPanelSessionCache>(
  (ref) => ProductionPanelSessionCache(),
);

int productionDesiredOutputRevision(Map<String, int> desiredOutputByRecipe) {
  final entries = desiredOutputByRecipe.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

ProductionPanelSessionRevision productionPanelSessionRevision({
  required Game game,
  required Orders orders,
  required Map<String, int> desiredOutputByRecipe,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
    ordersRevision: panelOrdersRevision(orders),
    desiredOutputRevision: productionDesiredOutputRevision(desiredOutputByRecipe),
  );
}

Map<String, IndustryCounselRecommendation>
    starredProduceRecommendationsFromRanked(
  List<IndustryCounselRecommendation> recommendations,
) {
  return {
    for (final recommendation in recommendations)
      if (recommendation.kind ==
              IndustryCounselRecommendationKind.produceRecipe &&
          recommendation.recipeId != null)
        recommendation.recipeId!: recommendation,
  };
}
