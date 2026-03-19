export 'game_screen_shared.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
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
void _showPauseMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: Text(AppLocalizations.of(ctx)!.debugLog_title),
            onTap: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(Routes.debugLog);
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text(AppLocalizations.of(ctx)!.game_pauseMenu_resume),
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
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
              onPressed: () => _showPauseMenu(context),
              tooltip: AppLocalizations.of(context)!.game_pauseMenu_tooltip,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: CtNinePatchButton(
              onPressed: () {
                if (game == null) return;
                final service = ref.read(gameServiceProvider);
                final orders = ref.read(currentOrdersProvider);
                final result = service.runTurnResolution(game, orders: orders);
                if (result is TurnResolutionComplete) {
                  ref.read(currentGameProvider.notifier).state = result.game;
                  ref.read(currentOrdersProvider.notifier).state =
                      const ct_models.Orders();
                } else if (result is TurnResolutionPendingOvertures) {
                  ref.read(currentGameProvider.notifier).state = result.game;
                  ref.read(pendingOverturesProvider.notifier).state =
                      result.pendingOvertures;
                }
              },
              child: Text(
                AppLocalizations.of(context)!.game_nextTurnButton(
                  game!.worldState.turnState.turnNumber,
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
            ref.read(currentOrdersProvider.notifier).state =
                const ct_models.Orders();
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
      title: AppLocalizations.of(context)!.game_screenTitle,
      child: content,
    );
  }
}
