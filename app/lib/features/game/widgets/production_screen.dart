// Full-screen Production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/games_provider.dart';
import '../../../providers/production_allocation_provider.dart';
import '../../../widgets/ct_screen_shell.dart';
import '../../../widgets/game_to_ui_bus_listener.dart';
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
    final desiredOutputByRecipe = ref.watch(productionDesiredOutputProvider);
    final live =
        attachGameToUiListener ? ref.watch(currentGameProvider) : null;
    final displayGame =
        live != null && live.id == game.id ? live : game;
    final displayPlayer =
        displayGame.players.firstWhere((p) => p.id == player.id);

    final shell = CtScreenShell(
      title: 'Production',
      showBackButton: true,
      child: ProductionPanel(
        game: displayGame,
        player: displayPlayer,
        desiredOutputByRecipe: desiredOutputByRecipe,
        onDesiredOutputChanged: (next) {
          ref.read(productionDesiredOutputProvider.notifier).replaceAll(next);
        },
      ),
    );
    if (!attachGameToUiListener) {
      return shell;
    }
    return GameToUIBusListener(gameId: game.id, child: shell);
  }
}
