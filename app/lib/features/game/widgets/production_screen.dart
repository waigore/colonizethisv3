// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        final displayPlayer = displayGame.players.firstWhere(
          (p) => p.id == player.id,
        );
        return ProductionPanel(
          game: displayGame,
          player: displayPlayer,
          desiredOutputByRecipe: desiredOutputByRecipe,
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
