// Game world state map visualization from InitGameMapViewData.
// SPEC/program/map-visualization.md § Game world state map visualizer.

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:image/image.dart' as img;

import '../tile_map_grid.dart';
import '../view/init_game_map_view_data.dart';
import 'multi_region_map_rendering.dart';
import 'tile_map_resource_legend.dart' show drawResourceLetterAtCellCenter;
import 'tile_map_visualization.dart';
import 'tile_map_visualization_cell_fill.dart'
    show drawBorders, fillRegionViewCells;
import 'tile_map_visualization_legend_layout.dart'
    show
        ResourceLegendRowsStyle,
        drawLegendLine,
        drawPortsLegendLine,
        kGameWorldMapOwnershipLegendBlurb,
        legendHeightForLineCount,
        legendLineHeight,
        legendPadding;
import 'tile_map_visualization_png_markers.dart'
    show drawCapitalMarkersOnImage, drawPortMarkersOnImage;
import 'tile_map_visualization_shared.dart'
    show
        drawResourceLegendRows,
        geographicGameWorldLegendResources,
        geographicGameWorldResourceGlyphs,
        seaZoneLocalIdsFromRegionCells;

/// Resolves terrain RGB for a cell (geographic fill). Uses terrainType or parses terrainTypeId.
(int r, int g, int b) terrainRgbForCell(
  CellViewData cell,
  RegionMapViewData region,
) {
  final terrain =
      cell.terrainType ??
      (cell.terrainTypeId != null
          ? TerrainType.values.byName(cell.terrainTypeId!)
          : null);
  if (terrain == null) return (128, 128, 128);
  final rgb = region.terrainColors[terrain];
  return rgb ?? (128, 128, 128);
}

/// Renders the combined Old World + New World map from InitGameMapViewData.
/// When [geographicMode] is true, land is filled by terrain and resource glyphs (g/t/i) are drawn; legend lists terrain and resources. When false, ownership fill only.
Uint8List renderInitGameMapToPngFromViewData({
  required InitGameMapViewData viewData,
  bool geographicMode = false,
}) {
  final ow = viewData.oldWorld;
  final nw = viewData.newWorld;

  Uint8List renderRegion(RegionMapViewData region) {
    final mapW = region.width * region.cellSize;
    final mapH = region.height * region.cellSize;

    final seaZoneIds = seaZoneLocalIdsFromRegionCells(region.cells);

    // Legend height: geographic = title + Sea + terrains + "Resources:" + g/t/i + ports; else title + factions + ports.
    final legendLines = geographicMode
        ? (1 +
              1 +
              region.terrainColors.length +
              1 +
              geographicGameWorldLegendResources.length +
              (region.portMarkers.isNotEmpty ? 1 : 0))
        : (2 +
              region.factionColors.length +
              (region.portMarkers.isNotEmpty ? 1 : 0));
    final legendHeight = legendHeightForLineCount(legendLines);

    final image = img.Image(width: mapW, height: mapH + legendHeight);
    final white = image.getColor(255, 255, 255);
    final black = image.getColor(0, 0, 0);
    final seaZoneBorderColor = image.getColor(
      seaZoneBorderRgb.$1,
      seaZoneBorderRgb.$2,
      seaZoneBorderRgb.$3,
    );
    image.clear(white);

    // Fill: by terrain (geographic) or by ownership. Shares the canonical
    // cell-fill render pipeline (fillRegionViewCells); political vs geographic
    // differ only by this colour strategy (Refs #3574).
    fillRegionViewCells(
      image,
      cells: region.cells,
      cellSize: region.cellSize,
      colorAt: (cell) {
        if (cell.isSea) return seaColorRgb;
        return geographicMode
            ? terrainRgbForCell(cell, region)
            : (region.factionColors[cell.ownerFactionId ?? ''] ??
                  (128, 128, 128));
      },
    );

    // Reconstruct a minimal TileMapResult-like structure for border drawing.
    final tmpResult = TileMapResult(
      width: region.width,
      height: region.height,
      grid: TileMapGrid.generate(
        region.height,
        region.width,
        (y, x) => region.cellAt(x, y).regionCellId,
      ),
    );
    drawBorders(
      image,
      tmpResult,
      seaZoneIds,
      region.cellSize,
      seaZoneBorderColor,
    );

    // Resource glyphs (geographic mode): g/t/i only per SPEC/program/map-visualization.md § Geographic legend scope.
    if (geographicMode) {
      for (final glyph in geographicGameWorldResourceGlyphs(region.cells)) {
        drawResourceLetterAtCellCenter(
          image,
          letter: glyph.letter,
          cellX: glyph.x,
          cellY: glyph.y,
          cellSize: region.cellSize,
          color: black,
          offsetY: 6,
        );
      }
    }

    drawPortMarkersOnImage(
      image,
      region.portMarkers.map((p) => (x: p.x, y: p.y)),
      region.cellSize,
    );
    drawCapitalMarkersOnImage(
      image,
      region.capitalMarkers.map((c) => (x: c.x, y: c.y)),
      region.cellSize,
    );

    // Legend.
    var legendY = mapH + legendPadding;
    if (geographicMode) {
      img.drawString(
        image,
        'Terrain. Black = land borders; light blue = sea borders.',
        font: img.arial14,
        x: legendPadding,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
      legendY = drawLegendLine(
        image,
        legendY,
        seaColorRgb.$1,
        seaColorRgb.$2,
        seaColorRgb.$3,
        'Sea',
      );
      for (final entry in region.terrainColors.entries) {
        legendY = drawLegendLine(
          image,
          legendY,
          entry.value.$1,
          entry.value.$2,
          entry.value.$3,
          entry.key.name,
        );
      }
      img.drawString(
        image,
        'Resources:',
        font: img.arial14,
        x: legendPadding,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
      legendY = drawResourceLegendRows(
        image,
        legendY: legendY,
        textColor: black,
        resources: geographicGameWorldLegendResources,
        style: ResourceLegendRowsStyle.compactInline,
      );
    } else {
      img.drawString(
        image,
        kGameWorldMapOwnershipLegendBlurb,
        font: img.arial14,
        x: legendPadding,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
      for (final entry in region.factionColors.entries) {
        legendY = drawLegendLine(
          image,
          legendY,
          entry.value.$1,
          entry.value.$2,
          entry.value.$3,
          entry.key,
        );
      }
    }
    if (region.portMarkers.isNotEmpty) {
      legendY = drawPortsLegendLine(image, legendY);
    }

    return img.encodePng(image);
  }

  final owPng = renderRegion(ow);
  final nwPng = renderRegion(nw);

  return composeMultiRegionMapPng(oldWorldPng: owPng, newWorldPng: nwPng);
}
