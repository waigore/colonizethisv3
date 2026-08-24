import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;

import 'package:colonizethis_orders/colonizethis_orders.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../region_map/region_map_component.dart' show CtMapVisibilityMode;
import '../../widgets/map_radial/game_map_tile_radial_host.dart';
import 'game_map_canvas_stack_hover.dart';
import 'game_map_canvas_stack_region_row.dart';
import 'game_map_canvas_stack_selection_prompt_layer.dart';
import '../region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

export 'game_map_canvas_stack_selection_prompt_tokens.dart';

/// Renders the Flame-backed map and the wide right-side detail panel.
/// Map and panel communicate only via [mapProvincePanelProvider].
class GameMapCanvasStack extends ConsumerWidget {
  const GameMapCanvasStack({
    required this.isNarrow,
    required this.game,
    required this.region,
    required this.mapBaseLayerFlags,
    required this.showProvinceOverlay,
    required this.showProvinceOwnershipTint,
    required this.showProvinceNamesLayer,
    required this.showCapitalLinkDisconnectedHighlight,
    required this.humanPlayerId,
    required this.playerView,
    required this.workTargetSelectionCache,
    this.armyMovePickerCache,
    required this.centerOnTileKey,
    required this.validTileKeysForSelection,
    this.lastTurnPulseTileKey,
    this.onLastTurnPlaybackMapTap,
    required this.onTileSelectedForWork,
    required this.onWorkTargetSelectionCancelled,
    required this.selectedCivilianTileKey,
    this.selectionPromptUsesRelocateCopy = false,
    this.workTargetForSelection,
    this.hoveredWorkTargetTileKey,
    this.lastValidHoveredWorkTargetTileKey,
    this.onWorkTargetTileHovered,
    required this.onCivilianTileStateChanged,
    required this.onCivilianTileSelectionCleared,
    required this.onRegionViewportSnapshot,
    required this.zoomMultiplier,
    this.visibilityMode = CtMapVisibilityMode.playerConstrained,
    this.omniscientDetail = false,
    this.canMutateViaUi = true,
    this.bus,
    super.key,
  });

  final bool isNarrow;
  final ct_models.Game game;
  final RegionMapViewData region;
  final MapBaseLayerFlags mapBaseLayerFlags;
  final bool showProvinceOverlay;
  final bool showProvinceOwnershipTint;
  final bool showProvinceNamesLayer;
  final bool showCapitalLinkDisconnectedHighlight;
  final String humanPlayerId;
  final PlayerView playerView;
  final PerPlayerWorkTargetSelectionCache workTargetSelectionCache;
  final PerPlayerArmyMovePickerCache? armyMovePickerCache;
  final String? centerOnTileKey;
  final Set<String>? validTileKeysForSelection;
  final String? lastTurnPulseTileKey;
  final VoidCallback? onLastTurnPlaybackMapTap;

  final void Function(String tileKey)? onTileSelectedForWork;
  final VoidCallback? onWorkTargetSelectionCancelled;
  final bool selectionPromptUsesRelocateCopy;
  final String? workTargetForSelection;
  final String? hoveredWorkTargetTileKey;
  final String? lastValidHoveredWorkTargetTileKey;
  final void Function(String? tileKey)? onWorkTargetTileHovered;
  final String? selectedCivilianTileKey;
  final void Function(String tileKey)? onCivilianTileStateChanged;
  final VoidCallback? onCivilianTileSelectionCleared;
  final void Function(RegionMapViewportSnapshot snapshot)
  onRegionViewportSnapshot;
  final double zoomMultiplier;
  final CtMapVisibilityMode visibilityMode;
  final bool omniscientDetail;
  final bool canMutateViaUi;
  final ct_models.AppEventBus? bus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow to map highlight fields so overlayOpen-only Chrome updates do not
    // rebuild the Flame host (Refs #4018).
    final highlights = ref.watch(
      mapProvincePanelProvider.select(mapCanvasHighlightSlice),
    );
    final inWorkTargetSelectionMode = validTileKeysForSelection != null;
    return Positioned.fill(
      child: Stack(
        children: [
          GameMapTileRadialHost(
            game: game,
            region: region,
            humanPlayerId: humanPlayerId,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
            canMutateViaUi: canMutateViaUi && !inWorkTargetSelectionMode,
            bus: bus,
            mapBuilder: (onSecondary) => GameMapCanvasStackHoverHost(
              inWorkTargetSelectionMode: inWorkTargetSelectionMode,
              game: game,
              region: region,
              onWorkTargetTileHovered: onWorkTargetTileHovered,
              mapBuilder: (onTileHovered) => gameMapCanvasStackRegionRow(
                onMapTileTapped: (tk) => ref
                    .read(mapProvincePanelProvider.notifier)
                    .reportMapTileTapped(tk),
                isNarrow: isNarrow,
                game: game,
                region: region,
                mapBaseLayerFlags: mapBaseLayerFlags,
                showProvinceOverlay: showProvinceOverlay,
                showProvinceOwnershipTint: showProvinceOwnershipTint,
                showProvinceNamesLayer: showProvinceNamesLayer,
                showCapitalLinkDisconnectedHighlight:
                    showCapitalLinkDisconnectedHighlight,
                humanPlayerId: humanPlayerId,
                playerView: playerView,
                workTargetSelectionCache: workTargetSelectionCache,
                armyMovePickerCache: armyMovePickerCache,
                centerOnTileKey: centerOnTileKey,
                validTileKeysForSelection: validTileKeysForSelection,
                lastTurnPulseTileKey: lastTurnPulseTileKey,
                onLastTurnPlaybackMapTap: onLastTurnPlaybackMapTap,
                onTileSelectedForWork: onTileSelectedForWork,
                onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
                selectedCivilianTileKey: selectedCivilianTileKey,
                onCivilianTileStateChanged: onCivilianTileStateChanged,
                onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
                onRegionViewportSnapshot: onRegionViewportSnapshot,
                zoomMultiplier: zoomMultiplier,
                visibilityMode: visibilityMode,
                omniscientDetail: omniscientDetail,
                canMutateViaUi: canMutateViaUi,
                bus: bus,
                highlights: highlights,
                inWorkTargetSelectionMode: inWorkTargetSelectionMode,
                onTileHovered: onTileHovered,
                onSecondary: onSecondary,
              ),
            ),
          ),
          if (inWorkTargetSelectionMode)
            GameMapCanvasStackSelectionPromptLayer(
              isNarrow: isNarrow,
              game: game,
              humanPlayerId: humanPlayerId,
              onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
              selectionPromptUsesRelocateCopy: selectionPromptUsesRelocateCopy,
              workTargetForSelection: workTargetForSelection,
              hoveredWorkTargetTileKey: hoveredWorkTargetTileKey,
              lastValidHoveredWorkTargetTileKey:
                  lastValidHoveredWorkTargetTileKey,
              canMutateViaUi: canMutateViaUi,
            ),
        ],
      ),
    );
  }
}
