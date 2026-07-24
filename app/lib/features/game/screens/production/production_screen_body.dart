import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/game_service/try_get_game_map_data.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../widgets/production/production_commodity_breakdown_dialog.dart';
import '../../widgets/production/production_labour_helpers.dart';
import '../../widgets/production/production_panel.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'production_screen.dart';

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
    final canEdit = shell.canMutateViaUi;
    final labourCallbacks = ProductionLabourCallbacks(
      onAppendRecruitOrder: (tier) {
        if (!canEdit) return;
        final next = ordersWithAppendedRecruitWorkerOrder(
          currentOrders: shellRef.read(currentOrdersProvider),
          playerId: displayPlayer.id,
          tier: tier,
        );
        shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
      },
      onPopLastRecruitOrder: (tier) {
        if (!canEdit) return;
        final next = ordersWithLastRecruitWorkerOrderRemoved(
          currentOrders: shellRef.read(currentOrdersProvider),
          playerId: displayPlayer.id,
          tier: tier,
        );
        shellRef.read(currentOrdersProvider.notifier).replaceAll(next);
      },
      onDisband: (tier) {
        if (!canEdit) return;
        final nextGame = gameWithImmediateDisband(
          game: shellRef.read(currentGameProvider) ?? displayGame,
          playerId: displayPlayer.id,
          tier: tier,
        );
        if (nextGame == null) return;
        shellRef.read(currentGameProvider.notifier).setGame(nextGame);
      },
    );
    final productionPanel = ProductionPanel(
      game: displayGame,
      player: displayPlayer,
      desiredOutputByRecipe: desiredOutputByRecipe,
      netDeltasByCommodity: netDeltasByCommodity,
      currentOrders: currentOrders,
      labourCallbacks: labourCallbacks,
      canEditLabour: canEdit,
      onOpenCommodityBreakdown: canEdit
          ? () {
              showDialog<void>(
                context: context,
                barrierColor: EditorialMonoclePalette.dialogScrim,
                builder: (_) => ProductionCommodityBreakdownDialog(
                  game: displayGame,
                  player: displayPlayer,
                  topology: panelTopology,
                  tileMapByRegion: panelTileMaps,
                  currentOrders: currentOrders,
                ),
              );
            }
          : null,
      onDesiredOutputChanged: (next) {
        if (!canEdit) return;
        shellRef.read(productionDesiredOutputProvider.notifier).replaceAll(next);
      },
    );
    final panel =
        canEdit ? productionPanel : IgnorePointer(child: productionPanel);
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
      return KeyedSubtree(key: kCtE2EProductionPanelRootKey, child: panel);
    }
    return panel;
  }
}
