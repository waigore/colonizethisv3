// Game world state map visualization: ownership overlay and capital markers.
// SPEC/program/map-visualization.md § Game world state map visualizer.

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'region_map_view_inputs.dart';
import 'tile_map_grid.dart';
import 'tile_map_topology_helpers.dart';
import 'tile_map_visualization.dart';
import 'tile_map_visualization_shared.dart';
import 'multi_region_map_rendering.dart';
import 'init_game_map_view_data.dart';
import 'region_constants.dart';
import 'tile_key_util.dart';

void _appendPortTileToRegionLists(
  String tileKey,
  List<({int x, int y})> owPortTiles,
  List<({int x, int y})> nwPortTiles,
) {
  final parsed = tryParseMapTileKey(tileKey);
  if (parsed == null) return;
  if (parsed.regionId == kRegionOldWorld) {
    owPortTiles.add((x: parsed.x, y: parsed.y));
    return;
  }
  if (parsed.regionId == kRegionNewWorld) {
    nwPortTiles.add((x: parsed.x, y: parsed.y));
  }
}

/// Resolves terrain RGB for a cell (geographic fill). Uses terrainType or parses terrainTypeId.
(int r, int g, int b) _terrainRgbForCell(
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

/// Renders a single region (OW or NW) with ownership and capitals to PNG bytes.
/// Used by renderInitGameMapToPng to render each region before composition.
Uint8List renderSingleRegionGameStateMapToPng({
  required TileMapResult result,
  required MapTopology topology,
  required String regionId,
  required Map<String, String> ownerByProvinceId,
  required List<({String factionId, String displayName, int x, int y})>
  capitalTiles,
  int cellSize = 24,
  Map<String, (int r, int g, int b)>? factionColorsOverride,
  List<({int x, int y})> portTiles = const [],
}) {
  final seaZoneIds = seaZoneIdsFromTopology(topology);

  final List<String> factionIds;
  final Map<String, (int r, int g, int b)> factionColors;
  if (factionColorsOverride != null && factionColorsOverride.isNotEmpty) {
    factionColors = factionColorsOverride;
    factionIds = factionColorsOverride.keys.toList();
  } else {
    factionIds = ownerByProvinceId.values.toSet().toList()..sort();
    factionColors = colorMapFromIds(factionIds);
  }

  final mapW = result.width * cellSize;
  final mapH = result.height * cellSize;

  const titleLines = 2;
  var legendLines = titleLines + 1 + factionIds.length;
  if (capitalTiles.isNotEmpty) legendLines += 1 + capitalTiles.length;
  if (portTiles.isNotEmpty) legendLines += 1;
  final legendHeight = legendPadding * 2 + legendLines * legendLineHeight;
  final totalWidth = mapW;
  final totalHeight = mapH + legendHeight;

  final image = img.Image(width: totalWidth, height: totalHeight);
  final white = image.getColor(255, 255, 255);
  final black = image.getColor(0, 0, 0);
  final seaZoneBorderColor = image.getColor(
    seaZoneBorderRgb.$1,
    seaZoneBorderRgb.$2,
    seaZoneBorderRgb.$3,
  );
  image.clear(white);

  // Fill: provinces by owner color, sea zones deep blue
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final id = result.cell(x, y);
      final isSea = seaZoneIds.contains(id);
      final fullProvinceId = isSea ? null : ProvinceId.full(regionId, id);
      final (r, g, b) = isSea
          ? seaColorRgb
          : (factionColors[ownerByProvinceId[fullProvinceId] ?? ''] ??
                (128, 128, 128));
      final color = image.getColor(r, g, b);
      img.fillRect(
        image,
        x1: x * cellSize,
        y1: y * cellSize,
        x2: (x + 1) * cellSize - 1,
        y2: (y + 1) * cellSize - 1,
        color: color,
      );
    }
  }

  drawBorders(image, result, seaZoneIds, cellSize, seaZoneBorderColor);

  drawPortMarkersOnImage(image, portTiles, cellSize);
  drawCapitalMarkersOnImage(
    image,
    capitalTiles.map((c) => (x: c.x, y: c.y)),
    cellSize,
  );

  // Legend
  final legendY0 = mapH + legendPadding;
  var legendY = legendY0;
  img.drawString(
    image,
    kGameWorldMapOwnershipLegendBlurb,
    font: img.arial14,
    x: legendPadding,
    y: legendY,
    color: black,
  );
  legendY += legendLineHeight;
  img.drawString(
    image,
    'Capitals marked with gold circle.',
    font: img.arial14,
    x: legendPadding,
    y: legendY,
    color: black,
  );
  legendY += legendLineHeight;
  if (portTiles.isNotEmpty) {
    legendY = drawPortsLegendLine(image, legendY);
  }
  for (final fid in factionIds) {
    final c = factionColors[fid]!;
    legendY = drawLegendLine(image, legendY, c.$1, c.$2, c.$3, fid);
  }
  if (capitalTiles.isNotEmpty) {
    const capitalRadius = 6;
    final capitalColor = image.getColor(
      capitalMarkerRgb.$1,
      capitalMarkerRgb.$2,
      capitalMarkerRgb.$3,
    );
    for (final cap in capitalTiles) {
      final cx = legendPadding + swatchSize ~/ 2;
      final cy = legendY + swatchSize ~/ 2;
      img.fillCircle(
        image,
        x: cx,
        y: cy,
        radius: capitalRadius - 1,
        color: capitalColor,
      );
      img.drawCircle(
        image,
        x: cx,
        y: cy,
        radius: capitalRadius - 1,
        color: black,
      );
      img.drawString(
        image,
        'Capital of ${cap.displayName}',
        font: img.arial14,
        x: legendPadding + swatchSize + swatchGap,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
    }
  }

  return img.encodePng(image);
}

