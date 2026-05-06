// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../widgets/production_commodity_breakdown_dialog.dart';
import '../widgets/production_panel.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.player,
    this.attachGameToUiListener = true,
    this.panelTopologyOverride,
    this.panelTileMapByRegionOverride,
  });

  final Game game;
  final Player player;

  /// When true (default), [GameToUIBusListener] subscribes to turn-complete events.
  /// Set false in isolated widget tests where the listener tree affects layout.
  final bool attachGameToUiListener;

  /// When set, the production panel uses this topology instead of
  /// [GameService.getMapData] (avoids Hive in tests).
  final MapTopology? panelTopologyOverride;

  /// Optional tile maps when [panelTopologyOverride] is set.
  final Map<String, TileMapResult>? panelTileMapByRegionOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      title: 'Production',
      attachGameToUiListener: attachGameToUiListener,
      bodyBuilder: (context, shellRef, displayGame) {
        final desiredOutputByRecipe = shellRef.watch(
          productionDesiredOutputProvider,
        );
        final currentOrders = shellRef.watch(currentOrdersProvider);
        var topology = MapTopology();
        Map<String, TileMapResult> tileMapByRegion = const {};
        try {
          final gameService = shellRef.watch(gameServiceProvider);
          final loaded = gameService.getMapData(displayGame.id);
          if (loaded != null) {
            topology = loaded.combinedTopology;
            tileMapByRegion = loaded.tileMapByRegion;
          }
        } on Object {
          // Widget tests may not initialize Hive-backed game service providers.
        }
        final displayPlayer = displayGame.players.firstWhere(
          (p) => p.id == player.id,
        );
        final MapTopology panelTopology;
        final Map<String, TileMapResult>? panelTileMaps;
        if (panelTopologyOverride != null) {
          panelTopology = panelTopologyOverride!;
          panelTileMaps = panelTileMapByRegionOverride;
        } else {
          panelTopology = topology;
          panelTileMaps = tileMapByRegion;
        }
        final netDeltasByCommodity =
            previewStockpileNetDeltaByCommodityForPlayer(
              game: displayGame,
              topology: panelTopology,
              playerId: displayPlayer.id,
              tileMapByRegion: panelTileMaps,
              currentOrders: currentOrders,
              defaultAssignmentsByPlayerId: {
                displayPlayer.id: assignedRecipesFromDesiredOutput(
                  desiredOutputByRecipe,
                ),
              },
            );
        final productionPanel = ProductionPanel(
          game: displayGame,
          player: displayPlayer,
          desiredOutputByRecipe: desiredOutputByRecipe,
          netDeltasByCommodity: netDeltasByCommodity,
          onOpenCommodityBreakdown: () {
            showDialog<void>(
              context: context,
              builder: (_) => ProductionCommodityBreakdownDialog(
                game: displayGame,
                player: displayPlayer,
                topology: panelTopology,
                tileMapByRegion: panelTileMaps,
                currentOrders: currentOrders,
              ),
            );
          },
          onDesiredOutputChanged: (next) {
            shellRef
                .read(productionDesiredOutputProvider.notifier)
                .replaceAll(next);
          },
        );
        if (kCtE2EEnabled) {
          updateCtE2eProductionPanelSnapshotIfEnabled(
            CtE2eProductionPanelSnapshot(
              game: displayGame,
              player: displayPlayer,
              desiredOutputByRecipe: desiredOutputByRecipe,
              netDeltasByCommodity: netDeltasByCommodity,
              topology: panelTopology,
              tileMapByRegion: panelTileMaps,
            ),
          );
          return KeyedSubtree(
            key: kCtE2EProductionPanelRootKey,
            child: productionPanel,
          );
        }
        return productionPanel;
      },
    );
  }
}
