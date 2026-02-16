// Tile map to PNG with legend. SPEC/program/map-data.md § Tile map PNG export.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:colonizethis_data/colonizethis_data.dart';

/// Deep blue for sea zones. SPEC/program/map-data.md § Tile map PNG export.
const (int, int, int) seaColorRgb = (20, 60, 140);

/// Light blue for sea zone borders (sea–sea). SPEC/program/map-data.md § Tile map PNG export.
const (int, int, int) seaZoneBorderRgb = (173, 216, 230);

/// Red for on-map region id labels (e.g. p1, s1). SPEC/program/map-data.md § Tile map PNG export.
const (int, int, int) regionIdLabelRgb = (220, 0, 0);

/// Fixed RGB per terrain type for map fill and legend.
const Map<TerrainType, (int r, int g, int b)> terrainColorRgb = {
  TerrainType.plains: (200, 220, 160),
  TerrainType.forest: (34, 100, 34),
  TerrainType.hills: (160, 130, 90),
  TerrainType.mountain: (120, 120, 120),
  TerrainType.swamp: (70, 100, 90),
};

/// Land seed marker color (bright red). SPEC/program/map-data.md § Tile map PNG export.
const (int, int, int) landSeedMarkerRgb = (255, 0, 0);

/// Continent seed marker color (distinct from land seeds; e.g. white/gold). SPEC/program/map-data.md § Tile map PNG export.
const (int, int, int) continentSeedMarkerRgb = (255, 255, 200);

/// Distinct RGB colors for region assignment (fallback when no terrain). Deterministic order.
const List<(int r, int g, int b)> _palette = [
  (180, 80, 80),   // red
  (80, 140, 200),  // blue
  (90, 160, 90),   // green
  (220, 180, 60),  // yellow
  (160, 100, 180), // purple
  (60, 180, 180),  // cyan
  (220, 140, 100), // orange
  (140, 100, 60),  // brown
  (200, 100, 160), // pink
  (100, 120, 200), // lighter blue
  (120, 200, 120), // light green
  (200, 200, 100), // light yellow
  (180, 140, 200), // light purple
  (100, 200, 200), // light cyan
  (200, 160, 140), // peach
  (160, 160, 160), // gray
];

/// Builds a map from region id to (r, g, b) using deterministic palette assignment.
Map<String, (int r, int g, int b)> _colorMap(TileMapResult result) {
  final ids = <String>{};
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      ids.add(result.cell(x, y));
    }
  }
  final sorted = ids.toList()..sort();
  final map = <String, (int r, int g, int b)>{};
  for (var i = 0; i < sorted.length; i++) {
    final c = _palette[i % _palette.length];
    map[sorted[i]] = c;
  }
  return map;
}

/// Legend layout constants.
const int _legendPadding = 12;
const int _legendLineHeight = 20;
const int _swatchSize = 14;
const int _swatchGap = 8;
const int _titleLines = 2;

