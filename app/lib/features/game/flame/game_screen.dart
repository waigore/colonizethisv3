export 'game_screen_shared.dart';

import 'dart:async';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:flame/game.dart' hide Game;
import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/ui_screen_ids.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../core/services/ai_profile_resolution.dart';
import '../../../core/services/turn_resolution_blocking_service.dart';
import '../../../core/services/turn_resolution_runner.dart';
import '../../../widgets/ct_icon_action.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_screen_shell.dart';
import '../../../widgets/game_to_ui_bus_listener.dart';

import '../dialogue/call_to_arms_dialogue_overlay.dart';
import '../dialogue/game_start_intro_overlay.dart';
import '../dialogue/intervention_dialogue_overlay.dart';
import '../dialogue/overture_dialogue_overlay.dart';
import '../dialogue/tribe_first_contact_overlay.dart';
import '../dialogue/tribe_first_contact_sync.dart';
import 'overlays/exit_confirm_dialog.dart';
import 'game_canvas.dart';
import 'map_state/map_state.dart';
import 'game_screen_shared.dart'
    show kGameMapNextTurnButtonKey, kNextTurnDisabledOpacity;
import 'overlays/next_turn_confirmation_dialog.dart';
import 'overlays/turn_resolution_processing_dialog.dart';
import 'overlays/turn_resolution_progress_labels.dart';
import 'turn_resolution_result_applier.dart';
import 'overlays/victory_overlay.dart';

part 'game_screen_fallback_next_turn.dart';

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
    Widget content = Stack(
      children: [
        if (mapViewData != null && game != null)
          GameMapArea(game: game, mapViewData: mapViewData)
        else
          GameWidget(game: ColonizeThisGame()),
        if (showOverlayButtons) ...[
          Positioned(
            left: 16,
            top: 16,
            child: CtIconAction(
              icon: Icons.menu,
              iconSize: 24,
              onPressed: () => _showPauseMenu(ref.read(appEventBusProvider)),
              tooltip: appL10n(context).game_pauseMenu_tooltip,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _FallbackNextTurnButton(
              game: game,
              turnResolutionBlocking: turnResolutionBlocking,
            ),
          ),
        ],
        if (game != null && victory != null)
          VictoryOverlay(
            game: game,
            victory: victory,
            bus: ref.read(appEventBusProvider),
          ),
      ],
    );

    if (game != null) {
      content = TribeFirstContactSyncListener(
        child: GameToUIBusListener(gameId: game.id, child: content),
      );
    }

    if (showIntro) {
      content = GameStartIntroOverlay(
        onDismissed: () {
          ref.read(gameIdsWithIntroShownProvider.notifier).markShown(game.id);
        },
        child: content,
      );
    }

    if (!showIntro && game != null && pendingHerald != null) {
      content = TribeFirstContactOverlay(
        tribeName: pendingHerald.tribeName,
        capitalName: pendingHerald.capitalName,
        onDismissed: () {
          ref
              .read(tribeFirstContactHeraldsShownProvider.notifier)
              .markShown(game.id, pendingHerald.tribeId);
          ref.read(tribeFirstContactHeraldQueueProvider.notifier).dequeueHead();
        },
        child: content,
      );
    }

    if (game != null && pendingDiplomacy != null) {
      switch (pendingDiplomacy) {
        case PendingDiplomacyOvertures(:final offers) when offers.isNotEmpty:
          content = OvertureDialogueOverlay(
            game: game,
            pendingOvertures: offers,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeOvertureDecisions(
                game,
                offers,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case PendingDiplomacyIntervention(:final prompts)
            when prompts.isNotEmpty:
          content = InterventionDialogueOverlay(
            game: game,
            prompts: prompts,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeInterventionDecisions(
                game,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case PendingDiplomacyCallToArms(:final pending) when pending.isNotEmpty:
          content = CallToArmsDialogueOverlay(
            game: game,
            pending: pending,
            onDecisions: (decisions) {
              final service = ref.read(gameServiceProvider);
              final orders = ref.read(currentOrdersProvider);
              final result = service.resumeCallToArmsDecisions(
                game,
                decisions,
                orders,
              );
              ref.read(turnResolutionResultApplierProvider).apply(result);
            },
            child: content,
          );
        case _:
          break;
      }
    }

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
