// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TileMapResult;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/game_service_provider.dart';
import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import 'production_panel.dart';

class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({
    super.key,
    required this.game,
    required this.player,
    this.attachGameToUiListener = true,
  });

  final Game game;
  final Player player;

  /// When true (default), [GameToUIBusListener] subscribes to turn-complete events.
  /// Set false in isolated widget tests where the listener tree affects layout.
  final bool attachGameToUiListener;

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
        final netDeltasByCommodity =
            previewStockpileNetDeltaByCommodityForPlayer(
              game: displayGame,
              playerId: displayPlayer.id,
              topology: topology,
              tileMapByRegion: tileMapByRegion,
              desiredOutputByRecipe: desiredOutputByRecipe,
            );
        return ProductionPanel(
          game: displayGame,
          player: displayPlayer,
          desiredOutputByRecipe: desiredOutputByRecipe,
          netDeltasByCommodity: netDeltasByCommodity,
          onDesiredOutputChanged: (next) {
            shellRef
                .read(productionDesiredOutputProvider.notifier)
                .replaceAll(next);
          },
        );
      },
    );
  }
}
