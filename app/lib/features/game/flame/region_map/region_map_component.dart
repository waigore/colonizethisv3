import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, resourceIdVisibleInPlayerView;
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../render/gp_ownership_tint_layer.dart';
import '../caches/civilian_icon_cache.dart';
import '../caches/fleet_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_province_overlay_geometry.dart';
import '../caches/resource_icon_cache.dart';
import '../caches/province_label_icon_cache.dart';
import '../tilesets/tilesets.dart';
import '../caches/town_icon_cache.dart';
import '../render/warp_zone_edge_geometry.dart';




part 'region_map_component_shared.dart';
part 'region_map_component_shared_palette.dart';
part 'region_map_component_shared_label_placement.dart';
part 'region_map_component_shared_visibility_halos.dart';
part 'region_map_component_shared_visibility_labels.dart';
part 'region_map_component_shared_visibility.dart';
part 'region_map_component_shared_visibility_fog_transport.dart';
part 'region_map_component_shared_visibility_extraction.dart';
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
part 'region_map_component_render_markers_selection.dart';
part 'region_map_component_render_markers_settlements_capitals.dart';
part 'region_map_component_render_markers_settlements_towns.dart';
part 'region_map_component_render_markers_settlements_warp.dart';
part 'region_map_component_render_markers_units_civilian.dart';
part 'region_map_component_render_markers_units_fleet.dart';
part 'region_map_component_interaction.dart';
part 'region_map_component_lifecycle.dart';

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

  int? _hoveredTileX;
  int? _hoveredTileY;
  String? _hoveredProvinceId;
  double _hoverAnimationT = 0.0;

  /// When true, topology/political border segments and hover glow segments are
  /// omitted unless at least one adjacent tile is not unrevealed. SPEC/ui/map-widget.md.
  bool get _gateMapBoundariesByVisibility =>
      visibilityMode == CtMapVisibilityMode.playerConstrained;

  RegionMapViewData? _provinceLabelsRegionRef;
  double? _provinceLabelsCellSize;
  CtMapVisibilityMode? _provinceLabelsVisibilityMode;
  List<
    ({
      double cx,
      double cy,
      String text,
      String provinceId,
      Color plateColor,
      bool isCapital,
      int? avoidTileX,
      int? avoidTileY,
    })
  >?
  _provinceLabelsCached;

  RegionMapViewData? _seaZoneLabelsRegionRef;
  double? _seaZoneLabelsCellSize;
  List<({int cx, int cy, String text, bool isWarpZone})>? _seaZoneLabelsCached;

  @override
  Future<void> onLoad() async {
    assertCtMapPlayerViewRequired(
      visibilityMode: visibilityMode,
      playerViewForResources: playerViewForResources,
    );
    await super.onLoad();
    await _ctRegionMapComponentAfterSuperOnLoad(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _ctRegionMapComponentAdvanceHoverAnimation(this, dt);
  }

  /// Updates hover state from a world-space position.
  void updateHoverFromWorld(Vector2 worldPosition) =>
      _ctRegionMapComponentUpdateHoverFromWorld(this, worldPosition);

  /// Handles a tap at the given world-space position.
  /// Reports province selection and the tapped tile (so overlay can show tile
  /// details on mobile where hover is unavailable). SPEC/ui/province-sea-zone-detail-overlay.md.
  void handleTapAtWorld(Vector2 worldPosition) =>
      _ctRegionMapComponentHandleTapAtWorld(this, worldPosition);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderRegionMap(canvas);
  }
}
