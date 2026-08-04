import 'dart:async' show unawaited;

import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../caches/civilian_icon_cache.dart';
import '../caches/fleet_icon_cache.dart';
import '../caches/province_label_icon_cache.dart';
import '../caches/resource_icon_cache.dart';
import '../caches/town_icon_cache.dart';
import '../tilesets/tilesets.dart';
import 'region_map_component.dart';

/// Mutable session fields for de-parted [CtRegionMapComponent] libraries (Refs #4117).
class CtRegionMapComponentSession {
  int? hoveredTileX;
  int? hoveredTileY;
  String? hoveredProvinceId;
  double hoverAnimationT = 0.0;
  RegionMapViewData? provinceLabelsRegionRef;
  double? provinceLabelsCellSize;
  CtMapVisibilityMode? provinceLabelsVisibilityMode;
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
  provinceLabelsCached;
  RegionMapViewData? seaZoneLabelsRegionRef;
  double? seaZoneLabelsCellSize;
  List<({int cx, int cy, String text, bool isWarpZone})>? seaZoneLabelsCached;
}

final regionMapComponentLifecycleLog = packageLogger();

Future<void> ctRegionMapComponentAfterSuperOnLoad(
  CtRegionMapComponent component,
) async {
  await Future.wait([
    terrainTilesetCache.load(),
    transportOverlayTilesetCache.load(),
    resourceIconCache.load(),
    civilianIconCache.load(),
    townIconCache.load(),
    provinceLabelIconCache.load(),
  ]);
  unawaited(
    fleetIconCache.load().catchError((Object _, StackTrace stackTrace) {}),
  );
  regionMapComponentLifecycleLog.i(
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
  component.size = Vector2(
    component.region.width * component.cellSize,
    component.region.height * component.cellSize,
  );
}

void ctRegionMapComponentAdvanceHoverAnimation(
  CtRegionMapComponent component,
  double dt,
) {
  component.session.hoverAnimationT += dt;
}

void ctRegionMapComponentUpdateHoverFromWorld(
  CtRegionMapComponent component,
  Vector2 worldPosition,
) {
  final local = worldPosition - component.absoluteTopLeftPosition;
  ctRegionMapComponentSetHoverFromCell(
    component,
    (local.x / component.cellSize).floor(),
    (local.y / component.cellSize).floor(),
  );
}

void ctRegionMapComponentSetHoverFromCell(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  int? nx;
  int? ny;
  if (x >= 0 &&
      x < component.region.width &&
      y >= 0 &&
      y < component.region.height) {
    final cell = component.region.cellAt(x, y);
    final isUnrevealed =
        component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed;
    if (!isUnrevealed) {
      nx = x;
      ny = y;
    }
  }
  final session = component.session;
  final prevId =
      session.hoveredTileX != null && session.hoveredTileY != null
      ? '${component.region.regionId}|${component.region.cellAt(session.hoveredTileX!, session.hoveredTileY!).regionCellId}'
      : null;
  final nextId = nx != null && ny != null
      ? '${component.region.regionId}|${component.region.cellAt(nx, ny).regionCellId}'
      : null;
  if (prevId != nextId) {
    component.onProvinceHovered?.call(nextId);
  }
  final nextTileKey = nx != null && ny != null
      ? '${component.region.regionId}|${component.region.cellAt(nx, ny).regionCellId}|$nx|$ny'
      : null;
  component.onTileHovered?.call(nextTileKey);
  session.hoveredTileX = nx;
  session.hoveredTileY = ny;
  session.hoveredProvinceId = nx != null && ny != null
      ? component.region.cellAt(nx, ny).regionCellId
      : null;
}

void ctRegionMapComponentHandleTapAtWorld(
  CtRegionMapComponent component,
  Vector2 worldPosition,
) {
  final local = worldPosition - component.absoluteTopLeftPosition;
  final x = (local.x / component.cellSize).floor();
  final y = (local.y / component.cellSize).floor();
  if (x < 0 ||
      x >= component.region.width ||
      y < 0 ||
      y >= component.region.height) {
    return;
  }
  final cell = component.region.cellAt(x, y);
  final tileKey = '${component.region.regionId}|${cell.regionCellId}|$x|$y';
  if (component.validTileKeys != null) {
    if (component.validTileKeys!.isNotEmpty &&
        component.validTileKeys!.contains(tileKey)) {
      component.onTileTapped?.call(tileKey);
    }
    return;
  }
  final tappedFleet = ctRegionMapComponentGetFleetMarkerAtTile(component, x, y);
  if (tappedFleet != null) {
    component.onFleetMarkerTapped?.call(
      tappedFleet.locationScopeKey,
      tappedFleet.fleetIds,
      tappedFleet.tileKey,
    );
    return;
  }
  final tappedCivilian = ctRegionMapComponentGetCivilianMarkerAtTile(
    component,
    x,
    y,
  );
  if (tappedCivilian != null) {
    component.onCivilianTileTapped?.call(tappedCivilian.tileKey);
    return;
  }
  if (component.selectedCivilianTileKey != null) {
    component.onCivilianTileSelectionCleared?.call();
  }
  final tappedTown = ctRegionMapComponentGetTownAtTile(component, x, y);
  if (tappedTown != null) {
    component.onTownIconTapped?.call(
      '${component.region.regionId}|${tappedTown.provinceId}',
    );
  }
  component.onMapTileTappedForDetail?.call(tileKey);
  component.onProvinceSelected?.call(
    tappedTown != null
        ? '${component.region.regionId}|${tappedTown.provinceId}'
        : '${component.region.regionId}|${cell.regionCellId}',
  );
}

FleetTileMarkerView? ctRegionMapComponentGetFleetMarkerAtTile(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  for (final marker in component.region.fleetTileMarkers) {
    if (marker.x == x && marker.y == y) return marker;
  }
  return null;
}

CivilianTileMarkerView? ctRegionMapComponentGetCivilianMarkerAtTile(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  for (final marker in component.region.civilianTileMarkers) {
    if (marker.x != x || marker.y != y) continue;
    final cell = component.region.cellAt(x, y);
    if (component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed) {
      return null;
    }
    return marker;
  }
  return null;
}

TownMarkerView? ctRegionMapComponentGetTownAtTile(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  for (final town in component.region.townMarkers) {
    if (town.x == x && town.y == y) return town;
    if (town.isPort) {
      final px = town.portIconX;
      final py = town.portIconY;
      if (px != null && py != null && px == x && py == y) return town;
    }
  }
  return null;
}

/// Effective terrain visibility for [CtRegionMapComponent] render passes.
TileVisibility regionMapComponentVisibilityForTerrain(
  CtRegionMapComponent component,
  CellViewData cell,
) {
  return visibilityForTerrainForMapCell(
    visibilityMode: component.visibilityMode,
    cell: cell,
    fleetTileMarkers: component.region.fleetTileMarkers,
    civilianTileMarkers: component.region.civilianTileMarkers,
  );
}
