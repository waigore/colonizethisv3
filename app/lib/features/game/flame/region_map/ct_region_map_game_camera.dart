import 'package:flame/game.dart';

import 'ct_region_map_game_fields.dart';
import 'region_map_viewport_snapshot.dart'
    show
        RegionMapViewportSnapshot,
        computeRegionMapFitMapZoom,
        kRegionMapZoomMultiplierMax,
        kRegionMapZoomMultiplierMin;

mixin CtRegionMapGameCamera on CtRegionMapGameFields {
  void syncCameraZoomFromMultiplier() {
    if (!state.mapLoaded || size == Vector2.zero()) return;
    state.zoomMultiplier = state.zoomMultiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final zFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: size.x,
      viewportHeightLogical: size.y,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    camera.viewfinder.zoom = state.zoomMultiplier * zFit;
    clampCameraToMap();
    onRegionViewChanged?.call();
    emitViewportSnapshot();
  }

  void emitViewportSnapshot() {
    final cb = onViewportSnapshotChanged;
    if (cb == null) return;
    if (!state.mapLoaded || size == Vector2.zero()) return;
    final mw = region.width * cellSizePx;
    final mh = region.height * cellSizePx;
    final zFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: size.x,
      viewportHeightLogical: size.y,
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    cb(
      RegionMapViewportSnapshot(
        regionId: region.regionId,
        cellSizePx: cellSizePx,
        mapWidthWorld: mw,
        mapHeightWorld: mh,
        cameraCenterX: camera.viewfinder.position.x,
        cameraCenterY: camera.viewfinder.position.y,
        zoom: camera.viewfinder.zoom,
        fitMapZoom: zFit,
        viewportWidthLogical: size.x,
        viewportHeightLogical: size.y,
      ),
    );
  }

  void handleGameResize(Vector2 size, Vector2? previousSize) {
    if (!state.mapLoaded) return;
    if (previousSize == null || previousSize == Vector2.zero()) {
      syncCameraZoomFromMultiplier();
      return;
    }
    final oldZoom = camera.viewfinder.zoom;
    if (oldZoom <= 0 || !oldZoom.isFinite) {
      syncCameraZoomFromMultiplier();
      return;
    }
    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;
    final newZFit = computeRegionMapFitMapZoom(
      viewportWidthLogical: size.x,
      viewportHeightLogical: size.y,
      mapWidthWorld: mapWidth,
      mapHeightWorld: mapHeight,
    );
    state.zoomMultiplier = state.zoomMultiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    final newZoom = state.zoomMultiplier * newZFit;
    final oldViewW = previousSize.x / oldZoom;
    final oldViewH = previousSize.y / oldZoom;
    final newViewW = size.x / newZoom;
    final newViewH = size.y / newZoom;
    var center = camera.viewfinder.position.clone();
    if (newViewW != oldViewW && mapWidth > newViewW) {
      final halfNewW = newViewW / 2;
      final minX = halfNewW;
      final maxX = mapWidth - halfNewW;
      if (newViewW > oldViewW) {
        center.x = (center.x + (oldViewW - newViewW) / 2)
            .clamp(minX, maxX)
            .toDouble();
      } else {
        center.x = center.x.clamp(minX, maxX).toDouble();
      }
    }
    if (newViewH != oldViewH && mapHeight > newViewH) {
      final halfNewH = newViewH / 2;
      final minY = halfNewH;
      final maxY = mapHeight - halfNewH;
      if (newViewH > oldViewH) {
        center.y = (center.y + (oldViewH - newViewH) / 2)
            .clamp(minY, maxY)
            .toDouble();
      } else {
        center.y = center.y.clamp(minY, maxY).toDouble();
      }
    }
    camera.viewfinder.position = center;
    camera.viewfinder.zoom = newZoom;
    clampCameraToMap();
    onRegionViewChanged?.call();
    emitViewportSnapshot();
  }

  void clampCameraToMap() {
    final mapWidth = region.width * cellSizePx;
    final mapHeight = region.height * cellSizePx;
    final z = camera.viewfinder.zoom;
    if (z <= 0 || !z.isFinite) return;
    final viewW = size.x / z;
    final viewH = size.y / z;
    if (mapWidth <= viewW && mapHeight <= viewH) {
      camera.viewfinder.position = Vector2(mapWidth / 2, mapHeight / 2);
      return;
    }
    final pos = camera.viewfinder.position.clone();
    if (mapWidth > viewW) {
      final halfW = viewW / 2;
      pos.x = pos.x.clamp(halfW, mapWidth - halfW).toDouble();
    } else {
      pos.x = mapWidth / 2;
    }
    if (mapHeight > viewH) {
      final halfH = viewH / 2;
      pos.y = pos.y.clamp(halfH, mapHeight - halfH).toDouble();
    } else {
      pos.y = mapHeight / 2;
    }
    camera.viewfinder.position = pos;
  }
}
