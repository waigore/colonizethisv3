part of 'ct_region_map_game.dart';

extension _CtRegionMapGameCamera on CtRegionMapGame {
  void _syncCameraZoomFromMultiplier() {
    if (!_mapLoaded || size == Vector2.zero()) return;
    _zoomMultiplier = _zoomMultiplier.clamp(
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
    camera.viewfinder.zoom = _zoomMultiplier * zFit;
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  void _emitViewportSnapshot() {
    final cb = onViewportSnapshotChanged;
    if (cb == null) return;
    if (!_mapLoaded || size == Vector2.zero()) return;
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

  void _handleGameResize(Vector2 size, Vector2? previousSize) {
    if (!_mapLoaded) {
      return;
    }

    if (previousSize == null || previousSize == Vector2.zero()) {
      _syncCameraZoomFromMultiplier();
      return;
    }

    final oldZoom = camera.viewfinder.zoom;
    if (oldZoom <= 0 || !oldZoom.isFinite) {
      _syncCameraZoomFromMultiplier();
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
    _zoomMultiplier = _zoomMultiplier.clamp(
      kRegionMapZoomMultiplierMin,
      kRegionMapZoomMultiplierMax,
    );
    final newZoom = _zoomMultiplier * newZFit;

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
        final desired = center.x + (oldViewW - newViewW) / 2;
        center.x = desired.clamp(minX, maxX).toDouble();
      } else {
        center.x = center.x.clamp(minX, maxX).toDouble();
      }
    }

    if (newViewH != oldViewH && mapHeight > newViewH) {
      final halfNewH = newViewH / 2;
      final minY = halfNewH;
      final maxY = mapHeight - halfNewH;
      if (newViewH > oldViewH) {
        final desired = center.y + (oldViewH - newViewH) / 2;
        center.y = desired.clamp(minY, maxY).toDouble();
      } else {
        center.y = center.y.clamp(minY, maxY).toDouble();
      }
    }

    camera.viewfinder.position = center;
    camera.viewfinder.zoom = newZoom;
    _clampCameraToMap();
    onRegionViewChanged?.call();
    _emitViewportSnapshot();
  }

  void _clampCameraToMap() {
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
      final minX = halfW;
      final maxX = mapWidth - halfW;
      pos.x = pos.x.clamp(minX, maxX).toDouble();
    } else {
      pos.x = mapWidth / 2;
    }
    if (mapHeight > viewH) {
      final halfH = viewH / 2;
      final minY = halfH;
      final maxY = mapHeight - halfH;
      pos.y = pos.y.clamp(minY, maxY).toDouble();
    } else {
      pos.y = mapHeight / 2;
    }

    camera.viewfinder.position = pos;
  }
}
