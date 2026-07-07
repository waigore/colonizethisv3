export 'game_screen_shared.dart';

import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flame/game.dart' hide Game;
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../../core/services/ai/ai_profile_resolution.dart';
import '../../../../core/services/turn_resolution/turn_resolution_blocking_service.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart';
import '../../../../widgets/ct_icon_action.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_screen_shell.dart';
import '../../../../widgets/game_to_ui_bus_listener.dart';

import '../../widgets/dialogue/call_to_arms_dialogue_overlay.dart';
import '../../widgets/dialogue/game_start_intro_overlay.dart';
import '../../widgets/dialogue/intervention_dialogue_overlay.dart';
import '../../widgets/dialogue/overture_dialogue_overlay.dart';
import '../../widgets/dialogue/tribe_first_contact_overlay.dart';
import '../../widgets/dialogue/tribe_first_contact_sync.dart';
import '../../flame/overlays/exit_confirm_dialog.dart';
import '../../flame/host/host.dart';
import '../../flame/map_state/map_state.dart';
import 'game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import '../../flame/overlays/next_turn_confirmation_dialog.dart';
import '../../flame/overlays/turn_resolution_processing_dialog.dart';
import '../../flame/overlays/turn_resolution_progress_labels.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import '../../flame/overlays/victory_overlay.dart';

part 'game_screen_fallback_next_turn_runner.dart';
part 'game_screen_fallback_next_turn.dart';
part 'game_screen_overlay_stack.dart';

final _gameScreenLog = packageLogger('logic');

/// Shows the in-game pause menu (Debug log, Resume). SPEC/program/debug-log-viewer.md.
/// Emits [OpenPauseMenuPanelEvent]; shell event handler shows the bottom sheet.
void _showPauseMenu(AppEventBus bus) {
  bus.emit(const OpenPauseMenuPanelEvent());
}

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
    final content = _GameScreenOverlayStack(
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
