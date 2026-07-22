import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Offset;

import 'ct_region_map_game_mixins.dart';
import 'region_map_viewport_snapshot.dart'
    show kRegionMapZoomMultiplierMax, kRegionMapZoomMultiplierMin;

void _ctRegionMapGameFinishCameraMove(CtRegionMapGameFields game) {
  (game as CtRegionMapGameCamera).clampCameraToMap();
  game.onRegionViewChanged?.call();
  (game as CtRegionMapGameCamera).emitViewportSnapshot();
}

void ctRegionMapGameSetCameraCenterWorld(
  CtRegionMapGameFields game,
  double x,
  double y,
) {
  game.camera.viewfinder.position = Vector2(x, y);
  _ctRegionMapGameFinishCameraMove(game);
}

void ctRegionMapGamePanCameraWorld(
  CtRegionMapGameFields game,
  double dx,
  double dy,
) {
  if (dx == 0 && dy == 0) return;
  game.camera.viewfinder.position += Vector2(dx, dy);
  _ctRegionMapGameFinishCameraMove(game);
}

void ctRegionMapGameCenterOnTileKey(CtRegionMapGameFields game, String tileKey) {
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
  _ctRegionMapGameFinishCameraMove(game);
}

void ctRegionMapGamePanBy(CtRegionMapGameFields game, Offset delta) {
  if (delta == Offset.zero) return;
  final z = game.camera.viewfinder.zoom;
  if (z <= 0 || !z.isFinite) return;
  game.camera.viewfinder.position -= Vector2(delta.dx, delta.dy) / z;
  _ctRegionMapGameFinishCameraMove(game);
}

void ctRegionMapGameZoomBy(CtRegionMapGameFields game, double factor) {
  game.state.zoomMultiplier = (game.state.zoomMultiplier * factor).clamp(
    kRegionMapZoomMultiplierMin,
    kRegionMapZoomMultiplierMax,
  );
  (game as CtRegionMapGameCamera).syncCameraZoomFromMultiplier();
}

void ctRegionMapGameSetZoomMultiplierAbsolute(
  CtRegionMapGameFields game,
  double multiplier,
) {
  game.state.zoomMultiplier = multiplier.clamp(
    kRegionMapZoomMultiplierMin,
    kRegionMapZoomMultiplierMax,
  );
  (game as CtRegionMapGameCamera).syncCameraZoomFromMultiplier();
}

void ctRegionMapGameUpdateHoverFromLocal(
  CtRegionMapGameFields game,
  Offset localPosition,
) {
  if (!game.state.mapLoaded || game.size == Vector2.zero()) return;

  final z = game.camera.viewfinder.zoom;
  if (z <= 0 || !z.isFinite) return;
  final screen = Vector2(localPosition.dx, localPosition.dy);
  final halfView = game.size / 2;
  final world = game.camera.viewfinder.position + (screen - halfView) / z;

  game.state.mapComponent.updateHoverFromWorld(world);
}
