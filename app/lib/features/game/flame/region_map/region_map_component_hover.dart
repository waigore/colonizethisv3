import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flame/components.dart';

import 'region_map_component.dart';

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
  int? visualX;
  int? visualY;
  int? callbackX;
  int? callbackY;
  if (x >= 0 &&
      x < component.region.width &&
      y >= 0 &&
      y < component.region.height) {
    callbackX = x;
    callbackY = y;
    final cell = component.region.cellAt(x, y);
    final isUnrevealed =
        component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed;
    if (!isUnrevealed) {
      visualX = x;
      visualY = y;
    }
  }
  final session = component.session;
  final prevId = session.hoveredTileX != null && session.hoveredTileY != null
      ? '${component.region.regionId}|${component.region.cellAt(session.hoveredTileX!, session.hoveredTileY!).regionCellId}'
      : null;
  final nextId = visualX != null && visualY != null
      ? '${component.region.regionId}|${component.region.cellAt(visualX, visualY).regionCellId}'
      : null;
  if (prevId != nextId) {
    component.onProvinceHovered?.call(nextId);
  }
  final nextTileKey = callbackX != null && callbackY != null
      ? '${component.region.regionId}|${component.region.cellAt(callbackX, callbackY).regionCellId}|$callbackX|$callbackY'
      : null;
  component.onTileHovered?.call(nextTileKey);
  session.hoveredTileX = visualX;
  session.hoveredTileY = visualY;
  session.hoveredProvinceId = visualX != null && visualY != null
      ? component.region.cellAt(visualX, visualY).regionCellId
      : null;
}
