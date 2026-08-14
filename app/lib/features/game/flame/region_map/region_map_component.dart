import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show MapBaseLayerFlags;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'region_map_component_render_core.dart';
import 'region_map_component_shared_palette.dart';
import 'region_map_component_support.dart';

export 'region_map_component_shared_palette.dart'
    show
        BaseLayerDisplayMode,
        CtMapVisibilityMode,
        RegionMapPalette,
        assertCtMapPlayerViewRequired,
        mapBaseLayerFlagsFromDisplayMode,
        resolveMapBaseLayerFlags,
        shouldShowExtractionUnitIndicators,
        shouldShowImprovementLabels,
        shouldShowResourceIcons;
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
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

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
    this.showCapitalLinkDisconnectedHighlight = true,
    this.mapBaseLayerFlags = MapBaseLayerFlags.fullDetail,
    this.baseLayerDisplayMode =
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
    this.onProvinceSelected,
    this.onMapTileTappedForDetail,
    this.onProvinceHovered,
    this.onTileHovered,
    this.onTileTapped,
    this.onCivilianTileTapped,
    this.onFleetMarkerTapped,
    this.onArmyMarkerTapped,
    this.onCivilianTileSelectionCleared,
    this.selectedTileKey,
    this.selectedCivilianTileKey,
    this.secondaryHighlightTileKey,
    this.secondaryHighlightTileKeys,
    this.validTileKeys,
    this.onTownIconTapped,
    this.playerViewForResources,
    this.showPlayerTerritoryOutline = false,
    this.playerTerritoryTileKeys,
  });

  RegionMapViewData region;
  double cellSize;
  bool showPoliticalOverlay;
  bool showProvinceOverlay;
  bool showProvinceOwnershipTint;
  bool showProvinceNamesLayer;
  bool showCapitalLinkDisconnectedHighlight;
  CtMapVisibilityMode visibilityMode;

  /// When [visibilityMode] is [CtMapVisibilityMode.playerConstrained], gates
  /// resource icons by fog + prospecting (SPEC/game/fog-and-exploration.md).
  /// Must be non-null in that mode; see [assertCtMapPlayerViewRequired].
  PlayerView? playerViewForResources;

  /// Light outer-perimeter stroke for player-owned land (panel maps). Refs #4175.
  bool showPlayerTerritoryOutline;
  Set<String>? playerTerritoryTileKeys;

  /// Camera zoom from Flame viewfinder; used to keep label size constant on screen.
  double cameraZoom = 1.0;

  /// Paint-boundary flags (Refs #4388). [baseLayerDisplayMode] remains a
  /// Widgetbook convenience and must not be read by paint predicates.
  MapBaseLayerFlags mapBaseLayerFlags;
  BaseLayerDisplayMode baseLayerDisplayMode;
  void Function(String provinceId)? onProvinceSelected;
  void Function(String tileKey)? onMapTileTappedForDetail;
  void Function(String? provinceId)? onProvinceHovered;
  void Function(String? tileKey)? onTileHovered;
  void Function(String? tileKey)? onTileTapped;
  void Function(String tileKey)? onCivilianTileTapped;
  void Function(
    String locationScopeKey,
    List<String> fleetIds,
    String markerTileKey,
  )?
  onFleetMarkerTapped;
  void Function(ArmyTileMarkerView marker)? onArmyMarkerTapped;
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
    renderRegionMap(canvas);
  }
}
