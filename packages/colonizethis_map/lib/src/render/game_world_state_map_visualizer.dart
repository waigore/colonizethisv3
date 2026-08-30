// SPEC/program/map-visualization.md § Game world state map visualizer.

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:image/image.dart' as img;

import '../map_region_dispatch.dart';
import '../region_constants.dart';
import '../tile_key_util.dart';
import '../tile_map_topology_helpers.dart';
import '../view/region_map_view_inputs.dart';
import 'multi_region_map_rendering.dart';
import 'tile_map_visualization.dart';
import 'tile_map_visualization_cell_fill.dart'
    show drawBorders, fillTileGridCells;
import 'tile_map_visualization_legend_layout.dart'
    show
        drawLegendLine,
        drawPortsLegendLine,
        kGameWorldMapOwnershipLegendBlurb,
        legendHeightForLineCount,
        legendLineHeight,
        legendPadding,
        swatchGap,
        swatchSize;
import 'tile_map_visualization_png_markers.dart'
    show capitalMarkerRgb, drawCapitalMarkersOnImage, drawPortMarkersOnImage;
import 'tile_map_visualization_shared.dart' show colorMapFromIds;

export 'game_world_state_map_visualizer_from_view_data.dart';

void _appendPortTileToRegionLists(
  String tileKey,
  List<({int x, int y})> owPortTiles,
  List<({int x, int y})> nwPortTiles,
) {
  final parsed = tryParseMapTileKey(tileKey);
  if (parsed == null) return;
  final bucket = selectByMapRegionIdOrNull<List<({int x, int y})>>(
    parsed.regionId,
    oldWorld: () => owPortTiles,
    newWorld: () => nwPortTiles,
  );
  bucket?.add((x: parsed.x, y: parsed.y));
}

/// Single-region ownership PNG. SPEC/program/map-visualization.md.
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
  final legendHeight = legendHeightForLineCount(legendLines);
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

  fillTileGridCells(
    image,
    height: result.height,
    width: result.width,
    cellSize: cellSize,
    colorAt: (x, y) {
      final id = result.cell(x, y);
      final isSea = seaZoneIds.contains(id);
      if (isSea) return seaColorRgb;
      final fullProvinceId = ProvinceId.full(regionId, id);
      return factionColors[ownerByProvinceId[fullProvinceId] ?? ''] ??
          (128, 128, 128);
    },
  );

  drawBorders(image, result, seaZoneIds, cellSize, seaZoneBorderColor);

  drawPortMarkersOnImage(image, portTiles, cellSize);
  drawCapitalMarkersOnImage(
    image,
    capitalTiles.map((c) => (x: c.x, y: c.y)),
    cellSize,
  );

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

/// Combined OW+NW ownership map. SPEC/program/map-visualization.md.
Uint8List renderInitGameMapToPng({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  int cellSize = 24,
}) {
  final owInputs = regionMapRenderInputs(game: game, regionId: kRegionOldWorld);
  final nwInputs = regionMapRenderInputs(game: game, regionId: kRegionNewWorld);

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
