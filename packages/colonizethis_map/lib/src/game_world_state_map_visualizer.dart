// Game world state map visualization: ownership overlay and capital markers.
// SPEC/program/map-data.md § Game world state map visualizer.

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'tile_map_visualization.dart';
import 'tile_map_visualization_shared.dart';
import 'multi_region_map_rendering.dart';
import 'init_game_map_view_data.dart';

const String _regionOldWorld = 'oldWorld';
const String _regionNewWorld = 'newWorld';

/// Capital marker color (gold/yellow, distinct from terrain).
const (int, int, int) capitalMarkerRgb = (255, 215, 0);

/// Resolves terrain RGB for a cell (geographic fill). Uses terrainType or parses terrainTypeId.
(int r, int g, int b) _terrainRgbForCell(
  CellViewData cell,
  RegionMapViewData region,
) {
  final terrain = cell.terrainType ??
      (cell.terrainTypeId != null
          ? TerrainType.values.byName(cell.terrainTypeId!)
          : null);
  if (terrain == null) return (128, 128, 128);
  final rgb = region.terrainColors[terrain];
  return rgb ?? (128, 128, 128);
}

/// Port marker color (teal, distinct from capitals).
const (int, int, int) portMarkerRgb = (0, 100, 140);

/// Renders a single region (OW or NW) with ownership and capitals to PNG bytes.
/// Used by renderInitGameMapToPng to render each region before composition.
Uint8List renderSingleRegionGameStateMapToPng({
  required TileMapResult result,
  required MapTopology topology,
  required Map<String, String> ownerByProvinceId,
  required List<({String factionId, String displayName, int x, int y})> capitalTiles,
  int cellSize = 24,
  Map<String, (int r, int g, int b)>? factionColorsOverride,
  List<({int x, int y})> portTiles = const [],
}) {
  final seaZoneIds = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone) n.id
  };

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
      final (r, g, b) = seaZoneIds.contains(id)
          ? seaColorRgb
          : (factionColors[ownerByProvinceId[id] ?? ''] ?? (128, 128, 128));
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

  // Port markers (filled square, teal, black outline) — drawn before capitals so capital on same tile stays on top
  const portHalfSize = 4;
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

  // Capital markers (filled circle, gold, black outline)
  const capitalRadius = 6;
  final capitalColor = image.getColor(
    capitalMarkerRgb.$1,
    capitalMarkerRgb.$2,
    capitalMarkerRgb.$3,
  );
  for (final cap in capitalTiles) {
    final cx = cap.x * cellSize + cellSize ~/ 2;
    final cy = cap.y * cellSize + cellSize ~/ 2;
    img.fillCircle(image, x: cx, y: cy, radius: capitalRadius, color: capitalColor);
    img.drawCircle(image, x: cx, y: cy, radius: capitalRadius, color: black);
  }

  // Legend
  final legendY0 = mapH + legendPadding;
  img.drawString(
    image,
    'Ownership by faction. Black = land borders; light blue = sea borders.',
    font: img.arial14,
    x: legendPadding,
    y: legendY0,
    color: black,
  );
  img.drawString(
    image,
    'Capitals marked with gold circle.',
    font: img.arial14,
    x: legendPadding,
    y: legendY0 + legendLineHeight,
    color: black,
  );
  if (portTiles.isNotEmpty) {
    img.drawString(
      image,
      'Ports marked with teal square.',
      font: img.arial14,
      x: legendPadding,
      y: legendY0 + 2 * legendLineHeight,
      color: black,
    );
  }
  var row = titleLines + (portTiles.isNotEmpty ? 1 : 0);
  for (final fid in factionIds) {
    final y = legendY0 + row * legendLineHeight;
    final c = factionColors[fid]!;
    drawLegendSwatch(image, y, c.$1, c.$2, c.$3);
    img.drawString(
      image,
      fid,
      font: img.arial14,
      x: legendPadding + swatchSize + swatchGap,
      y: y,
      color: black,
    );
    row++;
  }
  if (capitalTiles.isNotEmpty) {
    row++;
    for (final cap in capitalTiles) {
      final y = legendY0 + row * legendLineHeight;
      final cx = legendPadding + swatchSize ~/ 2;
      final cy = y + swatchSize ~/ 2;
      img.fillCircle(
        image,
        x: cx,
        y: cy,
        radius: capitalRadius - 1,
        color: capitalColor,
      );
      img.drawCircle(image, x: cx, y: cy, radius: capitalRadius - 1, color: black);
      img.drawString(
        image,
        'Capital of ${cap.displayName}',
        font: img.arial14,
        x: legendPadding + swatchSize + swatchGap,
        y: y,
        color: black,
      );
      row++;
    }
  }

  return img.encodePng(image);
}

