export 'game_screen_shared.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_screen_shell.dart';
import '../../../widgets/game_to_ui_bus_listener.dart';

import '../dialogue/call_to_arms_dialogue_overlay.dart';
import '../dialogue/game_start_intro_overlay.dart';
import '../dialogue/intervention_dialogue_overlay.dart';
import '../dialogue/overture_dialogue_overlay.dart';
import 'game_canvas.dart';
import 'game_map_area.dart';
import 'victory_overlay.dart';

/// Shows the in-game pause menu (Debug log, Resume). SPEC/program/debug-log-viewer.md.
/// Emits [OpenPauseMenuPanelEvent]; shell event handler shows the bottom sheet.
void _showPauseMenu(AppEventBus bus) {
  bus.emit(const OpenPauseMenuPanelEvent());
}

Future<bool> _showExitToMainMenuConfirmDialog(BuildContext context) async {
  final l10n = appL10n(context);
  final shouldExit = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    useRootNavigator: true,
    builder: (ctx) => CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.game_exitConfirm_title,
            style: Theme.of(ctx).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(l10n.game_exitConfirm_body),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.common_cancel),
              ),
              const SizedBox(width: 8),
              CtNinePatchButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.game_exitConfirm_exit),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return shouldExit ?? false;
}

void _applyTurnResolutionResult(WidgetRef ref, TurnResolutionResult result) {
  final gameN = ref.read(currentGameProvider.notifier);
  final ordersN = ref.read(currentOrdersProvider.notifier);
  final dipN = ref.read(pendingDiplomacyProvider.notifier);
  switch (result) {
    case TurnResolutionComplete():
      gameN.setGame(result.game);
      ordersN.clear();
      dipN.clear();
    case TurnResolutionPendingOvertures():
      gameN.setGame(result.game);
      dipN.setOvertures(result.pendingOvertures);
    case TurnResolutionPendingIntervention():
      gameN.setGame(result.game);
      dipN.setIntervention(result.pendingInterventions);
    case TurnResolutionPendingCallToArms():
      gameN.setGame(result.game);
      dipN.setCallToArms(result.pendingCallToArms);
  }
}

/// Hosts the Flame game canvas or map. When map data exists, shows map + province/sea zone overlay.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(currentGameProvider);
    final mapViewData = ref.watch(mapViewDataProvider);
    final victory = game?.victory;
    final showOverlayButtons =
        game != null && victory == null && mapViewData == null;
    final introShownIds = ref.watch(gameIdsWithIntroShownProvider);
    final showIntro = game != null && !introShownIds.contains(game.id);
    final pendingDiplomacy = ref.watch(pendingDiplomacyProvider);
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
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _showPauseMenu(ref.read(appEventBusProvider)),
              tooltip: appL10n(context).game_pauseMenu_tooltip,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: CtNinePatchButton(
              onPressed: () {
                final service = ref.read(gameServiceProvider);
                final orders = ref.read(currentOrdersProvider);
                final result = service.runTurnResolution(game, orders: orders);
                _applyTurnResolutionResult(ref, result);
              },
              child: Text(
                appL10n(context).game_nextTurnButton(
                  game.worldState.turnState.turnNumber,
                  turnToYear(
                    game.worldState.turnState.turnNumber,
                    game.turnTimeMapping,
                  ),
                ),
              ),
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
      content = GameToUIBusListener(gameId: game.id, child: content);
    }

    if (showIntro) {
      content = GameStartIntroOverlay(
        onDismissed: () {
          ref.read(gameIdsWithIntroShownProvider.notifier).markShown(game.id);
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
              _applyTurnResolutionResult(ref, result);
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
              _applyTurnResolutionResult(ref, result);
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
              _applyTurnResolutionResult(ref, result);
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
        final shouldExit = await _showExitToMainMenuConfirmDialog(context);
        if (!shouldExit || !context.mounted) return;
        ref.read(appEventBusProvider).emit(const NavigateToShellEvent());
      },
      child: CtScreenShell(
        title: appL10n(context).game_screenTitle,
        child: content,
      ),
    );
  }
}