/// Renders the combined Old World + New World map with ownership and capitals.
/// SPEC/program/map-visualization.md § Game world state map visualizer, Multi-region rendering.
Uint8List renderInitGameMapToPng({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  int cellSize = 24,
}) {
  final owInputs = regionMapRenderInputs(
    game: game,
    regionId: kRegionOldWorld,
  );
  final nwInputs = regionMapRenderInputs(
    game: game,
    regionId: kRegionNewWorld,
  );

  // Port tile positions from WorldState.portsByProvinceSeaboard (value = regionId|provinceId|x|y)
  final owPortTiles = <({int x, int y})>[];
  final nwPortTiles = <({int x, int y})>[];
  for (final tileKey in game.worldState.portsByProvinceSeaboard.values) {
    _appendPortTileToRegionLists(tileKey, owPortTiles, nwPortTiles);
  }

  final owResult = tileMapByRegion[kRegionOldWorld]!;
  final owTopo = topologyByRegion[kRegionOldWorld]!;
  final nwResult = tileMapByRegion[kRegionNewWorld]!;
  final nwTopo = topologyByRegion[kRegionNewWorld]!;

  final owPng = renderSingleRegionGameStateMapToPng(
    result: owResult,
    topology: owTopo,
    regionId: kRegionOldWorld,
    ownerByProvinceId: owInputs.ownerByProvinceId,
    capitalTiles: owInputs.capitalTiles,
    cellSize: cellSize,
    factionColorsOverride: owInputs.factionColors,
    portTiles: owPortTiles,
  );
  final nwPng = renderSingleRegionGameStateMapToPng(
    result: nwResult,
    topology: nwTopo,
    regionId: kRegionNewWorld,
    ownerByProvinceId: nwInputs.ownerByProvinceId,
    capitalTiles: nwInputs.capitalTiles,
    cellSize: cellSize,
    factionColorsOverride: nwInputs.factionColors,
    portTiles: nwPortTiles,
  );

  return composeMultiRegionMapPng(oldWorldPng: owPng, newWorldPng: nwPng);
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
    final legendHeight = legendPadding * 2 + legendLines * legendLineHeight;

    final image = img.Image(width: mapW, height: mapH + legendHeight);
    final white = image.getColor(255, 255, 255);
    final black = image.getColor(0, 0, 0);
    final seaZoneBorderColor = image.getColor(
      seaZoneBorderRgb.$1,
      seaZoneBorderRgb.$2,
      seaZoneBorderRgb.$3,
    );
    image.clear(white);

    // Fill: by terrain (geographic) or by ownership.
    for (final cell in region.cells) {
      final (r, g, b) = cell.isSea
          ? seaColorRgb
          : (geographicMode
                ? _terrainRgbForCell(cell, region)
                : (region.factionColors[cell.ownerFactionId ?? ''] ??
                      (128, 128, 128)));
      final color = image.getColor(r, g, b);
      img.fillRect(
        image,
        x1: cell.x * region.cellSize,
        y1: cell.y * region.cellSize,
        x2: (cell.x + 1) * region.cellSize - 1,
        y2: (cell.y + 1) * region.cellSize - 1,
        color: color,
      );
    }

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
