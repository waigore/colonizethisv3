/// Secondary-pointer tile hit test (no marker side effects). Refs #4440.
library;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';

import 'region_map_component.dart';
import 'region_map_component_support.dart';

/// Tile key if [worldPosition] is a bare tile (markers miss). Null otherwise.
String? ctRegionMapComponentTileKeyForSecondaryAtWorld(
  CtRegionMapComponent component,
  Vector2 worldPosition,
) {
  if (component.validTileKeys != null) {
    return null;
  }
  final local = worldPosition - component.absoluteTopLeftPosition;
  final x = (local.x / component.cellSize).floor();
  final y = (local.y / component.cellSize).floor();
  if (x < 0 ||
      x >= component.region.width ||
      y < 0 ||
      y >= component.region.height) {
    return null;
  }
  if (ctRegionMapComponentGetArmyMarkerAtLocal(
        component,
        local.x,
        local.y,
        x,
        y,
      ) !=
      null) {
    return null;
  }
  if (ctRegionMapComponentGetFleetMarkerAtTile(component, x, y) != null) {
    return null;
  }
  if (ctRegionMapComponentGetCivilianMarkerAtTile(component, x, y) != null) {
    return null;
  }
  final cell = component.region.cellAt(x, y);
  return '${component.region.regionId}|${cell.regionCellId}|$x|$y';
}
