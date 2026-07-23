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
/// Civilian work-target tile selection for [GameMapArea]: maintaining the
/// per-player valid-tile cache, starting/cancelling a selection, and committing
/// the resulting work order (Refs #3699 Theme 3).
mixin GameMapAreaSelection on ConsumerState<GameMapArea>, GameMapAreaStateBase {
  void refreshWorkTargetSelectionCache(ct_models.Game game) {
    final view = buildPlayerView(
      game,
      widget.mapViewData.combinedTopology,
      mapPlayerId,
    );
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    workTargetSelectionCache.refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: mapPlayerId,
        playerView: view,
        topology: widget.mapViewData.combinedTopology,
        currentOrders: const ct_models.Orders(),
        tileMapByRegion: mapData?.tileMapByRegion,
      ),
    );
  }

  int? preferredRegionIndexForValidSelection(Set<String> validTileKeys) {
    if (validTileKeys.isEmpty) {
      return null;
    }
    final currentRegionId = currentRegion.regionId;
    final hasCurrent = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$currentRegionId|'),
    );
    if (hasCurrent) {
      return null;
    }
    final hasOldWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionOldWorld|'),
    );
    final hasNewWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionNewWorld|'),
    );
    if (hasOldWorld && !hasNewWorld) {
      return 0;
    }
    if (hasNewWorld && !hasOldWorld) {
      return 1;
    }
    return null;
  }

  void computeValidTileKeysForSelection() {
    if (workTargetSelection == null) {
      cachedValidTileKeys = null;
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) {
      cachedValidTileKeys = null;
      return;
    }
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, mapPlayerId);
    final workTarget = workTargetSelection!.workTarget;
    cachedValidTileKeys =
        GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
          workTarget: workTarget,
          workTargetSelectionCache: workTargetSelectionCache,
          humanPlayerId: mapPlayerId,
          selectedUnitId: workTargetSelection!.unit.id,
          game: game,
          currentOrders: orders,
          playerView: view,
          topology: topology,
          tileMapByRegion: mapData?.tileMapByRegion,
        );
  }

  ct_models.Unit? findUnitById(String unitId) {
    for (final unit in widget.game.worldState.oldWorld.units) {
      if (unit.id == unitId) return unit;
    }
    for (final unit in widget.game.worldState.newWorld.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  void startWorkTargetSelection(String unitId, String workTarget) {
    final unit = findUnitById(unitId);
    if (unit == null) return;
    setState(() {
      workTargetSelection = (unit: unit, workTarget: workTarget);
      computeValidTileKeysForSelection();
      final validTileKeys = cachedValidTileKeys;
      if (validTileKeys != null) {
        final preferredRegionIndex = preferredRegionIndexForValidSelection(
          validTileKeys,
        );
        if (preferredRegionIndex != null) {
          regionIndex = preferredRegionIndex;
        }
      }
    });
  }

  void cancelWorkTargetSelection() {
    if (workTargetSelection == null) {
      return;
    }
    setState(() {
      workTargetSelection = null;
      cachedValidTileKeys = null;
    });
  }

  void onTileSelectedForWork(String tileKey) {
    if (!ref.read(shellPlayerContextProvider).canMutateViaUi) {
      return;
    }
    final sel = workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    final targetTileKey = GameMapAreaStateLogic.translateWorkTargetTileKey(
      tileKey: tileKey,
      workTarget: target,
    );
    final workOrder = ct_models.WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    final orders = ref.read(currentOrdersProvider);
    ref
        .read(currentOrdersProvider.notifier)
        .replaceAll(
          GameMapAreaStateLogic.addHumanWorkOrder(
            orders: orders,
            humanPlayerId: mapPlayerId,
            workOrder: workOrder,
          ),
        );
    setState(() {
      selectedCivilianTileKey =
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: selectedCivilianTileKey,
            assignedTileKey: targetTileKey,
          );
      workTargetSelection = null;
      cachedValidTileKeys = null;
    });
  }
}
