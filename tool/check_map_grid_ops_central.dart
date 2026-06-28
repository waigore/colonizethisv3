import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3459, AC5).
///
/// Keeps tile-grid deep-copy logic centralized in the `colonizethis_map`
/// package. Every defensive copy of a row-major 2D tile grid must route through
/// the canonical [TileMapGrid.copy] helper (`tile_map_grid.dart`) so the
/// grid-copy site has a single source of truth across the land-seed,
/// lakes-province, and join-sea generation passes.
///
/// Forbidden anywhere under `packages/colonizethis_map/lib/**` except the
/// canonical helper file:
/// - a reference to the removed `copyTileMapGrid(` helper, and
/// - an inline row-major deep copy `<g>.map((row) => row.toList()).toList()`.
const _mapLibRoot = 'packages/colonizethis_map/lib';

/// The single sanctioned home for the row-major grid deep-copy expression.
const _canonicalGridFile =
    'packages/colonizethis_map/lib/src/tile_map_grid.dart';

/// Matches the removed `copyTileMapGrid(` helper invocation.
final RegExp _removedHelperPattern = RegExp(r'\bcopyTileMapGrid\s*\(');

/// Matches an inline row-major deep copy such as
/// `grid.map((row) => row.toList()).toList()`.
final RegExp _inlineDeepCopyPattern = RegExp(
  r'\.map\(\s*\(\s*\w+\s*\)\s*=>\s*\w+\.toList\(\)\s*\)\.toList\(\)',
);

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckMapGridOpsCentral(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapGridOpsCentral(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_map_grid_ops_central: missing $libDir');
    return 1;
  }

  final violations = <MapGridOpsCentralViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (relPath == _canonicalGridFile) {
      continue;
    }
    violations.addAll(
      findMapGridOpsCentralViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map grid-ops centralization check passed.');
    return 0;
  }

  logE(
    'ERROR: Tile-grid deep copies must route through TileMapGrid.copy(...) in '
    '$_canonicalGridFile; do not re-introduce copyTileMapGrid(...) or inline '
    '`.map((row) => row.toList()).toList()` copies.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<MapGridOpsCentralViolation> findMapGridOpsCentralViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <MapGridOpsCentralViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    if (_removedHelperPattern.hasMatch(line)) {
      violations.add(
        MapGridOpsCentralViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Removed copyTileMapGrid(...) call; use TileMapGrid.copy(...).',
        ),
      );
    }
    if (_inlineDeepCopyPattern.hasMatch(line)) {
      violations.add(
        MapGridOpsCentralViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Inline row-major deep copy; use TileMapGrid.copy(...) instead.',
        ),
      );
    }
  }
  return violations;
}

class MapGridOpsCentralViolation {
  const MapGridOpsCentralViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
