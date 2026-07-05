import 'dart:ui' show Offset, Rect, Size;

import '../region_map/region_map_viewport_snapshot.dart';

/// Top-left corner of the main-map viewport rectangle on the minimap (logical px).
Offset minimapViewportTopLeft({
  required RegionMapViewportSnapshot viewport,
  required Size minimapSize,
  required double mapWidthWorld,
  required double mapHeightWorld,
}) {
  final scaleX = minimapSize.width / mapWidthWorld;
  final scaleY = minimapSize.height / mapHeightWorld;
  final vw = viewport.viewWidthWorld * scaleX;
  final vh = viewport.viewHeightWorld * scaleY;
  final left = viewport.cameraCenterX * scaleX - vw / 2;
  final top = viewport.cameraCenterY * scaleY - vh / 2;
  return Offset(left, top);
}

/// Size of the viewport indicator on the minimap (logical px).
Size minimapViewportIndicatorSize({
  required RegionMapViewportSnapshot viewport,
  required Size minimapSize,
  required double mapWidthWorld,
  required double mapHeightWorld,
}) {
  final scaleX = minimapSize.width / mapWidthWorld;
  final scaleY = minimapSize.height / mapHeightWorld;
  return Size(
    viewport.viewWidthWorld * scaleX,
    viewport.viewHeightWorld * scaleY,
  );
}

/// World-space center under a local minimap point (top-left origin).
Offset minimapLocalToWorldCenter({
  required Offset localOnMinimap,
  required Size minimapSize,
  required double mapWidthWorld,
  required double mapHeightWorld,
}) {
  final sx = mapWidthWorld / minimapSize.width;
  final sy = mapHeightWorld / minimapSize.height;
  return Offset(localOnMinimap.dx * sx, localOnMinimap.dy * sy);
}

/// World-space delta for a minimap drag delta (same direction as finger on minimap).
Offset minimapDeltaToWorldDelta({
  required Offset minimapDelta,
  required Size minimapSize,
  required double mapWidthWorld,
  required double mapHeightWorld,
}) {
  final sx = mapWidthWorld / minimapSize.width;
  final sy = mapHeightWorld / minimapSize.height;
  return Offset(minimapDelta.dx * sx, minimapDelta.dy * sy);
}

/// Viewport indicator rect; optionally enforces a minimum size in minimap pixels (nice-to-have).
Rect minimapViewportIndicatorRect({
  required RegionMapViewportSnapshot viewport,
  required Size minimapSize,
  required double mapWidthWorld,
  required double mapHeightWorld,
  double minMinimapSpan = 6,
}) {
  final topLeft = minimapViewportTopLeft(
    viewport: viewport,
    minimapSize: minimapSize,
    mapWidthWorld: mapWidthWorld,
    mapHeightWorld: mapHeightWorld,
  );
  var size = minimapViewportIndicatorSize(
    viewport: viewport,
    minimapSize: minimapSize,
    mapWidthWorld: mapWidthWorld,
    mapHeightWorld: mapHeightWorld,
  );
  if (size.width < minMinimapSpan || size.height < minMinimapSpan) {
    final cx = topLeft.dx + size.width / 2;
    final cy = topLeft.dy + size.height / 2;
    size = Size(
      size.width < minMinimapSpan ? minMinimapSpan : size.width,
      size.height < minMinimapSpan ? minMinimapSpan : size.height,
    );
    return Rect.fromCenter(center: Offset(cx, cy), width: size.width, height: size.height);
  }
  return topLeft & size;
}
