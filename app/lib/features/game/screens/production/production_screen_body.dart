import 'package:colonizethis_data/colonizethis_data.dart';
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
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../widgets/ct_app_perf_interactive_ready_marker.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'production_screen.dart';
import 'production_screen_body_panel.dart';

/// Production screen body with shell guard and panel wiring (Refs #4117 de-part).
class ProductionScreenBody extends ConsumerWidget {
  const ProductionScreenBody({
    super.key,
    required this.displayGame,
    required this.screen,
  });

  final Game displayGame;
  final ProductionScreen screen;

  @override
  Widget build(BuildContext context, WidgetRef shellRef) {
    final shell = shellRef.read(shellPlayerContextProvider);
    final sentinel = observeNotDefinedSentinel(shell, 'Production');
    if (sentinel != null) return sentinel;
    final desiredOutputByRecipe = shellRef.watch(
      productionDesiredOutputProvider,
    );
    final currentOrders = shellRef.watch(currentOrdersProvider);
    var topology = MapTopology();
    Map<String, TileMapResult> tileMapByRegion = const {};
    final loaded = tryGetGameMapData(
      () => shellRef.watch(gameServiceProvider).getMapData(displayGame.id),
    );
    if (loaded != null) {
      topology = loaded.combinedTopology;
      tileMapByRegion = loaded.tileMapByRegion;
    }
    final displayPlayer = displayGame.playerById(screen.player.id)!;
    final MapTopology panelTopology;
    final Map<String, TileMapResult>? panelTileMaps;
    if (screen.panelTopologyOverride != null) {
      panelTopology = screen.panelTopologyOverride!;
      panelTileMaps = screen.panelTileMapByRegionOverride;
    } else {
      panelTopology = topology;
      panelTileMaps = tileMapByRegion;
    }
    final netDeltasByCommodity = previewStockpileNetDeltaByCommodityForPlayer(
      game: displayGame,
      topology: panelTopology,
      playerId: displayPlayer.id,
      inputs: economyPreviewInputs(
        tileMapByRegion: panelTileMaps,
        currentOrders: currentOrders,
        defaultAssignmentsByPlayerId: {
          displayPlayer.id: assignedRecipesFromDesiredOutput(
            desiredOutputByRecipe,
          ),
        },
      ),
    );
    final regimentCounts = regimentTypeCountsForPlayer(
      displayGame.worldState,
      displayPlayer.id,
    );
    final shipCounts = shipTypeCountsForPlayer(
      displayGame.worldState,
      displayPlayer.id,
    );
    final labourReadiness = labourReadinessForPlayer(
      game: displayGame,
      topology: panelTopology,
      playerId: displayPlayer.id,
      foodCounts: MilitaryNavyFoodCounts(
        regimentCountsById: regimentCounts,
        shipCountsById: shipCounts,
      ),
      inputs: economyPreviewInputs(
        tileMapByRegion: panelTileMaps,
        currentOrders: currentOrders,
      ),
    );
    final forcesFeeding = forcesFeedingForPlayer(
      game: displayGame,
      topology: panelTopology,
      playerId: displayPlayer.id,
      foodCounts: MilitaryNavyFoodCounts(
        regimentCountsById: regimentCounts,
        shipCountsById: shipCounts,
      ),
      inputs: economyPreviewInputs(
        tileMapByRegion: panelTileMaps,
        currentOrders: currentOrders,
      ),
    );
    final canEdit = shell.canMutateViaUi;
    final bus = shellRef.read(appEventBusProvider);
    final industryCounselRecommendations = rankIndustryCounselRecommendations(
      game: displayGame,
      playerId: displayPlayer.id,
      currentOrders: currentOrders,
      topology: panelTopology,
      tileMapByRegion: panelTileMaps ?? const {},
    );
    final starredProduceRecommendationsByRecipeId = {
      for (final recommendation in industryCounselRecommendations)
        if (recommendation.kind ==
                IndustryCounselRecommendationKind.produceRecipe &&
            recommendation.recipeId != null)
          recommendation.recipeId!: recommendation,
    };
    void openCounsel({String? highlightRecommendationId}) {
      bus.emit(
        NavigateToRouteEvent(Routes.counsel, {
          'game': displayGame,
          'humanPlayerId': displayPlayer.id,
          'highlightRecommendationId': highlightRecommendationId,
        }),
      );
    }

    void openTradeMarket(String commodityId) {
      bus.emit(
        NavigateToRouteEvent(Routes.trade, {
          'game': displayGame,
          'humanPlayerId': displayPlayer.id,
          'initialTabIndex': 0,
          'highlightCommodityId': commodityId,
        }),
      );
    }

    final labourCallbacks = productionScreenLabourCallbacks(
      canEdit: canEdit,
      playerId: displayPlayer.id,
      readCurrentOrders: () => shellRef.read(currentOrdersProvider),
      replaceCurrentOrders: (next) {
        shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
      },
      readGame: () => shellRef.read(currentGameProvider) ?? displayGame,
      writeGame: (nextGame) {
        shellRef.read(currentGameProvider.notifier).setGame(nextGame);
      },
      context: context,
    );
    final productionPanel = buildProductionScreenPanel(
      context: context,
      displayGame: displayGame,
      displayPlayer: displayPlayer,
      desiredOutputByRecipe: desiredOutputByRecipe,
      netDeltasByCommodity: netDeltasByCommodity,
      labourReadiness: labourReadiness,
      forcesFeeding: forcesFeeding,
      currentOrders: currentOrders,
      labourCallbacks: labourCallbacks,
      canEdit: canEdit,
      replaceDesiredOutput: (next) {
        shellRef
            .read(productionDesiredOutputProvider.notifier)
            .replaceAll(next);
      },
      panelTopology: panelTopology,
      panelTileMaps: panelTileMaps,
      starredProduceRecommendationsByRecipeId:
          starredProduceRecommendationsByRecipeId,
      openCounsel: openCounsel,
      openTradeMarket: openTradeMarket,
    );
    final interactivePanel = CtAppPerfInteractiveReadyMarker(
      markerName: 'production.interactiveReady',
      child: productionPanel,
    );
    if (kCtE2EEnabled) {
      updateCtE2eProductionPanelSnapshotIfEnabled(
        CtE2eProductionPanelSnapshot(
          game: displayGame,
          player: displayPlayer,
          desiredOutputByRecipe: desiredOutputByRecipe,
          netDeltasByCommodity: netDeltasByCommodity,
          topology: panelTopology,
          currentOrders: currentOrders,
          canEditLabour: canEdit,
          tileMapByRegion: panelTileMaps,
        ),
      );
      return KeyedSubtree(
        key: kCtE2EProductionPanelRootKey,
        child: interactivePanel,
      );
    }
    return interactivePanel;
  }
}
