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

import 'gp_ownership_tint_layer.dart';
import 'civilian_icon_cache.dart';
import 'fleet_icon_cache.dart';
import 'region_map_boundary_visibility.dart';
import 'region_map_province_overlay_geometry.dart';
import 'resource_icon_cache.dart';
import 'province_label_icon_cache.dart';
import 'terrain_tileset.dart';
import 'town_icon_cache.dart';
import 'transport_overlay_mask.dart';
import 'transport_overlay_tileset.dart';
import 'warp_zone_edge_geometry.dart';




part 'region_map_component_shared.dart';
part 'region_map_component_render_orchestrator.dart';
part 'region_map_component_render_core.dart';
part 'region_map_component_render_political.dart';
part 'region_map_component_render_markers.dart';

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
    await Future.wait([
      terrainTilesetCache.load(),
      transportOverlayTilesetCache.load(),
      resourceIconCache.load(),
      civilianIconCache.load(),
      townIconCache.load(),
      provinceLabelIconCache.load(),
    ]);
    // Fleet icon uses ui.decodeImageFromList; awaiting it here can deadlock with
    // Flutter's test/game bootstrap (decode needs frames while onLoad blocks).
    unawaited(
      fleetIconCache.load().catchError((Object _, StackTrace stackTrace) {
        // Errors are already logged inside FleetIconCache.load.
      }),
    );
    _log.i(
      'TerrainTilesetCache loaded. '
      'sea_plains: ${terrainTilesetCache.getSeaPlainsTileset() != null}, '
      'sea_desert: ${terrainTilesetCache.getSeaDesertTileset() != null}, '
      'plains_desert: ${terrainTilesetCache.getPlainsDesertTileset() != null}. '
      'TransportOverlayTilesetCache loaded: ${transportOverlayTilesetCache.isLoaded}. '
      'ResourceIconCache loaded: ${resourceIconCache.isLoaded}. '
      'CivilianIconCache loaded: ${civilianIconCache.isLoaded}. '
      'TownIconCache loaded: ${townIconCache.isLoaded}. '
      'ProvinceLabelIconCache loaded: ${provinceLabelIconCache.isLoaded}',
    );
    size = Vector2(region.width * cellSize, region.height * cellSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _hoverAnimationT += dt;
  }

  /// Updates hover state from a world-space position.
  void updateHoverFromWorld(Vector2 worldPosition) {
    final local = worldPosition - absoluteTopLeftPosition;
    final x = (local.x / cellSize).floor();
    final y = (local.y / cellSize).floor();
    _setHoverFromCell(x, y);
  }

  void _setHoverFromCell(int x, int y) {
    int? nx;
    int? ny;
    if (x >= 0 && x < region.width && y >= 0 && y < region.height) {
      final cell = region.cellAt(x, y);
      final isUnrevealed =
          visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed;
      if (!isUnrevealed) {
        nx = x;
        ny = y;
      }
    }
    final prevId = _hoveredTileX != null && _hoveredTileY != null
        ? '${region.regionId}|${region.cellAt(_hoveredTileX!, _hoveredTileY!).regionCellId}'
        : null;
    final nextId = nx != null && ny != null
        ? '${region.regionId}|${region.cellAt(nx, ny).regionCellId}'
        : null;
    if (prevId != nextId) {
      onProvinceHovered?.call(nextId);
    }
    final nextTileKey = nx != null && ny != null
        ? '${region.regionId}|${region.cellAt(nx, ny).regionCellId}|$nx|$ny'
        : null;
    onTileHovered?.call(nextTileKey);
    _hoveredTileX = nx;
    _hoveredTileY = ny;
    _hoveredProvinceId = nx != null && ny != null
        ? region.cellAt(nx, ny).regionCellId
        : null;
  }

  /// Handles a tap at the given world-space position.
  /// Reports province selection and the tapped tile (so overlay can show tile
  /// details on mobile where hover is unavailable). SPEC/ui/province-sea-zone-detail-overlay.md.
  void handleTapAtWorld(Vector2 worldPosition) {
    final local = worldPosition - absoluteTopLeftPosition;
    final x = (local.x / cellSize).floor();
    final y = (local.y / cellSize).floor();
    if (x < 0 || x >= region.width || y < 0 || y >= region.height) return;
    final cell = region.cellAt(x, y);
    final tileKey = '${region.regionId}|${cell.regionCellId}|$x|$y';
    if (validTileKeys != null) {
      // Work target mode: only valid tile taps commit selection.
      if (validTileKeys!.isNotEmpty && validTileKeys!.contains(tileKey)) {
        onTileTapped?.call(tileKey);
      }
      return;
    }
    final tappedFleet = _getFleetMarkerAtTile(x, y);
    if (tappedFleet != null) {
      onFleetMarkerTapped?.call(
        tappedFleet.locationScopeKey,
        tappedFleet.fleetIds.isNotEmpty ? tappedFleet.fleetIds.first : null,
        tappedFleet.tileKey,
      );
      return;
    }
    final tappedCivilian = _getCivilianMarkerAtTile(x, y);
    if (tappedCivilian != null) {
      onCivilianTileTapped?.call(tappedCivilian.tileKey);
      return;
    }
    if (selectedCivilianTileKey != null) {
      onCivilianTileSelectionCleared?.call();
    }
    // Not in work target mode: allow province selection.
    // Town or port icon hit (port may be on an adjacent sea tile). SPEC/ui/town-port-icons.md.
    final tappedTown = _getTownAtTile(x, y);
    if (tappedTown != null) {
      final provinceId = '${region.regionId}|${tappedTown.provinceId}';
      onTownIconTapped?.call(provinceId);
    }
    onMapTileTappedForDetail?.call(tileKey);
    final provinceIdForSelection = tappedTown != null
        ? '${region.regionId}|${tappedTown.provinceId}'
        : '${region.regionId}|${cell.regionCellId}';
    onProvinceSelected?.call(provinceIdForSelection);
  }

  FleetTileMarkerView? _getFleetMarkerAtTile(int x, int y) {
    for (final marker in region.fleetTileMarkers) {
      if (marker.x != x || marker.y != y) {
        continue;
      }
      return marker;
    }
    return null;
  }

  CivilianTileMarkerView? _getCivilianMarkerAtTile(int x, int y) {
    for (final marker in region.civilianTileMarkers) {
      if (marker.x != x || marker.y != y) continue;
      final cell = region.cellAt(x, y);
      final isUnrevealed =
          visibilityMode == CtMapVisibilityMode.playerConstrained &&
          cell.visibility == TileVisibility.unrevealed;
      if (isUnrevealed) {
        return null;
      }
      return marker;
    }
    return null;
  }

  TownMarkerView? _getTownAtTile(int x, int y) {
    for (final town in region.townMarkers) {
      if (town.x == x && town.y == y) {
        return town;
      }
      if (town.isPort) {
        final px = town.portIconX;
        final py = town.portIconY;
        if (px != null && py != null && px == x && py == y) {
          return town;
        }
      }
    }
    return null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _renderRegionMap(canvas);
  }
}

class _CornerValues {
  final bool nw;
  final bool ne;
  final bool sw;
  final bool se;
  final bool same;
  final bool value;

  _CornerValues({
    required this.nw,
    required this.ne,
    required this.sw,
    required this.se,
    required this.same,
    required this.value,
  });
}
