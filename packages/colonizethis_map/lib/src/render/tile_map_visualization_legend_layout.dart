// Legend layout constants and primitive row drawing for PNG export.
// SPEC/program/map-visualization.md § Legend layout abstraction.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_colors.dart';
import 'tile_map_resource_legend.dart';

/// Legend layout constants. Shared by base and game-state visualizers.
const int legendPadding = 12;
const int legendLineHeight = 20;
const int swatchSize = 14;
const int swatchGap = 8;

/// Title line for PNG game-world ownership overlays (combined and view-data paths).
/// SPEC/program/map-visualization.md § Game world state map visualizer.
const String kGameWorldMapOwnershipLegendBlurb =
    'Ownership by faction. Black = land borders; light blue = sea borders.';

/// Total legend band height for [legendLines] content rows below the map.
///
/// Single source of truth for `legendPadding * 2 + legendLines * legendLineHeight`
/// (Refs #4112 wave-4 legend dedup).
int legendHeightForLineCount(int legendLines) =>
    legendPadding * 2 + legendLines * legendLineHeight;

/// Draws a color swatch in the legend at row y.
void drawLegendSwatch(img.Image image, int y, int r, int g, int b) {
  final color = image.getColor(r, g, b);
  img.fillRect(
    image,
    x1: legendPadding,
    y1: y,
    x2: legendPadding + swatchSize,
    y2: y + swatchSize,
    color: color,
  );
}

/// Draws a continent seed marker in the legend (larger circle).
void drawLegendContinentSeedMarker(img.Image image, int y) {
  final cx = legendPadding + swatchSize ~/ 2;
  final cy = y + swatchSize ~/ 2;
  final fillColor = image.getColor(
    continentSeedMarkerRgb.$1,
    continentSeedMarkerRgb.$2,
    continentSeedMarkerRgb.$3,
  );
  final black = image.getColor(0, 0, 0);
  img.fillCircle(image, x: cx, y: cy, radius: 5, color: fillColor);
  img.drawCircle(image, x: cx, y: cy, radius: 5, color: black);
}

/// Draws a land seed marker in the legend (smaller circle).
void drawLegendLandSeedMarker(img.Image image, int y) {
  final cx = legendPadding + swatchSize ~/ 2;
  final cy = y + swatchSize ~/ 2;
  final black = image.getColor(0, 0, 0);
  final color = image.getColor(
    landSeedMarkerRgb.$1,
    landSeedMarkerRgb.$2,
    landSeedMarkerRgb.$3,
  );
  img.fillCircle(image, x: cx, y: cy, radius: 4, color: color);
  img.drawCircle(image, x: cx, y: cy, radius: 4, color: black);
}

/// Draws one legend line: swatch (r,g,b) + label at [y]. Returns y + legendLineHeight.
int drawLegendLine(img.Image image, int y, int r, int g, int b, String label) {
  drawLegendSwatch(image, y, r, g, b);
  final black = image.getColor(0, 0, 0);
  img.drawString(
    image,
    label,
    font: img.arial14,
    x: legendPadding + swatchSize + swatchGap,
    y: y,
    color: black,
  );
  return y + legendLineHeight;
}

/// Layout variant for [drawResourceLegendRows] (Refs #2489 D7/D9 legend dedup).
enum ResourceLegendRowsStyle {
  /// `"<letter>  <label>"` at [legendPadding] (game-world geographic PNG).
  compactInline,

  /// Letter at [legendPadding]; label column aligned with color-swatch legends.
  tileMapColumns,
}

/// Draws resource legend rows. Returns y after the last row.
int drawResourceLegendRows(
  img.Image image, {
  required int legendY,
  required img.Color textColor,
  required Iterable<Resource> resources,
  ResourceLegendRowsStyle style = ResourceLegendRowsStyle.tileMapColumns,
}) {
  var y = legendY;
  for (final r in resources) {
    final letter = resourceToLegendLetter(r);
    final label = resourceToLegendLabel(r);
    switch (style) {
      case ResourceLegendRowsStyle.compactInline:
        img.drawString(
          image,
          '$letter  $label',
          font: img.arial14,
          x: legendPadding,
          y: y,
          color: textColor,
        );
      case ResourceLegendRowsStyle.tileMapColumns:
        img.drawString(
          image,
          letter,
          font: img.arial14,
          x: legendPadding,
          y: y,
          color: textColor,
        );
        img.drawString(
          image,
          '  $label',
          font: img.arial14,
          x: legendPadding + swatchSize + swatchGap,
          y: y,
          color: textColor,
        );
    }
    y += legendLineHeight;
  }
  return y;
}

/// Draws the "Ports marked with teal square." legend line at [y]. Returns y + legendLineHeight.
int drawPortsLegendLine(img.Image image, int y) {
  final black = image.getColor(0, 0, 0);
  img.drawString(
    image,
    'Ports marked with teal square.',
    font: img.arial14,
    x: legendPadding,
    y: y,
    color: black,
  );
  return y + legendLineHeight;
}
