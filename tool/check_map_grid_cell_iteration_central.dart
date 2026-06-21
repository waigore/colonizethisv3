import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3574).
///
/// Keeps tile-grid cell traversal centralized in the `colonizethis_map`
/// package. Hand-rolled nested `for (var y …) { for (var x …) }` walks over a
/// row-major tile grid must route through the canonical
/// [TileMapGrid.forEachIndex] / [TileMapGrid.forEachCell] helpers
/// (`tile_map_grid.dart`) so iteration order — which seeded generation depends
/// on for bit-for-bit determinism — has one definition across the generation
/// passes, view builders, and visualizers.
///
/// A "nested y/x walk" is detected when a `for (<decl> y …)` loop header is
/// immediately followed by a `for (<decl> x …)` loop header (the canonical
/// row-major shape). Comment lines between the two headers are skipped.
///
/// Exemptions:
/// - whole-file: the canonical API home and graph/distance-transform algorithms
///   that cannot adopt a single-pass `(y, x)` callback ([_exemptFiles]);
/// - per-loop: an inline `ct-lint-allow: nested-grid-walk` marker on the outer
///   `for (… y …)` header line or on the comment line directly above it, for
///   genuine exceptions such as `sync*` generators (a callback cannot `yield`
///   to the enclosing generator) and bordered interior walks that skip the
///   grid edge.
const _mapLibRoot = 'packages/colonizethis_map/lib';

/// Whole-file exemptions (paths relative to the repo root).
///
/// - `tile_map_grid.dart` defines the canonical traversal API itself.
/// - `tile_map_grid_graph.dart` holds BFS / flood-fill / neighbour graph
///   algorithms whose traversal order is not row-major cell iteration.
/// - `tile_map_manhattan_distance_transform.dart` is a two-pass (forward +
///   reverse) distance transform; it is not a forward-only row-major walk.
const _exemptFiles = <String>{
  'packages/colonizethis_map/lib/src/tile_map_grid.dart',
  'packages/colonizethis_map/lib/src/gen/tile_map_grid_graph.dart',
  'packages/colonizethis_map/lib/src/gen/tile_map_manhattan_distance_transform.dart',
};

/// Inline per-loop opt-out marker. Place on the outer `for (… y …)` header line
/// (trailing comment) or on the comment line directly above it.
const String kNestedGridWalkAllowMarker = 'ct-lint-allow: nested-grid-walk';

final RegExp _outerYLoopPattern = RegExp(r'for\s*\(\s*(?:var|final|int)\s+y\b');
final RegExp _innerXLoopPattern = RegExp(r'for\s*\(\s*(?:var|final|int)\s+x\b');

/// True when [line] is a pure comment line so prose is not treated as code.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckMapGridCellIterationCentral(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapGridCellIterationCentral(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_map_grid_cell_iteration_central: missing $libDir');
    return 1;
  }

  final violations = <MapGridCellIterationViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (_exemptFiles.contains(relPath)) {
      continue;
    }
    violations.addAll(
      findMapGridCellIterationViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map grid cell-iteration centralization check passed.');
    return 0;
  }

  logE(
    'ERROR: Tile-grid cell walks must route through TileMapGrid.forEachIndex / '
    'TileMapGrid.forEachCell (packages/colonizethis_map/lib/src/tile_map_grid.dart). '
    'Replace hand-rolled nested `for (var y …) { for (var x …) }` walks, or, for '
    'a genuine exception (sync* generator, bordered edge-skipping walk), add an '
    'inline `$kNestedGridWalkAllowMarker` marker on the outer loop header:',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<MapGridCellIterationViolation> findMapGridCellIterationViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <MapGridCellIterationViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    if (!_outerYLoopPattern.hasMatch(line)) {
      continue;
    }
    final innerIndex = _indexOfInnerXLoop(lines, i);
    if (innerIndex == null) {
      continue;
    }
    if (_hasAllowMarker(lines, i)) {
      continue;
    }
    violations.add(
      MapGridCellIterationViolation(
        path: relativePath,
        line: i + 1,
        message:
            'Nested y/x tile-grid walk; use TileMapGrid.forEachIndex(...) / '
            'TileMapGrid.forEachCell(...) or add a '
            '`$kNestedGridWalkAllowMarker` marker for a sanctioned exception.',
      ),
    );
  }
  return violations;
}

/// Returns the index of the inner `for (… x …)` header when it immediately
/// follows the outer `for (… y …)` header at [outerIndex] (skipping blank and
/// comment lines), or `null` when there is no adjacent inner x-loop.
int? _indexOfInnerXLoop(List<String> lines, int outerIndex) {
  for (var j = outerIndex + 1; j < lines.length; j++) {
    final candidate = lines[j];
    if (candidate.trim().isEmpty || _isCommentLine(candidate)) {
      continue;
    }
    return _innerXLoopPattern.hasMatch(candidate) ? j : null;
  }
  return null;
}

/// True when the outer loop header at [outerIndex] carries the allow marker on
/// its own line or on the comment line directly above it.
bool _hasAllowMarker(List<String> lines, int outerIndex) {
  if (lines[outerIndex].contains(kNestedGridWalkAllowMarker)) {
    return true;
  }
  for (var j = outerIndex - 1; j >= 0; j--) {
    final above = lines[j];
    if (above.trim().isEmpty) {
      continue;
    }
    if (!_isCommentLine(above)) {
      return false;
    }
    if (above.contains(kNestedGridWalkAllowMarker)) {
      return true;
    }
  }
  return false;
}

class MapGridCellIterationViolation {
  const MapGridCellIterationViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
