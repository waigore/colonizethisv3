
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../providers/games_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../region_map/region_map_component.dart' show BaseLayerDisplayMode;
import '../region_map/region_map_viewport_snapshot.dart';

import 'game_map_area_state_logic.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart';
import 'package:colonizethis_logic/debug_console_api.dart';
import 'package:colonizethis_orders/src/orders/per_player_work_target_selection_cache.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart';
import 'package:colonizethis_logic/src/turn_to_year.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart';
import 'package:colonizethis_logic/src/civilians/civilians_missing_work_orders.dart';

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
