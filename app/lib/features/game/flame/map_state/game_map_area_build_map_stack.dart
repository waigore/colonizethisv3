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
import 'game_map_area_build_map_stack_chrome.dart';
/// Map canvas stack and in-map overlay chrome (left rail, corner controls,
/// side menu, minimap, players bar, turn feed). Split from
/// [game_map_area_build_overlays.dart] for Phase 3 flame map modularization.
mixin GameMapAreaBuildMapStack
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection,
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
              : null,
          onWorkTargetSelectionCancelled: workTargetSelection != null
              ? cancelWorkTargetSelection
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
            onIconTappedWhileSelectionMode: workTargetSelection != null
                ? cancelWorkTargetSelection
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
