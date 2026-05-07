import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

import '../../features/game/flame/ct_region_map_game.dart';
import '../../features/game/flame/region_map_component.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import '../../features/game/flame/region_map_viewport_snapshot.dart'
    show RegionMapViewportSnapshot;
import '../../features/game/widgets/chrome/region_map_game_viewport.dart';
export '../../features/game/flame/ct_region_map_game.dart' show CtRegionMapGame;
export '../../features/game/flame/region_map_component.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode, assertCtMapPlayerViewRequired;
export '../../features/game/flame/region_map_viewport_snapshot.dart'
    show RegionMapViewportSnapshot;

/// Narrow, non-widget binding surface for region-map Flame integrations.
typedef CreateCtRegionMapGame = CtRegionMapGame Function({
  required RegionMapViewData region,
  required double cellSizePx,
  required bool showPoliticalOverlay,
  required bool showProvinceOverlay,
  required bool showProvinceOwnershipTint,
  required bool showProvinceNamesLayer,
  required CtMapVisibilityMode visibilityMode,
  required BaseLayerDisplayMode baseLayerDisplayMode,
  required void Function(String provinceId)? onProvinceSelected,
  required void Function(String tileKey)? onMapTileTappedForDetail,
  required VoidCallback? onRegionViewChanged,
  required void Function(String? provinceId)? onProvinceHovered,
  required void Function(String? tileKey)? onTileHovered,
  required void Function(String tileKey)? onCivilianTileTapped,
  required void Function(
    String locationScopeKey,
    String? initialFleetId,
    String markerTileKey,
  )?
  onFleetMarkerTapped,
  required VoidCallback? onCivilianTileSelectionCleared,
  required String? selectedTileKey,
  required String? selectedCivilianTileKey,
  required String? secondaryHighlightTileKey,
  required Set<String>? validTileKeys,
  required void Function(String tileKey)? onTileSelected,
  required VoidCallback? onWorkTargetSelectionCancelled,
  required void Function(String provinceId)? onTownIconTapped,
  required PlayerView? playerViewForResources,
  required void Function(RegionMapViewportSnapshot viewport)?
  onViewportSnapshotChanged,
  required double initialZoomMultiplier,
});

CtRegionMapGame defaultCreateCtRegionMapGame({
  required RegionMapViewData region,
  required double cellSizePx,
  required bool showPoliticalOverlay,
  required bool showProvinceOverlay,
  required bool showProvinceOwnershipTint,
  required bool showProvinceNamesLayer,
  required CtMapVisibilityMode visibilityMode,
  required BaseLayerDisplayMode baseLayerDisplayMode,
  required void Function(String provinceId)? onProvinceSelected,
  required void Function(String tileKey)? onMapTileTappedForDetail,
  required VoidCallback? onRegionViewChanged,
  required void Function(String? provinceId)? onProvinceHovered,
  required void Function(String? tileKey)? onTileHovered,
  required void Function(String tileKey)? onCivilianTileTapped,
  required void Function(
    String locationScopeKey,
    String? initialFleetId,
    String markerTileKey,
  )?
  onFleetMarkerTapped,
  required VoidCallback? onCivilianTileSelectionCleared,
  required String? selectedTileKey,
  required String? selectedCivilianTileKey,
  required String? secondaryHighlightTileKey,
  required Set<String>? validTileKeys,
  required void Function(String tileKey)? onTileSelected,
  required VoidCallback? onWorkTargetSelectionCancelled,
  required void Function(String provinceId)? onTownIconTapped,
  required PlayerView? playerViewForResources,
  required void Function(RegionMapViewportSnapshot viewport)?
  onViewportSnapshotChanged,
  required double initialZoomMultiplier,
}) {
  return CtRegionMapGame(
    region: region,
    cellSizePx: cellSizePx,
    showPoliticalOverlay: showPoliticalOverlay,
    showProvinceOverlay: showProvinceOverlay,
    showProvinceOwnershipTint: showProvinceOwnershipTint,
    showProvinceNamesLayer: showProvinceNamesLayer,
    visibilityMode: visibilityMode,
    baseLayerDisplayMode: baseLayerDisplayMode,
    onProvinceSelected: onProvinceSelected,
    onMapTileTappedForDetail: onMapTileTappedForDetail,
    onRegionViewChanged: onRegionViewChanged,
    onProvinceHovered: onProvinceHovered,
    onTileHovered: onTileHovered,
    onCivilianTileTapped: onCivilianTileTapped,
    onFleetMarkerTapped: onFleetMarkerTapped,
    onCivilianTileSelectionCleared: onCivilianTileSelectionCleared,
    selectedTileKey: selectedTileKey,
    selectedCivilianTileKey: selectedCivilianTileKey,
    secondaryHighlightTileKey: secondaryHighlightTileKey,
    validTileKeys: validTileKeys,
    onTileSelected: onTileSelected,
    onWorkTargetSelectionCancelled: onWorkTargetSelectionCancelled,
    onTownIconTapped: onTownIconTapped,
    playerViewForResources: playerViewForResources,
    onViewportSnapshotChanged: onViewportSnapshotChanged,
    initialZoomMultiplier: initialZoomMultiplier,
  );
}

RegionMapGameViewport buildRegionMapGameViewport(CtRegionMapGame game) {
  return RegionMapGameViewport(game: game);
}
