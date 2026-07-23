import 'dart:math' as math;

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, resourceIdVisibleInPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../caches/province_label_icon_cache.dart';
import '../caches/resource_icon_cache.dart';
import '../render/gp_ownership_tint_layer.dart';
import '../tilesets/tilesets.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_province_overlay_geometry.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_shared_visibility.dart';
import 'region_map_component_support.dart';
import 'region_map_component_render_markers_selection.dart';
import 'region_map_component_render_markers_settlements_capitals.dart';
import 'region_map_component_render_markers_settlements_towns.dart';
import 'region_map_component_render_markers_settlements_warp.dart';
import 'region_map_component_render_markers_units_civilian.dart';
import 'region_map_component_render_markers_units_fleet.dart';

export 'region_map_component_shared_palette.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        RegionMapPalette,
        assertCtMapPlayerViewRequired,
        shouldShowExtractionUnitIndicators;
export 'region_map_component_shared_visibility.dart'
    show
        extractionIndicatorDisplaySizePx,
        extractionIndicatorRectsForIconRect,
        isCellUnderCivilianRevealHalo,
        isCellUnderFleetRevealHalo,
        isRailTransportLevel,
        paintResourceExtractionDiscIndicators,
        regionMapComponentDominantAdjacentLandBase,
        regionMapComponentIsFeatureTerrain,
        resolveProvinceLabelIconIds,
        resolveProvinceLabelPresenceIconIds,
        resolveSeaZoneLabelPrefixIconIds,
        resolveSeaZoneNamePlateCenterWorld,
        resourceIconDisplaySizePx,
        shouldApplyFogToFeatureOverlay,
        shouldApplyFogToInteriorPlainsVariantBase,
        shouldApplyFogToInteriorPlainsVariantOverlay,
        shouldApplyFogToLandBase,
        shouldEllipsizeProvinceLabelText,
        shouldPaintTransportOverlayForCell,
        shouldRenderTransportOverlay,
        shouldWrapProvinceLabelPresenceIcons,
        visibilityForTerrainForMapCell;
export 'region_map_component_support.dart';

part 'region_map_component_shared.dart';
part 'region_map_component_render_orchestrator.dart';
part 'region_map_component_render_core.dart';
part 'region_map_component_render_core_base_tiles_helpers.dart';
part 'region_map_component_render_core_base_tiles_sea.dart';
part 'region_map_component_render_core_base_tiles_land.dart';
part 'region_map_component_render_core_transport_feature.dart';
part 'region_map_component_render_core_overlays.dart';
part 'region_map_component_render_political_labels_province_compute.dart';
part 'region_map_component_render_political_labels_province_paint.dart';
part 'region_map_component_render_political_labels_sea.dart';
part 'region_map_component_render_political_borders_province.dart';
part 'region_map_component_render_political_borders_faction.dart';

final _log = packageLogger();

/// Flame-based region map component. Renders one RegionMapViewData and exposes
/// hover/selection state via callbacks. SPEC/ui/map-widget.md.
class CtRegionMapComponent extends PositionComponent {
  CtRegionMapComponent({
    required this.region,
    required this.cellSize,
    required this.showPoliticalOverlay,
    required this.showProvinceOverlay,
    required this.showProvinceOwnershipTint,
    required this.showProvinceNamesLayer,
    required this.visibilityMode,
    this.baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    this.onProvinceHovered,
    this.onTileHovered,
    this.onTileTapped,
    this.onCivilianTileTapped,
    this.onFleetMarkerTapped,
    this.onCivilianTileSelectionCleared,
    this.selectedTileKey,
    this.selectedCivilianTileKey,
    this.secondaryHighlightTileKey,
    this.secondaryHighlightTileKeys,
    this.validTileKeys,
    this.onTownIconTapped,
    this.playerViewForResources,
  });

  RegionMapViewData region;
  double cellSize;
  bool showPoliticalOverlay;
  bool showProvinceOverlay;
  bool showProvinceOwnershipTint;
  bool showProvinceNamesLayer;
  CtMapVisibilityMode visibilityMode;

  /// When [visibilityMode] is [CtMapVisibilityMode.playerConstrained], gates
  /// resource icons by fog + prospecting (SPEC/game/fog-and-exploration.md).
  /// Must be non-null in that mode; see [assertCtMapPlayerViewRequired].
  PlayerView? playerViewForResources;

  /// Camera zoom from Flame viewfinder; used to keep label size constant on screen.
  double cameraZoom = 1.0;
  BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  void Function(String? tileKey)? onTileTapped;
  void Function(String tileKey)? onCivilianTileTapped;
  void Function(
    String locationScopeKey,
    String? initialFleetId,
    String markerTileKey,
  )?
  onFleetMarkerTapped;
  VoidCallback? onCivilianTileSelectionCleared;
  String? selectedTileKey;
  String? selectedCivilianTileKey;
  String? secondaryHighlightTileKey;
  Set<String>? secondaryHighlightTileKeys;
  Set<String>? validTileKeys;
  void Function(String provinceId)? onTownIconTapped;

  /// Session fields shared by de-parted implementation libraries (Refs #4117).
  final CtRegionMapComponentSession session = CtRegionMapComponentSession();

  /// When true, topology/political border segments and hover glow segments are
  /// omitted unless at least one adjacent tile is not unrevealed. SPEC/ui/map-widget.md.
  bool get gateMapBoundariesByVisibility =>
      visibilityMode == CtMapVisibilityMode.playerConstrained;

  @override
  Future<void> onLoad() async {
    assertCtMapPlayerViewRequired(
      visibilityMode: visibilityMode,
      playerViewForResources: playerViewForResources,
    );
    await super.onLoad();
    await ctRegionMapComponentAfterSuperOnLoad(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    ctRegionMapComponentAdvanceHoverAnimation(this, dt);
  }

  /// Updates hover state from a world-space position.
  void updateHoverFromWorld(Vector2 worldPosition) =>
      ctRegionMapComponentUpdateHoverFromWorld(this, worldPosition);

  /// Handles a tap at the given world-space position.
  /// Reports province selection and the tapped tile (so overlay can show tile
  /// details on mobile where hover is unavailable). SPEC/ui/province-sea-zone-detail-overlay.md.
  void handleTapAtWorld(Vector2 worldPosition) =>
      ctRegionMapComponentHandleTapAtWorld(this, worldPosition);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderRegionMap(canvas);
  }
}
