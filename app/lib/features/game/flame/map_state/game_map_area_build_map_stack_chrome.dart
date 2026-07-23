import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData, RegionMapViewData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import '../../../../config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../screens/game/game_screen_shared.dart';
import '../map_area/map_area.dart'
    show GameMapAreaBackground, GameMapCanvasStack;
import '../controls/controls.dart';
import '../minimap/minimap.dart';
import '../overlays/game_map_narrow_detail_overlay.dart';
import '../overlays/debug_console_overlay_panel.dart';
import 'game_map_area_state_logic.dart';
import '../overlays/next_turn_confirmation_dialog.dart';
import '../overlays/turn_resolution_processing_dialog.dart';
import '../overlays/turn_resolution_progress_labels.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import 'map_location_resolver.dart';
import '../../widgets/dialogs/game_map_options_dialog.dart';
import '../../widgets/shell/game_map_players_bar.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/debug_console_provider.dart';
import '../../../../core/services/game_service/game_service.dart'
    show GameMapData, GameService;
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/region_minimap_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../region_map/region_map_component.dart' show BaseLayerDisplayMode;
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../../core/services/ai/ai_profile_resolution.dart';
import '../../../../core/services/subscription_tracker.dart';
import '../../../../core/services/turn_resolution/turn_resolution_blocking_service.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart';
import '../region_map/region_map_viewport_snapshot.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../../../providers/human_draft_projected_region_provider.dart';

import 'game_map_area_state_base.dart';
import 'game_map_area_widget.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_view.dart';
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
