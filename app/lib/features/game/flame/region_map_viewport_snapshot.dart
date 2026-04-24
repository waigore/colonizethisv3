/// Fit-relative zoom band vs [computeRegionMapFitMapZoom] (`z_fit`). SPEC/ui/map-widget.md.
const double kRegionMapZoomMultiplierMin = 0.5;
const double kRegionMapZoomMultiplierMax = 8.0;

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
    required this.fitMapZoom,
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

  /// Flame viewfinder zoom at which the full map fits the viewport (`z_fit`). SPEC/ui/map-widget.md.
  final double fitMapZoom;

  final double viewportWidthLogical;
  final double viewportHeightLogical;

  /// Fit-relative multiplier `m = zoom / fitMapZoom` (100% = fit entire map).
  double get zoomMultiplier => fitMapZoom > 0 ? zoom / fitMapZoom : 1.0;

  /// Visible world width at current zoom (matches [CtRegionMapGame] / map-widget math).
  double get viewWidthWorld => viewportWidthLogical / zoom;

  /// Visible world height at current zoom.
  double get viewHeightWorld => viewportHeightLogical / zoom;

  static bool _e(double a, double b) => (a - b).abs() < 1.0;

  /// Zoom and fit baseline must use a tight epsilon: a 1.0 absolute tolerance on
  /// [zoom] incorrectly treated distinct camera zooms as equal and suppressed
  /// minimap/shell updates during small slider steps (see region minimap zoom).
  static bool _eZoom(double a, double b) => (a - b).abs() < 1e-5;

  /// True when [other] represents the same viewport (avoids redundant Riverpod writes).
  bool matches(RegionMapViewportSnapshot other) {
    return regionId == other.regionId &&
        _e(cellSizePx, other.cellSizePx) &&
        _e(mapWidthWorld, other.mapWidthWorld) &&
        _e(mapHeightWorld, other.mapHeightWorld) &&
        _e(cameraCenterX, other.cameraCenterX) &&
        _e(cameraCenterY, other.cameraCenterY) &&
        _eZoom(zoom, other.zoom) &&
        _eZoom(fitMapZoom, other.fitMapZoom) &&
        _e(viewportWidthLogical, other.viewportWidthLogical) &&
        _e(viewportHeightLogical, other.viewportHeightLogical);
  }
}

/// `z_fit` = min(vw/mapW, vh/mapH) in Flame zoom units (entire map visible at this zoom).
double computeRegionMapFitMapZoom({
  required double viewportWidthLogical,
  required double viewportHeightLogical,
  required double mapWidthWorld,
  required double mapHeightWorld,
}) {
  if (mapWidthWorld <= 0 ||
      mapHeightWorld <= 0 ||
      viewportWidthLogical <= 0 ||
      viewportHeightLogical <= 0) {
    return 1.0;
  }
  final zx = viewportWidthLogical / mapWidthWorld;
  final zy = viewportHeightLogical / mapHeightWorld;
  final z = zx < zy ? zx : zy;
  if (!z.isFinite || z <= 0) {
    return 1.0;
  }
  return z;
}
