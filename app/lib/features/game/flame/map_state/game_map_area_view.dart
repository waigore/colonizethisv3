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
/// Camera/view-state controls for [GameMapArea]: base-layer display cycling,
/// map view state persistence, capital centering, tile locating, and region
/// viewport snapshot handling (Refs #3699 Theme 3).
mixin GameMapAreaView on ConsumerState<GameMapArea>, GameMapAreaStateBase {
  void cycleBaseLayerDisplayMode() {
    setState(() {
      baseLayerDisplayMode = switch (baseLayerDisplayMode) {
        BaseLayerDisplayMode.terrainOnly =>
          BaseLayerDisplayMode.terrainAndResources,
        BaseLayerDisplayMode.terrainAndResources =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
        BaseLayerDisplayMode.terrainAndResourcesImprovementLabels =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads =>
          BaseLayerDisplayMode.terrainOnly,
      };
    });
  }

  void setMapViewState(ct_models.MapViewState next) {
    if (mapViewState == next) {
      return;
    }
    setState(() {
      mapViewState = next;
    });
    final current = ref.read(currentGameProvider);
    if (current != null && current.id == widget.game.id) {
      ref
          .read(currentGameProvider.notifier)
          .setGame(current.copyWith(mapViewState: next));
    }
  }

  void togglePlayerTurnEventsFeedVisibility() {
    setMapViewState(
      mapViewState.copyWith(
        showPlayerTurnEventsFeed: !mapViewState.showPlayerTurnEventsFeed,
      ),
    );
  }

  void togglePlayersBarVisibility() {
    setMapViewState(
      mapViewState.copyWith(showPlayersBar: !mapViewState.showPlayersBar),
    );
  }

  /// Runs the one-shot shell-entry auto-center on the current player's capital.
  /// Skipped in global observe (no `viewingPlayerId`) or when the current
  /// player has no capital. SPEC/ui/empire-overview.md § Initial map viewport.
  void maybeAutoCenterOnShellEntry() {
    if (didAutoCenterOnEntry) {
      return;
    }
    didAutoCenterOnEntry = true;
    final shell = ref.read(shellPlayerContextProvider);
    applyCapitalCenter(shell.viewingPlayerId);
  }

  /// Manual home-to-capital action: centers on the current player's capital.
  /// SPEC/ui/empire-overview.md § Home-to-capital button.
  void centerOnCurrentPlayerCapital() {
    final shell = ref.read(shellPlayerContextProvider);
    applyCapitalCenter(shell.mapPlayerIdFor(widget.game));
  }

  /// Switches the region tab, centers the camera, and sets the secondary
  /// highlight on [currentPlayerId]'s capital tile. No-op when the resolved
  /// target is null (global observe or no capital).
  void applyCapitalCenter(String? currentPlayerId) {
    final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
      game: widget.game,
      currentPlayerId: currentPlayerId,
    );
    if (target == null) {
      return;
    }
    ref
        .read(mapProvincePanelProvider.notifier)
        .setSecondaryHighlight(target.tileKey);
    setState(() {
      centerOnTileKey = target.tileKey;
      regionIndex = target.regionIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        centerOnTileKey = null;
      });
    });
  }

  void locateTile(String tileKey, String regionId) {
    ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(tileKey);
    setState(() {
      centerOnTileKey = tileKey;
      if (regionId == kRegionNewWorld) {
        regionIndex = 1;
      } else if (regionId == kRegionOldWorld) {
        regionIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => centerOnTileKey = null);
    });
  }

  void openMapTileDetail(String tileKey) {
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    ref.read(mapProvincePanelProvider.notifier).reportMapTileTapped(tileKey);
    setState(() {
      if (regionId == kRegionNewWorld) {
        regionIndex = 1;
      } else if (regionId == kRegionOldWorld) {
        regionIndex = 0;
      }
    });
  }

  void onRegionViewportSnapshot(RegionMapViewportSnapshot snapshot) {
    final clampedMultiplier = snapshot.zoomMultiplier.clamp(0.5, 8.0);
    if ((clampedMultiplier - mapViewState.zoomMultiplier).abs() > 0.001) {
      setMapViewState(
        mapViewState.copyWith(zoomMultiplier: clampedMultiplier),
      );
    }
    pendingRegionViewport = snapshot;
    if (regionViewportFrameScheduled) return;
    regionViewportFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      regionViewportFrameScheduled = false;
      if (!mounted) return;
      final next = pendingRegionViewport;
      pendingRegionViewport = null;
      if (next == null) return;
      final cur = regionViewportSnapshot;
      if (cur != null && cur.matches(next)) return;
      setState(() => regionViewportSnapshot = next);
    });
  }
}
