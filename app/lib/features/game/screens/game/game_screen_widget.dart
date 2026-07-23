import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../widgets/ct_screen_shell.dart';
import '../../flame/overlays/exit_confirm_dialog.dart';
import 'game_screen_overlay_stack.dart';

/// Hosts the Flame game canvas or map. When map data exists, shows map + province/sea zone overlay.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  /// SPEC/ui/game-screen.md — [UiScreenIds.gameScreen].
  static const screenId = UiScreenIds.gameScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final mapViewData = ref.watch(mapViewDataProvider);
    final victory = game?.victory;
    final showOverlayButtons =
        game != null && victory == null && mapViewData == null;
    // The in-game map shell renders its own 36 dp `GameTopBar`; the mockup
    // shows no secondary `CtScreenShell` title band above it, so suppress it
    // when the map shell is active (issue #2861 M2 / R2). The Flame-canvas
    // fallback path keeps the titled shell.
    final bool mapShellActive = game != null && mapViewData != null;
    final introShownIds = ref.watch(gameIdsWithIntroShownProvider);
    final showIntro = game != null && !introShownIds.contains(game.id);
    final heraldQueue = ref.watch(tribeFirstContactHeraldQueueProvider);
    final pendingHerald =
        heraldQueue.isNotEmpty ? heraldQueue.first : null;
    final pendingDiplomacy = ref.watch(pendingDiplomacyProvider);
    final turnResolutionBlocking = ref.watch(turnResolutionBlockingProvider);
    final content = GameScreenOverlayStack(
      game: game,
      mapViewData: mapViewData,
      victory: victory,
      showOverlayButtons: showOverlayButtons,
      showIntro: showIntro,
      pendingHerald: pendingHerald,
      pendingDiplomacy: pendingDiplomacy,
      turnResolutionBlocking: turnResolutionBlocking,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !context.mounted) return;
        final shouldExit = await showExitToMainMenuConfirmDialog(context);
        if (!shouldExit || !context.mounted) return;
        ref.read(appEventBusProvider).emit(const NavigateToShellEvent());
      },
      child: CtScreenShell(
        title: appL10n(context).game_screenTitle,
        showTitleBar: !mapShellActive,
        child: content,
      ),
    );
  }
}