/// Renders the combined Old World + New World map with ownership and capitals.
/// SPEC/program/map-data.md § Game world state map visualizer, Multi-region rendering.
Uint8List renderInitGameMapToPng({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  int cellSize = 24,
}) {
  final owOwnerByProvinceId = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      owOwnerByProvinceId[p.id] = p.ownerId!;
    }
  }
  final nwOwnerByProvinceId = <String, String>{};
  for (final p in game.worldState.newWorld.provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      nwOwnerByProvinceId[p.id] = p.ownerId!;
    }
  }

  final owCapitals = <({String factionId, String displayName, int x, int y})>[];
  for (final p in game.players) {
    final cap = p.capitalTile;
    if (cap != null && cap.regionId == _regionOldWorld) {
      owCapitals.add((
        factionId: p.id,
        displayName: p.displayName,
        x: cap.x,
        y: cap.y,
      ));
    }
  }
  for (final m in game.minorNations) {
    final cap = m.capitalTile;
    if (cap != null && cap.regionId == _regionOldWorld) {
      owCapitals.add((
        factionId: m.id,
        displayName: m.displayName ?? m.id,
        x: cap.x,
        y: cap.y,
      ));
    }
  }
  final nwCapitals = <({String factionId, String displayName, int x, int y})>[];
  for (final t in game.tribes) {
    final cap = t.capitalTile;
    if (cap != null && cap.regionId == _regionNewWorld) {
      nwCapitals.add((
        factionId: t.id,
        displayName: t.displayName ?? t.id,
        x: cap.x,
        y: cap.y,
      ));
    }
  }

  // Ownership colours by faction type (GP vibrant, minors grey, tribes vibrant)
  final owGreatPowerIds = game.players.map((p) => p.id).toList()..sort();
  final owMinorNationIds = game.minorNations.map((m) => m.id).toList()..sort();
  final owFactionColors = factionOwnershipColorMap(
    greatPowerIds: owGreatPowerIds,
    minorNationIds: owMinorNationIds,
  );
  final nwTribeIds = game.tribes.map((t) => t.id).toList()..sort();
  final nwFactionColors = factionOwnershipColorMap(tribeIds: nwTribeIds);

  // Port tile positions from WorldState.portsByProvinceSeaboard (value = regionId|provinceId|x|y)
  final owPortTiles = <({int x, int y})>[];
  final nwPortTiles = <({int x, int y})>[];
  for (final tileKey in game.worldState.portsByProvinceSeaboard.values) {
    final parts = tileKey.split('|');
    if (parts.length >= 4) {
      final regionId = parts[0];
      final x = int.tryParse(parts[2]);
      final y = int.tryParse(parts[3]);
      if (x != null && y != null) {
        if (regionId == _regionOldWorld) {
          owPortTiles.add((x: x, y: y));
        } else if (regionId == _regionNewWorld) {
          nwPortTiles.add((x: x, y: y));
        }
      }
    }
  }

  final owResult = tileMapByRegion[_regionOldWorld]!;
  final owTopo = topologyByRegion[_regionOldWorld]!;
  final nwResult = tileMapByRegion[_regionNewWorld]!;
  final nwTopo = topologyByRegion[_regionNewWorld]!;

  final owPng = renderSingleRegionGameStateMapToPng(
    result: owResult,
    topology: owTopo,
    ownerByProvinceId: owOwnerByProvinceId,
    capitalTiles: owCapitals,
    cellSize: cellSize,
    factionColorsOverride: owFactionColors,
    portTiles: owPortTiles,
  );
  final nwPng = renderSingleRegionGameStateMapToPng(
    result: nwResult,
    topology: nwTopo,
    ownerByProvinceId: nwOwnerByProvinceId,
    capitalTiles: nwCapitals,
    cellSize: cellSize,
    factionColorsOverride: nwFactionColors,
    portTiles: nwPortTiles,
  );

  return composeMultiRegionMapPng(
    oldWorldPng: owPng,
    newWorldPng: nwPng,
  );
}

