part of 'ct_region_map_game.dart';

void _ctRegionMapGameSetCameraCenterWorld(CtRegionMapGame game, double x, double y) {
  game.camera.viewfinder.position = Vector2(x, y);
  game._clampCameraToMap();
  game.onRegionViewChanged?.call();
  game._emitViewportSnapshot();
}

void _ctRegionMapGamePanCameraWorld(CtRegionMapGame game, double dx, double dy) {
  if (dx == 0 && dy == 0) return;
  game.camera.viewfinder.position += Vector2(dx, dy);
  game._clampCameraToMap();
  game.onRegionViewChanged?.call();
  game._emitViewportSnapshot();
}

void _ctRegionMapGameCenterOnTileKey(CtRegionMapGame game, String tileKey) {
  final parsed = tryParseTileKey(tileKey);
  if (parsed == null || parsed.regionId != game.region.regionId) return;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 || x >= game.region.width || y < 0 || y >= game.region.height) {
    return;
  }
  final worldX = x * game.cellSizePx + game.cellSizePx / 2;
  final worldY = y * game.cellSizePx + game.cellSizePx / 2;
  game.camera.moveTo(Vector2(worldX, worldY));
  game._clampCameraToMap();
  game.onRegionViewChanged?.call();
  game._emitViewportSnapshot();
}

void _ctRegionMapGamePanBy(CtRegionMapGame game, Offset delta) {
  if (delta == Offset.zero) return;
  final z = game.camera.viewfinder.zoom;
  if (z <= 0 || !z.isFinite) return;
  game.camera.viewfinder.position -= Vector2(delta.dx, delta.dy) / z;
  game._clampCameraToMap();
  game.onRegionViewChanged?.call();
  game._emitViewportSnapshot();
}

void _ctRegionMapGameZoomBy(CtRegionMapGame game, double factor) {
  game._zoomMultiplier = (game._zoomMultiplier * factor).clamp(
    kRegionMapZoomMultiplierMin,
    kRegionMapZoomMultiplierMax,
  );
  game._syncCameraZoomFromMultiplier();
}

void _ctRegionMapGameSetZoomMultiplierAbsolute(
  CtRegionMapGame game,
  double multiplier,
) {
  game._zoomMultiplier = multiplier.clamp(
    kRegionMapZoomMultiplierMin,
    kRegionMapZoomMultiplierMax,
  );
  game._syncCameraZoomFromMultiplier();
}

void _ctRegionMapGameUpdateHoverFromLocal(
  CtRegionMapGame game,
  Offset localPosition,
) {
  if (!game._mapLoaded || game.size == Vector2.zero()) return;

  final z = game.camera.viewfinder.zoom;
  if (z <= 0 || !z.isFinite) return;
  final screen = Vector2(localPosition.dx, localPosition.dy);
  final halfView = game.size / 2;
  final world = game.camera.viewfinder.position + (screen - halfView) / z;

  game._mapComponent.updateHoverFromWorld(world);
}
