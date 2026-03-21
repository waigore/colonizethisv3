export 'game_screen_shared.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/map_view_provider.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_screen_shell.dart';

import '../dialogue/game_start_intro_overlay.dart';
import '../dialogue/overture_dialogue_overlay.dart';
import 'game_canvas.dart';
import 'game_map_area.dart';
import 'victory_overlay.dart';

/// Shows the in-game pause menu (Debug log, Resume). SPEC/program/debug-log-viewer.md.
/// Emits `OpenPanelEvent('pause_menu')` via [bus] to let AppEventHandler open the bottom sheet.
/// Menu item actions emit `ClosePanelEvent` and `NavigateToRouteEvent`.
void _showPauseMenu(AppEventBus bus) {
  bus.emit(
    OpenPanelEvent('pause_menu', {
      'onDebugLog': () {
        bus.emit(const ClosePanelEvent());
        bus.emit(NavigateToRouteEvent(Routes.debugLog));
      },
      'onResume': () => bus.emit(const ClosePanelEvent()),
    }),
  );
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
    final pendingOvertures = ref.watch(pendingOverturesProvider);
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
                if (result is TurnResolutionComplete) {
                  ref.read(currentGameProvider.notifier).state = result.game;
                  ref.read(currentOrdersProvider.notifier).state =
                      const Orders();
                } else if (result is TurnResolutionPendingOvertures) {
                  ref.read(currentGameProvider.notifier).state = result.game;
                  ref.read(pendingOverturesProvider.notifier).state =
                      result.pendingOvertures;
                }
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
          VictoryOverlay(game: game, victory: victory),
      ],
    );

    if (showIntro) {
      content = GameStartIntroOverlay(
        onDismissed: () {
          ref
              .read(gameIdsWithIntroShownProvider.notifier)
              .update((set) => {...set, game.id});
        },
        child: content,
      );
    }

    if (game != null &&
        pendingOvertures != null &&
        pendingOvertures.isNotEmpty) {
      content = OvertureDialogueOverlay(
        game: game,
        pendingOvertures: pendingOvertures,
        onDecisions: (decisions) {
          final service = ref.read(gameServiceProvider);
          final orders = ref.read(currentOrdersProvider);
          final result = service.resumeOvertureDecisions(
            game,
            pendingOvertures,
            decisions,
            orders,
          );
          ref.read(pendingOverturesProvider.notifier).state = null;
          if (result is TurnResolutionComplete) {
            ref.read(currentGameProvider.notifier).state = result.game;
            ref.read(currentOrdersProvider.notifier).state = const Orders();
          } else if (result is TurnResolutionPendingOvertures) {
            ref.read(currentGameProvider.notifier).state = result.game;
            ref.read(pendingOverturesProvider.notifier).state =
                result.pendingOvertures;
          }
        },
        child: content,
      );
    }

    return CtScreenShell(
      title: appL10n(context).game_screenTitle,
      child: content,
    );
  }
}
