import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show rankIndustryCounselRecommendations;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart'
    show
        economyPreviewInputs,
        forcesFeedingForPlayer,
        labourReadinessForPlayer,
        previewStockpileNetDeltaByCommodityForPlayer;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/shell/shell_player_context.dart';
import 'development_panel_projection_provider.dart'
    show developmentPanelOrdersRevision, developmentPanelWorldRevision;
import 'game_service_provider.dart';
import 'games_provider.dart';
import 'production_allocation_provider.dart';

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
    worldRevision: developmentPanelWorldRevision(game),
    ordersRevision: developmentPanelOrdersRevision(orders),
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

/// Stockpile preview, labour readiness, and forces feeding — session-cached
/// across `GAME20001` reopen when game/orders/allocation are unchanged.
final productionPanelOpenPathProvider =
    Provider.autoDispose<ProductionPanelOpenPathSnapshot?>((ref) {
      final game = ref.watch(currentGameProvider);
      if (game == null) return null;
      final orders = ref.watch(currentOrdersProvider);
      final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      if (mapData == null) return null;

      final playerId = resolveShellPanelPlayerId(
        ref.watch(shellPlayerContextProvider),
        game,
      );
      final revision = productionPanelSessionRevision(
        game: game,
        orders: orders,
        desiredOutputByRecipe: desiredOutputByRecipe,
      );
      final session = ref.read(productionPanelSessionCacheProvider).state;
      if (session.openPathRevision == revision && session.openPath != null) {
        return session.openPath;
      }

      final topology = mapData.combinedTopology;
      final tileMapByRegion = mapData.tileMapByRegion;
      final openPath = ctAppPerfSync('production.openPath', () {
        final netDeltasByCommodity =
            previewStockpileNetDeltaByCommodityForPlayer(
          game: game,
          topology: topology,
          playerId: playerId,
          inputs: economyPreviewInputs(
            tileMapByRegion: tileMapByRegion,
            currentOrders: orders,
            defaultAssignmentsByPlayerId: {
              playerId: assignedRecipesFromDesiredOutput(desiredOutputByRecipe),
            },
          ),
        );
        final regimentCounts = regimentTypeCountsForPlayer(
          game.worldState,
          playerId,
        );
        final shipCounts = shipTypeCountsForPlayer(game.worldState, playerId);
        final foodCounts = MilitaryNavyFoodCounts(
          regimentCountsById: regimentCounts,
          shipCountsById: shipCounts,
        );
        final previewInputs = economyPreviewInputs(
          tileMapByRegion: tileMapByRegion,
          currentOrders: orders,
        );
        return ProductionPanelOpenPathSnapshot(
          netDeltasByCommodity: netDeltasByCommodity,
          labourReadiness: labourReadinessForPlayer(
            game: game,
            topology: topology,
            playerId: playerId,
            foodCounts: foodCounts,
            inputs: previewInputs,
          ),
          forcesFeeding: forcesFeedingForPlayer(
            game: game,
            topology: topology,
            playerId: playerId,
            foodCounts: foodCounts,
            inputs: previewInputs,
          ),
        );
      });
      ref
          .read(productionPanelSessionCacheProvider)
          .storeOpenPath(revision: revision, openPath: openPath);
      return openPath;
    });

/// Industry counsel stars — deferred from first paint; session-cached on reopen.
final productionPanelIndustryCounselProvider = Provider.autoDispose<
    Map<String, IndustryCounselRecommendation>?>((ref) {
  final game = ref.watch(currentGameProvider);
  if (game == null) return null;
  final orders = ref.watch(currentOrdersProvider);
  final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
  final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
  if (mapData == null) return null;

  final playerId = resolveShellPanelPlayerId(
    ref.watch(shellPlayerContextProvider),
    game,
  );
  final revision = productionPanelSessionRevision(
    game: game,
    orders: orders,
    desiredOutputByRecipe: desiredOutputByRecipe,
  );
  final session = ref.read(productionPanelSessionCacheProvider).state;
  if (session.counselRevision == revision &&
      session.starredProduceRecommendationsByRecipeId != null) {
    return session.starredProduceRecommendationsByRecipeId;
  }

  final recommendations = ctAppPerfSync(
    'production.industryCounsel',
    () => rankIndustryCounselRecommendations(
      game: game,
      playerId: playerId,
      currentOrders: orders,
      topology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
    ),
  );
  final starred = starredProduceRecommendationsFromRanked(recommendations);
  ref.read(productionPanelSessionCacheProvider).storeIndustryCounsel(
        revision: revision,
        starredProduceRecommendationsByRecipeId: starred,
      );
  return starred;
});