/// Renders the tile map and legend to a PNG image; returns PNG bytes.
/// When [result.terrainGrid] is present: fill by terrain (sea = deep blue), draw province/sea borders in black, terrain legend. Otherwise: region-colored fill and region legend.
/// When [landSeedPositions] is provided, draws a marker at each cell center and adds a legend row for land seeds.
/// When [landSeedContinentIndices] is provided and same length as [landSeedPositions], land seeds are colored by continent and the legend lists one row per continent.
/// When [continentSeedPositions] is provided, draws a distinct marker at each and adds a legend row for continent seeds. SPEC/program/map-data.md § Tile map PNG export.
Uint8List renderTileMapToPng(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 24,
  List<(int x, int y)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int x, int y)>? continentSeedPositions,
}) {
  final useTerrain = result.terrainGrid != null;
  final showLandSeeds = landSeedPositions != null && landSeedPositions.isNotEmpty;
  final useLandSeedByContinent = showLandSeeds &&
      landSeedContinentIndices != null &&
      landSeedContinentIndices.length == landSeedPositions!.length;
  final showContinentSeeds = continentSeedPositions != null && continentSeedPositions.isNotEmpty;
  final seaZoneIds = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.seaZone) n.id
  };

  final mapW = result.width * cellSize;
  final mapH = result.height * cellSize;

  var legendLines = useTerrain
      ? _titleLines + 1 + TerrainType.values.length  // title + Sea + terrains
      : _titleLines + topology.nodes.length;
  if (showContinentSeeds) legendLines += 1;
  if (showLandSeeds) {
    if (useLandSeedByContinent) {
      final maxContinent = landSeedContinentIndices!.reduce((a, b) => a > b ? a : b);
      legendLines += maxContinent + 1;
    } else {
      legendLines += 1;
    }
  }
  if (result.resourceGrid != null) legendLines += Resource.values.length;
  final legendHeight = _legendPadding * 2 + legendLines * _legendLineHeight;
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

  // Draw map: fill each cell (terrain-based or region-based).
  if (useTerrain) {
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final id = result.cell(x, y);
        final terrain = result.terrainAt(x, y);
        final (r, g, b) = (seaZoneIds.contains(id) || terrain == null)
            ? seaColorRgb
            : terrainColorRgb[terrain]!;
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
  } else {
    final colors = _colorMap(result);
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final id = result.cell(x, y);
        final c = colors[id]!;
        final color = image.getColor(c.$1, c.$2, c.$3);
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
  }

  // Borders: land borders (P–P, P–S) in black; sea zone borders (S–S) in light blue.
  final borderThickness = cellSize >= 12 ? 2 : 1;
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final id = result.cell(x, y);
      if (x + 1 < result.width) {
        final other = result.cell(x + 1, y);
        if (id != other) {
          final borderColor = (seaZoneIds.contains(id) && seaZoneIds.contains(other))
              ? seaZoneBorderColor
              : black;
          final xEdge = (x + 1) * cellSize;
          img.drawLine(
            image,
            x1: xEdge,
            y1: y * cellSize,
            x2: xEdge,
            y2: (y + 1) * cellSize - 1,
            color: borderColor,
            thickness: borderThickness,
          );
        }
      }
      if (y + 1 < result.height) {
        final other = result.cell(x, y + 1);
        if (id != other) {
          final borderColor = (seaZoneIds.contains(id) && seaZoneIds.contains(other))
              ? seaZoneBorderColor
              : black;
          final yEdge = (y + 1) * cellSize;
          img.drawLine(
            image,
            x1: x * cellSize,
            y1: yEdge,
            x2: (x + 1) * cellSize - 1,
            y2: yEdge,
            color: borderColor,
            thickness: borderThickness,
          );
        }
      }
    }
  }

  // Continent seed markers (distinct: larger, different color, black outline).
  if (showContinentSeeds) {
    const radius = 5;
    final fillColor = image.getColor(continentSeedMarkerRgb.$1, continentSeedMarkerRgb.$2, continentSeedMarkerRgb.$3);
    for (final (sx, sy) in continentSeedPositions!) {
      final cx = sx * cellSize + cellSize ~/ 2;
      final cy = sy * cellSize + cellSize ~/ 2;
      img.fillCircle(image, x: cx, y: cy, radius: radius, color: fillColor);
      img.drawCircle(image, x: cx, y: cy, radius: radius, color: black);
    }
  }

  // Land seed markers (cell centers); color by continent when indices provided. Small circles with black outline.
  if (showLandSeeds) {
    const radius = 3;
    for (var i = 0; i < landSeedPositions!.length; i++) {
      final (sx, sy) = landSeedPositions[i];
      final (r, g, b) = useLandSeedByContinent
          ? _palette[landSeedContinentIndices![i] % _palette.length]
          : landSeedMarkerRgb;
      final markerColor = image.getColor(r, g, b);
      final cx = sx * cellSize + cellSize ~/ 2;
      final cy = sy * cellSize + cellSize ~/ 2;
      img.fillCircle(image, x: cx, y: cy, radius: radius, color: markerColor);
      img.drawCircle(image, x: cx, y: cy, radius: radius, color: black);
    }
  }

  // Region id on each tile (red, top-left inset). Drawn after borders/seeds, before resource letters.
  final regionIdColor = image.getColor(
    regionIdLabelRgb.$1,
    regionIdLabelRgb.$2,
    regionIdLabelRgb.$3,
  );
  const idInset = 2;
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final id = result.cell(x, y);
      final tx = x * cellSize + idInset;
      final ty = y * cellSize + idInset;
      img.drawString(image, id, font: img.arial14, x: tx, y: ty, color: regionIdColor);
    }
  }

  // Resource letters (drawn last on map so visible).
  if (result.resourceGrid != null) {
    const letterOffsetX = 4;
    const letterOffsetY = 7;
    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final r = result.resourceAt(x, y);
        if (r == null) continue;
        final letter = _resourceLetter(r);
        final cx = x * cellSize + cellSize ~/ 2;
        final cy = y * cellSize + cellSize ~/ 2;
        final px = cx - letterOffsetX;
        final py = cy - letterOffsetY;
        img.drawString(image, letter, font: img.arial14, x: px, y: py, color: black);
      }
    }
  }

  // Legend (below map).
  final legendY0 = mapH + _legendPadding;
  if (useTerrain) {
    img.drawString(
      image,
      'Terrain. Black = land borders; light blue = sea zone borders.',
      font: img.arial14,
      x: _legendPadding,
      y: legendY0,
      color: black,
    );
    img.drawString(
      image,
      'Colors = terrain type; sea = deep blue.',
      font: img.arial14,
      x: _legendPadding,
      y: legendY0 + _legendLineHeight,
      color: black,
    );
    var row = _titleLines;
    _drawLegendSwatch(image, legendY0 + row * _legendLineHeight, seaColorRgb.$1, seaColorRgb.$2, seaColorRgb.$3);
    img.drawString(image, 'Sea', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: legendY0 + row * _legendLineHeight, color: black);
    row++;
    for (final t in TerrainType.values) {
      final (r, g, b) = terrainColorRgb[t]!;
      _drawLegendSwatch(image, legendY0 + row * _legendLineHeight, r, g, b);
      final label = _terrainLabel(t);
      img.drawString(image, label, font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: legendY0 + row * _legendLineHeight, color: black);
      row++;
    }
    if (showContinentSeeds) {
      final y = legendY0 + row * _legendLineHeight;
      _drawLegendContinentSeedMarker(image, y);
      img.drawString(image, 'Continent seeds (one per continent)', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
      row++;
    }
    if (showLandSeeds) {
      if (useLandSeedByContinent) {
        final maxContinent = landSeedContinentIndices!.reduce((a, b) => a > b ? a : b);
        for (var c = 0; c <= maxContinent; c++) {
          final y = legendY0 + row * _legendLineHeight;
          final (r, g, b) = _palette[c % _palette.length];
          _drawLegendSwatch(image, y, r, g, b);
          img.drawString(image, 'Continent $c', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
          row++;
        }
      } else {
        final y = legendY0 + row * _legendLineHeight;
        _drawLegendLandSeedMarker(image, y);
        img.drawString(image, 'Land seeds (cluster per continent)', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
        row++;
      }
    }
    if (result.resourceGrid != null) {
      for (final r in Resource.values) {
        final y = legendY0 + row * _legendLineHeight;
        img.drawString(image, _resourceLetter(r), font: img.arial14, x: _legendPadding, y: y, color: black);
        img.drawString(image, '  ${_resourceLabel(r)}', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
        row++;
      }
    }
  } else {
    img.drawString(
      image,
      'Each cell = one tile. Colors = regions (provinces / sea zones).',
      font: img.arial14,
      x: _legendPadding,
      y: legendY0,
      color: black,
    );
    img.drawString(
      image,
      'P = province (land), S = sea zone. Black = land borders; light blue = sea borders.',
      font: img.arial14,
      x: _legendPadding,
      y: legendY0 + _legendLineHeight,
      color: black,
    );
    final colors = _colorMap(result);
    final nodesSorted =
        List<TopologyNode>.from(topology.nodes)..sort((a, b) => a.id.compareTo(b.id));
    var row = _titleLines;
    for (final n in nodesSorted) {
      final y = legendY0 + row * _legendLineHeight;
      final c = colors[n.id]!;
      _drawLegendSwatch(image, y, c.$1, c.$2, c.$3);
      final label = '${n.id} (${n.type == TopologyNodeType.province ? 'P' : 'S'})';
      img.drawString(image, label, font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
      row++;
    }
    if (showContinentSeeds) {
      final y = legendY0 + row * _legendLineHeight;
      _drawLegendContinentSeedMarker(image, y);
      img.drawString(image, 'Continent seeds (one per continent)', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
      row++;
    }
    if (showLandSeeds) {
      if (useLandSeedByContinent) {
        final maxContinent = landSeedContinentIndices!.reduce((a, b) => a > b ? a : b);
        for (var c = 0; c <= maxContinent; c++) {
          final y = legendY0 + row * _legendLineHeight;
          final (r, g, b) = _palette[c % _palette.length];
          _drawLegendSwatch(image, y, r, g, b);
          img.drawString(image, 'Continent $c', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
          row++;
        }
      } else {
        final y = legendY0 + row * _legendLineHeight;
        _drawLegendLandSeedMarker(image, y);
        img.drawString(image, 'Land seeds (cluster per continent)', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
        row++;
      }
    }
    if (result.resourceGrid != null) {
      for (final r in Resource.values) {
        final y = legendY0 + row * _legendLineHeight;
        img.drawString(image, _resourceLetter(r), font: img.arial14, x: _legendPadding, y: y, color: black);
        img.drawString(image, '  ${_resourceLabel(r)}', font: img.arial14, x: _legendPadding + _swatchSize + _swatchGap, y: y, color: black);
        row++;
      }
    }
  }

  return img.encodePng(image);
}

void _drawLegendContinentSeedMarker(img.Image image, int y) {
  final cx = _legendPadding + _swatchSize ~/ 2;
  final cy = y + _swatchSize ~/ 2;
  final fillColor = image.getColor(continentSeedMarkerRgb.$1, continentSeedMarkerRgb.$2, continentSeedMarkerRgb.$3);
  final black = image.getColor(0, 0, 0);
  img.fillCircle(image, x: cx, y: cy, radius: 5, color: fillColor);
  img.drawCircle(image, x: cx, y: cy, radius: 5, color: black);
}

void _drawLegendLandSeedMarker(img.Image image, int y) {
  final cx = _legendPadding + _swatchSize ~/ 2;
  final cy = y + _swatchSize ~/ 2;
  final black = image.getColor(0, 0, 0);
  final color = image.getColor(landSeedMarkerRgb.$1, landSeedMarkerRgb.$2, landSeedMarkerRgb.$3);
  img.fillCircle(image, x: cx, y: cy, radius: 4, color: color);
  img.drawCircle(image, x: cx, y: cy, radius: 4, color: black);
}

void _drawLegendSwatch(img.Image image, int y, int r, int g, int b) {
  final color = image.getColor(r, g, b);
  img.fillRect(
    image,
    x1: _legendPadding,
    y1: y,
    x2: _legendPadding + _swatchSize,
    y2: y + _swatchSize,
    color: color,
  );
}

String _terrainLabel(TerrainType t) {
  switch (t) {
    case TerrainType.plains:
      return 'Plains';
    case TerrainType.forest:
      return 'Forest';
    case TerrainType.hills:
      return 'Hills';
    case TerrainType.mountain:
      return 'Mountain';
    case TerrainType.swamp:
      return 'Swamp';
  }
}

String _resourceLetter(Resource r) {
  switch (r) {
    case Resource.grain:
      return 'g';
    case Resource.timber:
      return 't';
    case Resource.iron:
      return 'i';
  }
}

String _resourceLabel(Resource r) {
  switch (r) {
    case Resource.grain:
      return 'Grain';
    case Resource.timber:
      return 'Timber';
    case Resource.iron:
      return 'Iron';
  }
}

/// Writes the tile map image to [file].
void writeTileMapImageToFile(
  File file,
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 24,
  List<(int x, int y)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int x, int y)>? continentSeedPositions,
}) {
  final png = renderTileMapToPng(
    result,
    topology,
    cellSize: cellSize,
    landSeedPositions: landSeedPositions,
    landSeedContinentIndices: landSeedContinentIndices,
    continentSeedPositions: continentSeedPositions,
  );
  file.writeAsBytesSync(png);
}

/// Writes the tile map image to a new file in the system temp directory.
/// Returns the absolute path of the written file.
String writeTileMapImageToTempFile(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 24,
  List<(int x, int y)>? landSeedPositions,
  List<int>? landSeedContinentIndices,
  List<(int x, int y)>? continentSeedPositions,
}) {
  final tmp = Directory.systemTemp;
  final name = 'tile_map_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File('${tmp.path}/$name');
  writeTileMapImageToFile(
    file,
    result,
    topology,
    cellSize: cellSize,
    landSeedPositions: landSeedPositions,
    landSeedContinentIndices: landSeedContinentIndices,
    continentSeedPositions: continentSeedPositions,
  );
  return file.absolute.path;
}

/// Tries to open [path] in the system default image viewer.
/// Respects SUPPRESS_IMAGE_VIEWER=1 env var to skip opening in non-interactive contexts.
bool openInDefaultViewer(String path) {
  if (Platform.environment['SUPPRESS_IMAGE_VIEWER'] == '1') {
    return false;
  }
  try {
    if (Platform.isMacOS) {
      Process.runSync('open', [path]);
      return true;
    } else if (Platform.isLinux) {
      Process.runSync('xdg-open', [path]);
      return true;
    } else if (Platform.isWindows) {
      Process.runSync('explorer', [path]);
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}

