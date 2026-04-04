/// Read-only viewport state for the in-game region map (Flame world space + zoom).
/// Published into Riverpod by the map host for the region minimap. SPEC/ui/empire-overview.md.
class RegionMapViewportSnapshot {
  const RegionMapViewportSnapshot({
    required this.regionId,
    required this.cellSizePx,
    required this.mapWidthWorld,
    required this.mapHeightWorld,
    required this.cameraCenterX,
    required this.cameraCenterY,
    required this.zoom,
    required this.viewportWidthLogical,
    required this.viewportHeightLogical,
  });

  final String regionId;
  final double cellSizePx;
  final double mapWidthWorld;
  final double mapHeightWorld;
  final double cameraCenterX;
  final double cameraCenterY;
  final double zoom;
  final double viewportWidthLogical;
  final double viewportHeightLogical;

  /// Visible world width at current zoom (matches `_CtRegionMapGame` / map-widget math).
  double get viewWidthWorld => viewportWidthLogical / zoom;

  /// Visible world height at current zoom.
  double get viewHeightWorld => viewportHeightLogical / zoom;

  static bool _e(double a, double b) => (a - b).abs() < 1.0;

  /// True when [other] represents the same viewport (avoids redundant Riverpod writes).
  bool matches(RegionMapViewportSnapshot other) {
    return regionId == other.regionId &&
        _e(cellSizePx, other.cellSizePx) &&
        _e(mapWidthWorld, other.mapWidthWorld) &&
        _e(mapHeightWorld, other.mapHeightWorld) &&
        _e(cameraCenterX, other.cameraCenterX) &&
        _e(cameraCenterY, other.cameraCenterY) &&
        _e(zoom, other.zoom) &&
        _e(viewportWidthLogical, other.viewportWidthLogical) &&
        _e(viewportHeightLogical, other.viewportHeightLogical);
  }
}
