// Optional legend sections (continent seeds, land seeds, resources).
// SPEC/program/map-visualization.md § Tile map PNG export.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_colors.dart' show regionPalette;
import 'tile_map_visualization_legend_layout.dart'
    show
        drawLegendContinentSeedMarker,
        drawLegendLandSeedMarker,
        drawLegendLine,
        drawResourceLegendRows,
        legendLineHeight,
        legendPadding,
        swatchGap,
        swatchSize;

/// Legend rows after the fixed title + primary swatch block (Refs #2489 D7).
int optionalLegendSectionLineCount({
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  var rows = 0;
  if (showContinentSeeds) {
    rows++;
  }
  if (showLandSeeds) {
    if (useLandSeedByContinent && landSeedContinentIndices != null) {
      final maxContinent = landSeedContinentIndices.reduce(
        (a, b) => a > b ? a : b,
      );
      rows += maxContinent + 1;
    } else {
      rows++;
    }
  }
  if (hasResourceGrid) {
    rows += Resource.values.length;
  }
  return rows;
}

/// Draws optional legend sections (continent seeds, land seeds, resources).
int drawOptionalLegendSections(
  img.Image image,
  int legendY0,
  int row, {
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  final black = image.getColor(0, 0, 0);
  if (showContinentSeeds) {
    final y = legendY0 + row * legendLineHeight;
    drawLegendContinentSeedMarker(image, y);
    img.drawString(
      image,
      'Continent seeds (one per continent)',
      font: img.arial14,
      x: legendPadding + swatchSize + swatchGap,
      y: y,
      color: black,
    );
    row++;
  }
  if (showLandSeeds) {
    if (useLandSeedByContinent && landSeedContinentIndices != null) {
      final maxContinent = landSeedContinentIndices.reduce(
        (a, b) => a > b ? a : b,
      );
      for (var c = 0; c <= maxContinent; c++) {
        var y = legendY0 + row * legendLineHeight;
        final (r, g, b) = regionPalette[c % regionPalette.length];
        y = drawLegendLine(image, y, r, g, b, 'Continent $c');
        row = (y - legendY0) ~/ legendLineHeight;
      }
    } else {
      final y = legendY0 + row * legendLineHeight;
      drawLegendLandSeedMarker(image, y);
      img.drawString(
        image,
        'Land seeds (cluster per continent)',
        font: img.arial14,
        x: legendPadding + swatchSize + swatchGap,
        y: y,
        color: black,
      );
      row++;
    }
  }
  if (hasResourceGrid) {
    final yAfter = drawResourceLegendRows(
      image,
      legendY: legendY0 + row * legendLineHeight,
      textColor: black,
      resources: Resource.values,
    );
    row += (yAfter - (legendY0 + row * legendLineHeight)) ~/ legendLineHeight;
  }
  return row;
}

/// Shared trailer for terrain and region legends after primary swatches.
void drawLegendOptionalSectionsTrailer({
  required img.Image image,
  required int legendY0,
  required int rowAfterPrimary,
  required bool showContinentSeeds,
  required bool showLandSeeds,
  required bool useLandSeedByContinent,
  required List<int>? landSeedContinentIndices,
  required bool hasResourceGrid,
}) {
  drawOptionalLegendSections(
    image,
    legendY0,
    rowAfterPrimary,
    showContinentSeeds: showContinentSeeds,
    showLandSeeds: showLandSeeds,
    useLandSeedByContinent: useLandSeedByContinent,
    landSeedContinentIndices: landSeedContinentIndices,
    hasResourceGrid: hasResourceGrid,
  );
}