/// Renders the combined Old World + New World map from InitGameMapViewData.
/// When [geographicMode] is true, land is filled by terrain and resource glyphs (g/t/i) are drawn; legend lists terrain and resources. When false, ownership fill only.
Uint8List renderInitGameMapToPngFromViewData({
  required InitGameMapViewData viewData,
  bool geographicMode = false,
}) {
  final ow = viewData.oldWorld;
  final nw = viewData.newWorld;

  Uint8List _renderRegion(RegionMapViewData region) {
    final mapW = region.width * region.cellSize;
    final mapH = region.height * region.cellSize;

    // Determine sea zone ids from cells marked as sea.
    final seaZoneIds = <String>{};
    for (final cell in region.cells) {
      if (cell.isSea) {
        seaZoneIds.add(cell.regionCellId);
      }
    }

    // Legend height: geographic = title + Sea + terrains + "Resources:" + g/t/i + ports; else title + factions + ports.
    final legendLines = geographicMode
        ? (1 + 1 + region.terrainColors.length + 1 + 3 +
            (region.portMarkers.isNotEmpty ? 1 : 0))
        : (2 + region.factionColors.length +
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
      grid: List.generate(
        region.height,
        (y) => List.generate(
          region.width,
          (x) => region.cellAt(x, y).regionCellId,
        ),
      ),
    );
    drawBorders(image, tmpResult, seaZoneIds, region.cellSize, seaZoneBorderColor);

    // Resource glyphs (geographic mode): g/t/i at cell centre.
    if (geographicMode) {
      for (final cell in region.cells) {
        final letter = resourceIdToLegendLetter(cell.resourceId);
        if (letter == null) continue;
        final cx = cell.x * region.cellSize + region.cellSize ~/ 2;
        final cy = cell.y * region.cellSize + region.cellSize ~/ 2;
        const letterOffsetX = 4;
        const letterOffsetY = 6;
        img.drawString(
          image,
          letter,
          font: img.arial14,
          x: cx - letterOffsetX,
          y: cy - letterOffsetY,
          color: black,
        );
      }
    }

    // Ports.
    const portHalfSize = 4;
    final portColor = image.getColor(
      portMarkerRgb.$1,
      portMarkerRgb.$2,
      portMarkerRgb.$3,
    );
    for (final pt in region.portMarkers) {
      final cx = pt.x * region.cellSize + region.cellSize ~/ 2;
      final cy = pt.y * region.cellSize + region.cellSize ~/ 2;
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

    // Capitals.
    const capitalRadius = 6;
    final capitalColor = image.getColor(
      capitalMarkerRgb.$1,
      capitalMarkerRgb.$2,
      capitalMarkerRgb.$3,
    );
    for (final cap in region.capitalMarkers) {
      final cx = cap.x * region.cellSize + region.cellSize ~/ 2;
      final cy = cap.y * region.cellSize + region.cellSize ~/ 2;
      img.fillCircle(
        image,
        x: cx,
        y: cy,
        radius: capitalRadius,
        color: capitalColor,
      );
      img.drawCircle(
        image,
        x: cx,
        y: cy,
        radius: capitalRadius,
        color: black,
      );
    }

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
      drawLegendSwatch(
        image,
        legendY,
        seaColorRgb.$1,
        seaColorRgb.$2,
        seaColorRgb.$3,
      );
      img.drawString(
        image,
        'Sea',
        font: img.arial14,
        x: legendPadding + swatchSize + swatchGap,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
      for (final entry in region.terrainColors.entries) {
        final y = legendY;
        drawLegendSwatch(
          image,
          y,
          entry.value.$1,
          entry.value.$2,
          entry.value.$3,
        );
        img.drawString(
          image,
          entry.key.name,
          font: img.arial14,
          x: legendPadding + swatchSize + swatchGap,
          y: y,
          color: black,
        );
        legendY += legendLineHeight;
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
      for (final (letter, label) in [
        ('g', 'Grain'),
        ('t', 'Timber'),
        ('i', 'Iron'),
      ]) {
        img.drawString(
          image,
          '$letter  $label',
          font: img.arial14,
          x: legendPadding,
          y: legendY,
          color: black,
        );
        legendY += legendLineHeight;
      }
    } else {
      img.drawString(
        image,
        'Ownership by faction. Black = land borders; light blue = sea borders.',
        font: img.arial14,
        x: legendPadding,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
      for (final entry in region.factionColors.entries) {
        final y = legendY;
        drawLegendSwatch(
          image,
          y,
          entry.value.$1,
          entry.value.$2,
          entry.value.$3,
        );
        img.drawString(
          image,
          entry.key,
          font: img.arial14,
          x: legendPadding + swatchSize + swatchGap,
          y: y,
          color: black,
        );
        legendY += legendLineHeight;
      }
    }
    if (region.portMarkers.isNotEmpty) {
      img.drawString(
        image,
        'Ports marked with teal square.',
        font: img.arial14,
        x: legendPadding,
        y: legendY,
        color: black,
      );
      legendY += legendLineHeight;
    }

    return img.encodePng(image);
  }

  final owPng = _renderRegion(ow);
  final nwPng = _renderRegion(nw);

  return composeMultiRegionMapPng(
    oldWorldPng: owPng,
    newWorldPng: nwPng,
  );
}
