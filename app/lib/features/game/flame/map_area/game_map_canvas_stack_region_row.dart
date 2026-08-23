import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/map_province_panel_provider.dart';
import '../../../../widgets/ct_region_map.dart' show CtRegionMap;
import '../overlays/game_map_province_detail_side_panel.dart';
import '../caches/per_player_army_move_picker_cache.dart';
import '../caches/per_player_work_target_selection_cache.dart';
import '../region_map/region_map_component.dart' show CtMapVisibilityMode;
import '../region_map/region_map_viewport_snapshot.dart';

Widget gameMapCanvasStackRegionRow({
  required WidgetRef ref,
  required bool isNarrow,
  required ct_models.Game game,
  required RegionMapViewData region,
  required MapBaseLayerFlags mapBaseLayerFlags,
  required bool showProvinceOverlay,
  required bool showProvinceOwnershipTint,
  required bool showProvinceNamesLayer,
  required bool showCapitalLinkDisconnectedHighlight,
  required String humanPlayerId,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required PerPlayerArmyMovePickerCache? armyMovePickerCache,
  required String? centerOnTileKey,
  required Set<String>? validTileKeysForSelection,
  required String? lastTurnPulseTileKey,
  required VoidCallback? onLastTurnPlaybackMapTap,
  required void Function(String tileKey)? onTileSelectedForWork,
  required VoidCallback? onWorkTargetSelectionCancelled,
  required String? selectedCivilianTileKey,
  required void Function(String tileKey)? onCivilianTileStateChanged,
  required VoidCallback? onCivilianTileSelectionCleared,
  required void Function(RegionMapViewportSnapshot snapshot)
  onRegionViewportSnapshot,
  required double zoomMultiplier,
  required CtMapVisibilityMode visibilityMode,
  required bool omniscientDetail,
  required bool canMutateViaUi,
  required ct_models.AppEventBus? bus,
  required ({
    String? selectedTileKey,
    String? secondaryHighlightTileKey,
    Set<String>? secondaryHighlightTileKeys,
  })
  highlights,
  required bool inWorkTargetSelectionMode,
  required void Function(String? tileKey)? onTileHovered,
  required void Function(String tileKey, Offset local)? onSecondary,
}) {
  return Row(
    children: [
      Expanded(
        child: CtRegionMap(
          region: region,
          cellSizePx: region.cellSize.toDouble(),
          showProvinceOverlay: showProvinceOverlay,
          showProvinceOwnershipTint: showProvinceOwnershipTint,
          showProvinceNamesLayer: showProvinceNamesLayer,
          showCapitalLinkDisconnectedHighlight:
              showCapitalLinkDisconnectedHighlight,
          visibilityMode: visibilityMode,
          playerViewForResources:
              visibilityMode == CtMapVisibilityMode.playerConstrained
              ? playerView
              : null,
          mapBaseLayerFlags: mapBaseLayerFlags,
          onProvinceSelected: null,
          onMapTileTappedForDetail: inWorkTargetSelectionMode
              ? null
              : onLastTurnPlaybackMapTap != null
              ? (_) => onLastTurnPlaybackMapTap()
              : (tk) => ref
                    .read(mapProvincePanelProvider.notifier)
                    .reportMapTileTapped(tk),
          onMapTileSecondaryForRadial: onLastTurnPlaybackMapTap != null
              ? null
              : onSecondary,
          onProvinceHovered: (_) {},
          onTileHovered: onTileHovered,
          onCivilianTileStateChanged: inWorkTargetSelectionMode
              ? null
              : onCivilianTileStateChanged,
          onCivilianTileSelectionCleared: inWorkTargetSelectionMode
              ? null
              : onCivilianTileSelectionCleared,
          selectedTileKey: highlights.selectedTileKey,
          selectedCivilianTileKey: selectedCivilianTileKey,
          secondaryHighlightTileKey: highlights.secondaryHighlightTileKey,
          secondaryHighlightTileKeys: highlights.secondaryHighlightTileKeys,
          centerOnTileKey: centerOnTileKey,
          validTileKeys: validTileKeysForSelection,
          lastTurnPulseTileKey: lastTurnPulseTileKey,
          onTileSelected: onTileSelectedForWork,
          onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
          bus: inWorkTargetSelectionMode ? null : bus,
          onViewportSnapshotChanged: onRegionViewportSnapshot,
          zoomMultiplier: zoomMultiplier,
        ),
      ),
      if (!isNarrow)
        GameMapProvinceDetailSidePanel(
          game: game,
          region: region,
          humanPlayerId: humanPlayerId,
          playerView: playerView,
          omniscientDetail: omniscientDetail,
          canMutateViaUi: canMutateViaUi,
          workTargetSelectionCache: workTargetSelectionCache,
          armyMovePickerCache: armyMovePickerCache,
        ),
    ],
  );
}
