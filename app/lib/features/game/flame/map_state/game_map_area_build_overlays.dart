
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';

import 'package:colonizethis_map/colonizethis_map.dart'
    show RegionMapViewData;

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../widgets/shell/shell_player_context.dart';

import '../../screens/game/game_screen_shared.dart';
import '../overlays/game_map_narrow_detail_overlay.dart';
import '../overlays/debug_console_overlay_panel.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_view.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_e2e.dart';
import 'game_map_area_build_map_stack.dart';
import 'game_map_area_relocate_selection.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Map play-area shell (keyboard focus, debug console, narrow detail slot).
/// Split from [game_map_area_build.dart] for Phase 3 flame map modularization.
mixin GameMapAreaBuildOverlays
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection,
        GameMapAreaRelocateSelection,
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
                if (inMapTileSelectionMode &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  cancelAnyMapTileSelection();
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
                  armyMovePickerCache: armyMovePickerCache,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
