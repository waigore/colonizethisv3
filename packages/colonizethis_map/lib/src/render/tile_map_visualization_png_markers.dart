// On-map port/capital marker painting for PNG export.
// SPEC/program/map-visualization.md § Game world state map visualizer.

import 'package:image/image.dart' as img;

/// Capital marker color (gold), distinct from terrain. Used for drawing and legend.
const (int, int, int) capitalMarkerRgb = (255, 215, 0);

/// Port marker color (teal), distinct from capitals.
const (int, int, int) portMarkerRgb = (0, 100, 140);

/// Draws port markers (filled teal square with black outline) at cell centres.
/// Call after fill and borders, before capital markers.
void drawPortMarkersOnImage(
  img.Image image,
  Iterable<({int x, int y})> portTiles,
  int cellSize,
) {
  const portHalfSize = 4;
  final black = image.getColor(0, 0, 0);
  final portColor = image.getColor(
    portMarkerRgb.$1,
    portMarkerRgb.$2,
    portMarkerRgb.$3,
  );
  for (final pt in portTiles) {
    final cx = pt.x * cellSize + cellSize ~/ 2;
    final cy = pt.y * cellSize + cellSize ~/ 2;
    img.fillRect(
      image,
      x1: cx - portHalfSize,
      y1: cy - portHalfSize,
      x2: cx + portHalfSize,
      y2: cy + portHalfSize,
      color: portColor,
    );
    img.drawRect(
      image,
      x1: cx - portHalfSize,
      y1: cy - portHalfSize,
      x2: cx + portHalfSize,
      y2: cy + portHalfSize,
      color: black,
    );
  }
}

/// Draws capital markers (filled gold circle with black outline) at cell centres.
void drawCapitalMarkersOnImage(
  img.Image image,
  Iterable<({int x, int y})> positions,
  int cellSize,
) {
  const capitalRadius = 6;
  final black = image.getColor(0, 0, 0);
  final capitalColor = image.getColor(
    capitalMarkerRgb.$1,
    capitalMarkerRgb.$2,
    capitalMarkerRgb.$3,
  );
  for (final pos in positions) {
    final cx = pos.x * cellSize + cellSize ~/ 2;
    final cy = pos.y * cellSize + cellSize ~/ 2;
    img.fillCircle(
      image,
      x: cx,
      y: cy,
      radius: capitalRadius,
      color: capitalColor,
    );
    img.drawCircle(image, x: cx, y: cy, radius: capitalRadius, color: black);
  }
}
