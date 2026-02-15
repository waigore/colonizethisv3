// Tile map to PNG with legend. SPEC/program/map-data.md.
// Logic lives here; tools (e.g. describe_topology) only orchestrate.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'map_topology.dart';
import 'tile_map_result.dart';
import 'topology_node.dart';

/// Distinct RGB colors for region assignment (deterministic order).
/// Cycle if more regions than palette size.
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
Uint8List renderTileMapToPng(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 8,
}) {
  final colors = _colorMap(result);
  final mapW = result.width * cellSize;
  final mapH = result.height * cellSize;

  // Legend: title (2 lines) + one line per node (id + P/S).
  final nodesSorted =
      List<TopologyNode>.from(topology.nodes)..sort((a, b) => a.id.compareTo(b.id));
  final legendLines = _titleLines + nodesSorted.length;
  final legendHeight = _legendPadding * 2 + legendLines * _legendLineHeight;
  final totalWidth = mapW;
  final totalHeight = mapH + legendHeight;

  final image = img.Image(width: totalWidth, height: totalHeight);
  final white = image.getColor(255, 255, 255);
  final black = image.getColor(0, 0, 0);
  image.clear(white);

  // Draw map: each cell as filled rect.
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

  // Legend area (below map).
  final legendY0 = mapH + _legendPadding;
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
    'P = province (land), S = sea zone (water).',
    font: img.arial14,
    x: _legendPadding,
    y: legendY0 + _legendLineHeight,
    color: black,
  );

  var row = _titleLines;
  for (final n in nodesSorted) {
    final y = legendY0 + row * _legendLineHeight;
    final c = colors[n.id]!;
    final color = image.getColor(c.$1, c.$2, c.$3);
    img.fillRect(
      image,
      x1: _legendPadding,
      y1: y,
      x2: _legendPadding + _swatchSize - 1,
      y2: y + _swatchSize - 1,
      color: color,
    );
    final label = '${n.id} (${n.type == TopologyNodeType.province ? 'P' : 'S'})';
    img.drawString(
      image,
      label,
      font: img.arial14,
      x: _legendPadding + _swatchSize + _swatchGap,
      y: y,
      color: black,
    );
    row++;
  }

  return img.encodePng(image);
}

/// Encodes the tile map (with legend) to PNG and writes to [file].
void writeTileMapImageToFile(
  File file,
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 8,
}) {
  final bytes = renderTileMapToPng(result, topology, cellSize: cellSize);
  file.writeAsBytesSync(bytes);
}

/// Writes the tile map image to a new file in the system temp directory.
/// Returns the absolute path of the written file.
String writeTileMapImageToTempFile(
  TileMapResult result,
  MapTopology topology, {
  int cellSize = 8,
}) {
  final dir = Directory.systemTemp;
  final file = File('${dir.path}${Platform.pathSeparator}colonizethis_tilemap_${DateTime.now().millisecondsSinceEpoch}.png');
  writeTileMapImageToFile(file, result, topology, cellSize: cellSize);
  return file.absolute.path;
}

/// Tries to open [path] in the system default image viewer.
/// Returns true if the launch command succeeded (exit code 0), false otherwise.
bool openInDefaultViewer(String path) {
  if (Platform.environment['SUPPRESS_IMAGE_VIEWER'] == '1' ||
      Platform.environment['SUPPRESS_IMAGE_VIEWER'] == 'true' ||
      Platform.environment['CI'] == 'true') {
    return false;
  }
  final executable = _viewerExecutable;
  if (executable == null) return false;
  try {
    final result = Process.runSync(
      executable,
      _viewerArgs(path),
      runInShell: true,
    );
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

String? get _viewerExecutable {
  if (Platform.isMacOS) return 'open';
  if (Platform.isLinux) return 'xdg-open';
  if (Platform.isWindows) return 'start';
  return null;
}

List<String> _viewerArgs(String path) {
  if (Platform.isWindows) return [path];
  return [path];
}
