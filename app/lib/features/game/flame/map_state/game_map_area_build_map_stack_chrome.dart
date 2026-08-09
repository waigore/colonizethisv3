
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_map/colonizethis_map.dart'
    show RegionMapViewData;

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../widgets/shell/shell_player_context.dart';

import '../../screens/game/game_screen_shared.dart';
import '../minimap/minimap.dart';
import '../../widgets/shell/game_map_players_bar.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_view.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_e2e.dart';

/// Minimap, players bar, and turn-feed overlay chrome for the map stack.
mixin GameMapAreaBuildMapStackChrome
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection,
        GameMapAreaE2e {
  List<Widget> buildMapStackChromeChildren({
    required bool isNarrow,
    required RegionMapViewData projectedRegion,
    required String mapPlayerId,
    required ShellPlayerContext shell,
    required List<PlayerTurnEventFeedEntry> feedEntries,
  }) {
    return [
      Consumer(
        builder: (context, ref, _) {
          final panelOpen = ref.watch(
            mapProvincePanelProvider.select((s) => s.overlayOpen),
          );
          final rightInset = !isNarrow
              ? gameMapWideOverlayRightInset(provincePanelOpen: panelOpen)
              : kGameMapWideStackRightGutter;
          return Positioned(
            right: rightInset,
            bottom: 8,
            child: GameRegionMinimap(
              region: projectedRegion,
              viewportSnapshot: regionViewportSnapshot,
              bus: ref.read(appEventBusProvider),
              cellSizePx: currentRegion.cellSize.toDouble(),
              narrow: isNarrow,
            ),
          );
        },
      ),
      // Players bar paints below the news feed card so an open feed card is
      // never obscured by player chips (mockup z-order: news card 7 > players
      // bar 5; issue #2861 M4). Keep this child earlier in the stack than the
      // feed cards below.
      if (!isNarrow &&
          widget.game.victory == null &&
          mapViewState.showPlayersBar)
        GameMapPlayersBar(
          game: widget.game,
          highlightPlayerId: shell.inObservePhase && shell.viewingPlayerId == null
              ? null
              : shell.viewingPlayerId ?? shell.effectiveHumanPlayerId,
        ),
      if (!isNarrow)
        Consumer(
          builder: (context, ref, _) {
            final panelOpen = ref.watch(
              mapProvincePanelProvider.select((s) => s.overlayOpen),
            );
            final rightInset = gameMapWideOverlayRightInset(
              provincePanelOpen: panelOpen,
            );
            if (!shell.showPlayerChrome ||
                !mapViewState.showPlayerTurnEventsFeed) {
              return const SizedBox.shrink();
            }
            return Positioned(
              right: rightInset,
              top: 56,
              child: PlayerTurnEventFeedCard(
                entries: feedEntries,
                emptyLabel: 'No player events last turn.',
              ),
            );
          },
        ),
      if (isNarrow &&
          widget.game.victory == null &&
          (mapViewState.showPlayersBar ||
              (shell.showPlayerChrome &&
                  mapViewState.showPlayerTurnEventsFeed)))
        Positioned(
          right: kMapOverlayEdgeInset,
          top: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (shell.showPlayerChrome &&
                  mapViewState.showPlayerTurnEventsFeed)
                PlayerTurnEventFeedCard(
                  entries: feedEntries,
                  emptyLabel: 'No player events last turn.',
                  narrow: true,
                ),
              if (mapViewState.showPlayersBar) ...[
                if (shell.showPlayerChrome &&
                    mapViewState.showPlayerTurnEventsFeed)
                  const SizedBox(
                    height: GameMapPlayersBar.narrowStackGap,
                  ),
                GameMapPlayersBar(
                  game: widget.game,
                  highlightPlayerId:
                      shell.inObservePhase && shell.viewingPlayerId == null
                      ? null
                      : shell.viewingPlayerId ?? shell.effectiveHumanPlayerId,
                  embedded: true,
                ),
              ],
            ],
          ),
        ),
    ];
  }
}
