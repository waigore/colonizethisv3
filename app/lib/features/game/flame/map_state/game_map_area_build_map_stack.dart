
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:colonizethis_map/colonizethis_map.dart'
    show RegionMapViewData;

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../widgets/shell/shell_player_context.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../screens/game/game_screen_shared.dart';
import '../map_area/map_area.dart'
    show GameMapAreaBackground, GameMapCanvasStack;
import '../controls/controls.dart';
import '../../widgets/dialogs/game_map_options_dialog.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_view.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_e2e.dart';
import 'game_map_area_build_map_stack_chrome.dart';
import 'game_map_area_relocate_selection.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';

/// Map canvas stack and in-map overlay chrome (left rail, corner controls,
/// side menu, minimap, players bar, turn feed). Split from
/// [game_map_area_build_overlays.dart] for Phase 3 flame map modularization.
mixin GameMapAreaBuildMapStack
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection,
        GameMapAreaRelocateSelection,
        GameMapAreaE2e,
        GameMapAreaBuildMapStackChrome {
  Widget buildMapFocusedStack({
    required BuildContext context,
    required bool isNarrow,
    required RegionMapViewData projectedRegion,
    required String mapPlayerId,
    required PlayerView mapPlayerView,
    required ShellPlayerContext shell,
    required List<PlayerTurnEventFeedEntry> feedEntries,
  }) {
    return Stack(
      children: [
        const Positioned.fill(child: GameMapAreaBackground()),
        GameMapCanvasStack(
          isNarrow: isNarrow,
          game: widget.game,
          region: projectedRegion,
          baseLayerDisplayMode: baseLayerDisplayMode,
          showProvinceOverlay: mapViewState.showProvinceOverlay,
          showProvinceOwnershipTint: mapViewState.showProvinceOwnershipTint,
          showProvinceNamesLayer: mapViewState.showProvinceNamesLayer,
          showCapitalLinkDisconnectedHighlight:
              mapViewState.showCapitalLinkDisconnectedHighlight,
          humanPlayerId: mapPlayerId,
          playerView: mapPlayerView,
          visibilityMode: shell.mapVisibilityMode,
          omniscientDetail: shell.omniscientDetail,
          canMutateViaUi: shell.canMutateViaUi,
          workTargetSelectionCache: workTargetSelectionCache,
          centerOnTileKey: centerOnTileKey,
          validTileKeysForSelection: validTileKeysForSelection,
          selectedCivilianTileKey: selectedCivilianTileKey,
          onTileSelectedForWork: workTargetSelection != null
              ? onTileSelectedForWork
              : civilianRelocateSelection != null
              ? onTileSelectedForRelocate
              : null,
          onWorkTargetSelectionCancelled: inMapTileSelectionMode
              ? cancelAnyMapTileSelection
              : null,
          selectionPromptUsesRelocateCopy: civilianRelocateSelection != null,
          workTargetForSelection: workTargetSelection?.workTarget,
          hoveredWorkTargetTileKey: hoveredWorkTargetTileKey,
          lastValidHoveredWorkTargetTileKey: lastValidHoveredWorkTargetTileKey,
          onWorkTargetTileHovered: workTargetSelection != null
              ? onWorkTargetTileHovered
              : null,
          onCivilianTileStateChanged: (tileKey) {
            setState(() {
              selectedCivilianTileKey = tileKey;
            });
          },
          onCivilianTileSelectionCleared: () {
            if (selectedCivilianTileKey == null) return;
            setState(() {
              selectedCivilianTileKey = null;
            });
          },
          bus: ref.read(appEventBusProvider),
          onRegionViewportSnapshot: onRegionViewportSnapshot,
          zoomMultiplier: mapViewState.zoomMultiplier,
        ),
        if (!sideMenuOpen)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: kEdgeSwipeStripWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 20) {
                  setState(() => sideMenuOpen = true);
                }
              },
            ),
          ),
        Positioned(
          left: kEdgeSwipeStripWidth,
          top: 0,
          child: GameMapEmpireLeftRail(
            game: widget.game,
            humanPlayerId: mapPlayerId,
            narrow: isNarrow,
            onIconTappedWhileSelectionMode: inMapTileSelectionMode
                ? cancelAnyMapTileSelection
                : null,
          ),
        ),
        Positioned(
          left: kMapOverlayEdgeInset,
          bottom: kMapOverlayEdgeInset,
          child: GameMapCornerControls(
            narrow: isNarrow,
            onCycleBaseLayerDisplayMode: cycleBaseLayerDisplayMode,
            onCenterOnHomeCapital: centerOnCurrentPlayerCapital,
            homeToCapitalEnabled: shell.viewingPlayerId != null,
            onOpenMapDisplayOptions: () {
              showDialog<void>(
                context: context,
                barrierColor: EditorialMonoclePalette.dialogScrim,
                builder: (context) {
                  return GameMapOptionsDialog(
                    initialState: mapViewState,
                    onChanged: setMapViewState,
                  );
                },
              );
            },
          ),
        ),
        if (kCtE2EEnabled) ...buildE2eOverlayTaps(projectedRegion),
        if (sideMenuOpen) ...[
          Positioned.fill(
            child: GameSideMenuScrim(
              onDismiss: () => setState(() => sideMenuOpen = false),
            ),
          ),
          GameSideMenu(
            sideMenuOpen: sideMenuOpen,
            onClose: () => setState(() => sideMenuOpen = false),
          ),
        ],
        ...buildMapStackChromeChildren(
          isNarrow: isNarrow,
          projectedRegion: projectedRegion,
          mapPlayerId: mapPlayerId,
          shell: shell,
          feedEntries: feedEntries,
        ),
      ],
    );
  }
}
