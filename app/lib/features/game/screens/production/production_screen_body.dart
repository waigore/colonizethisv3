import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show rankIndustryCounselRecommendations;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../providers/production_panel_projection_provider.dart';
import '../../../../widgets/ct_app_perf_interactive_ready_marker.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'production_screen.dart';
import 'production_screen_body_panel.dart';

/// Production screen body with shell guard and panel wiring (Refs #4117 de-part).
class ProductionScreenBody extends ConsumerStatefulWidget {
  const ProductionScreenBody({
    super.key,
    required this.displayGame,
    required this.screen,
  });

  final Game displayGame;
  final ProductionScreen screen;

  @override
  ConsumerState<ProductionScreenBody> createState() => _ProductionScreenBodyState();
}

class _ProductionScreenBodyState extends ConsumerState<ProductionScreenBody> {
  bool _industryCounselReady = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _industryCounselReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.read(shellPlayerContextProvider);
    final sentinel = observeNotDefinedSentinel(shell, 'Production');
    if (sentinel != null) return sentinel;
    final desiredOutputByRecipe = ref.watch(
      productionDesiredOutputProvider,
    );
    final currentOrders = ref.watch(currentOrdersProvider);
    var topology = MapTopology();
    Map<String, TileMapResult> tileMapByRegion = const {};
    final loaded = tryGetGameMapData(
      () => ref.watch(gameServiceProvider).getMapData(widget.displayGame.id),
    );
    if (loaded != null) {
      topology = loaded.combinedTopology;
      tileMapByRegion = loaded.tileMapByRegion;
    }
    final displayPlayer = widget.displayGame.playerById(widget.screen.player.id)!;
    final MapTopology panelTopology;
    final Map<String, TileMapResult>? panelTileMaps;
    final bool useSessionCache = widget.screen.panelTopologyOverride == null;
    if (widget.screen.panelTopologyOverride != null) {
      panelTopology = widget.screen.panelTopologyOverride!;
      panelTileMaps = widget.screen.panelTileMapByRegionOverride;
    } else {
      panelTopology = topology;
      panelTileMaps = tileMapByRegion;
    }

    late final Map<String, int> netDeltasByCommodity;
    late final LabourReadinessSnapshot labourReadiness;
    late final ForceFeedingSnapshot forcesFeeding;
    if (useSessionCache) {
      final openPath = ref.watch(productionPanelOpenPathProvider);
      if (openPath == null) {
        return const SizedBox.shrink();
      }
      netDeltasByCommodity = openPath.netDeltasByCommodity;
      labourReadiness = openPath.labourReadiness;
      forcesFeeding = openPath.forcesFeeding;
    } else {
      final openPath = buildProductionPanelOpenPathWithoutSessionCache(
        displayGame: widget.displayGame,
        displayPlayer: displayPlayer,
        panelTopology: panelTopology,
        panelTileMaps: panelTileMaps,
        currentOrders: currentOrders,
        desiredOutputByRecipe: desiredOutputByRecipe,
      );
      netDeltasByCommodity = openPath.netDeltasByCommodity;
      labourReadiness = openPath.labourReadiness;
      forcesFeeding = openPath.forcesFeeding;
    }

    final Map<String, IndustryCounselRecommendation>
        starredProduceRecommendationsByRecipeId;
    if (_industryCounselReady) {
      if (useSessionCache) {
        starredProduceRecommendationsByRecipeId =
            ref.watch(productionPanelIndustryCounselProvider) ?? const {};
      } else {
        starredProduceRecommendationsByRecipeId =
            starredProduceRecommendationsFromRanked(
          rankIndustryCounselRecommendations(
            game: widget.displayGame,
            playerId: displayPlayer.id,
            currentOrders: currentOrders,
            topology: panelTopology,
            tileMapByRegion: panelTileMaps ?? const {},
          ),
        );
      }
    } else {
      starredProduceRecommendationsByRecipeId = const {};
    }

    final canEdit = shell.canMutateViaUi;
    final bus = ref.read(appEventBusProvider);
    void openCounsel({String? highlightRecommendationId}) {
      bus.emit(
        NavigateToRouteEvent(Routes.counsel, {
          'game': widget.displayGame,
          'humanPlayerId': displayPlayer.id,
          'highlightRecommendationId': highlightRecommendationId,
        }),
      );
    }

    void openTradeMarket(String commodityId) {
      bus.emit(
        NavigateToRouteEvent(Routes.trade, {
          'game': widget.displayGame,
          'humanPlayerId': displayPlayer.id,
          'initialTabIndex': 0,
          'highlightCommodityId': commodityId,
        }),
      );
    }

    final labourCallbacks = productionScreenLabourCallbacks(
      canEdit: canEdit,
      playerId: displayPlayer.id,
      readCurrentOrders: () => ref.read(currentOrdersProvider),
      replaceCurrentOrders: (next) {
        ref.read(currentOrdersProvider.notifier).replaceAll(next);
      },
      readGame: () => ref.read(currentGameProvider) ?? widget.displayGame,
      writeGame: (nextGame) {
        ref.read(currentGameProvider.notifier).setGame(nextGame);
      },
      context: context,
    );
    final productionPanel = buildProductionScreenPanel(
      context: context,
      displayGame: widget.displayGame,
      displayPlayer: displayPlayer,
      desiredOutputByRecipe: desiredOutputByRecipe,
      netDeltasByCommodity: netDeltasByCommodity,
      labourReadiness: labourReadiness,
      forcesFeeding: forcesFeeding,
      currentOrders: currentOrders,
      labourCallbacks: labourCallbacks,
      canEdit: canEdit,
      replaceDesiredOutput: (next) {
        ref
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
          game: widget.displayGame,
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
