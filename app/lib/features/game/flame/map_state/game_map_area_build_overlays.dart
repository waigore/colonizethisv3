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
import 'game_map_area_build_map_stack.dart';
/// Map play-area shell (keyboard focus, debug console, narrow detail slot).
/// Split from [game_map_area_build.dart] for Phase 3 flame map modularization.
mixin GameMapAreaBuildOverlays
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection,
        GameMapAreaE2e,
        GameMapAreaBuildMapStack {
  Widget buildMapPlayAreaStack({
    required BuildContext context,
    required bool isNarrow,
    required RegionMapViewData projectedRegion,
    required String mapPlayerId,
    required PlayerView mapPlayerView,
    required ShellPlayerContext shell,
    required List<PlayerTurnEventFeedEntry> feedEntries,
    required bool debugConsoleEnabled,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: isTurnResolving,
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (workTargetSelection != null &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  cancelWorkTargetSelection();
                  return KeyEventResult.handled;
                }
                if (sideMenuOpen &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  setState(() => sideMenuOpen = false);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: buildMapFocusedStack(
                context: context,
                isNarrow: isNarrow,
                projectedRegion: projectedRegion,
                mapPlayerId: mapPlayerId,
                mapPlayerView: mapPlayerView,
                shell: shell,
                feedEntries: feedEntries,
              ),
            ),
          ),
        ),
        if (debugConsoleEnabled && debugConsoleOpen)
          Positioned(
            left: kEdgeSwipeStripWidth + 60,
            top: 56,
            child: DebugConsoleOverlayPanel(
              bus: ref.read(appEventBusProvider),
              humanPlayerId: debugConsolePlayerId ?? mapPlayerId,
              readOnlyContextProvider: () {
                final selectedTileKey =
                    ref.read(mapProvincePanelProvider).selectedTileKey;
                final players = widget.game.players
                    .map(
                      (p) => DebugConsolePlayerSnapshot(
                        id: p.id,
                        displayName: p.displayName,
                        isHuman: p.isHuman,
                        capitalProvinceId: p.capitalProvinceId,
                      ),
                    )
                    .toList(growable: false);
                return DebugConsoleReadOnlyContext(
                  selectedTileKey: selectedTileKey,
                  players: players,
                );
              },
              onClose: () => setState(() => debugConsoleOpen = false),
            ),
          ),
        if (isNarrow)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameMapNarrowDetailOverlaySlot(
                  game: widget.game,
                  region: projectedRegion,
                  humanPlayerId: mapPlayerId,
                  playerView: mapPlayerView,
                  omniscientDetail: shell.omniscientDetail,
                  canMutateViaUi: shell.canMutateViaUi,
                  workTargetSelectionCache: workTargetSelectionCache,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
