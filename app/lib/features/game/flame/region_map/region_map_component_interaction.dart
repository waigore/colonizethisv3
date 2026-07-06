part of 'region_map_component.dart';

void _ctRegionMapComponentUpdateHoverFromWorld(
  CtRegionMapComponent component,
  Vector2 worldPosition,
) {
  final local = worldPosition - component.absoluteTopLeftPosition;
  final x = (local.x / component.cellSize).floor();
  final y = (local.y / component.cellSize).floor();
  _ctRegionMapComponentSetHoverFromCell(component, x, y);
}

void _ctRegionMapComponentSetHoverFromCell(
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
  final prevId = component._hoveredTileX != null && component._hoveredTileY != null
      ? '${component.region.regionId}|${component.region.cellAt(component._hoveredTileX!, component._hoveredTileY!).regionCellId}'
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
  component._hoveredTileX = nx;
  component._hoveredTileY = ny;
  component._hoveredProvinceId = nx != null && ny != null
      ? component.region.cellAt(nx, ny).regionCellId
      : null;
}

/// Handles a tap at the given world-space position.
void _ctRegionMapComponentHandleTapAtWorld(
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
    // Work target mode: only valid tile taps commit selection.
    if (component.validTileKeys!.isNotEmpty &&
        component.validTileKeys!.contains(tileKey)) {
      component.onTileTapped?.call(tileKey);
    }
    return;
  }
  final tappedFleet = _ctRegionMapComponentGetFleetMarkerAtTile(component, x, y);
  if (tappedFleet != null) {
    component.onFleetMarkerTapped?.call(
      tappedFleet.locationScopeKey,
      tappedFleet.fleetIds.isNotEmpty ? tappedFleet.fleetIds.first : null,
      tappedFleet.tileKey,
    );
    return;
  }
  final tappedCivilian =
      _ctRegionMapComponentGetCivilianMarkerAtTile(component, x, y);
  if (tappedCivilian != null) {
    component.onCivilianTileTapped?.call(tappedCivilian.tileKey);
    return;
  }
  if (component.selectedCivilianTileKey != null) {
    component.onCivilianTileSelectionCleared?.call();
  }
  // Not in work target mode: allow province selection.
  // Town or port icon hit (port may be on an adjacent sea tile). SPEC/ui/town-port-icons.md.
  final tappedTown = _ctRegionMapComponentGetTownAtTile(component, x, y);
  if (tappedTown != null) {
    final provinceId = '${component.region.regionId}|${tappedTown.provinceId}';
    component.onTownIconTapped?.call(provinceId);
  }
  component.onMapTileTappedForDetail?.call(tileKey);
  final provinceIdForSelection = tappedTown != null
      ? '${component.region.regionId}|${tappedTown.provinceId}'
      : '${component.region.regionId}|${cell.regionCellId}';
  component.onProvinceSelected?.call(provinceIdForSelection);
}

FleetTileMarkerView? _ctRegionMapComponentGetFleetMarkerAtTile(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  for (final marker in component.region.fleetTileMarkers) {
    if (marker.x != x || marker.y != y) {
      continue;
    }
    return marker;
  }
  return null;
}

CivilianTileMarkerView? _ctRegionMapComponentGetCivilianMarkerAtTile(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  for (final marker in component.region.civilianTileMarkers) {
    if (marker.x != x || marker.y != y) continue;
    final cell = component.region.cellAt(x, y);
    final isUnrevealed =
        component.visibilityMode == CtMapVisibilityMode.playerConstrained &&
        cell.visibility == TileVisibility.unrevealed;
    if (isUnrevealed) {
      return null;
    }
    return marker;
  }
  return null;
}

TownMarkerView? _ctRegionMapComponentGetTownAtTile(
  CtRegionMapComponent component,
  int x,
  int y,
) {
  for (final town in component.region.townMarkers) {
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
