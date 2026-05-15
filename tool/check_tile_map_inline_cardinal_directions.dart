import 'dart:io';

import 'package:path/path.dart' as p;

/// Cardinal neighbor deltas must come from [tile_map_directions.dart].
/// Refs #2489 (optional CI); SPEC/program/tile-map-gen-algorithm.md.
const _allowedPath = 'packages/colonizethis_map/lib/src/tile_map_directions.dart';

const _mapLibRoot = 'packages/colonizethis_map/lib';

/// North delta `(0, -1)` is the canonical sentinel for inline 4-neighbor lists.
final _inlineNorthDeltaPattern = RegExp(r'\(\s*0\s*,\s*-1\s*\)');

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckTileMapInlineCardinalDirections(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_tile_map_inline_cardinal_directions: missing $libDir');
    return 1;
  }

  final violations = <TileMapInlineCardinalDirectionViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (relPath == _allowedPath) {
      continue;
    }
    violations.addAll(
      findTileMapInlineCardinalDirectionViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('tile map inline cardinal-direction check passed.');
    return 0;
  }

  logE(
    'ERROR: Inline cardinal neighbor tuple `(0, -1)` must not appear in '
    'colonizethis_map lib; use kTileMapDirections4 / kTileMapDirections8 in '
    '$_allowedPath.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line}:${v.column} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckTileMapInlineCardinalDirections(Directory.current.path));
}

List<TileMapInlineCardinalDirectionViolation>
findTileMapInlineCardinalDirectionViolations({
  required String relativePath,
  required String source,
}) {
  final violations = <TileMapInlineCardinalDirectionViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final match = _inlineNorthDeltaPattern.firstMatch(line);
    if (match == null) {
      continue;
    }
    violations.add(
      TileMapInlineCardinalDirectionViolation(
        path: relativePath,
        line: i + 1,
        column: match.start + 1,
        message:
            'Inline `(0, -1)` tuple; use kTileMapDirections4/8 from tile_map_directions.dart.',
      ),
    );
  }
  return violations;
}

class TileMapInlineCardinalDirectionViolation {
  const TileMapInlineCardinalDirectionViolation({
    required this.path,
    required this.line,
    required this.column,
    required this.message,
  });

  final String path;
  final int line;
  final int column;
  final String message;
}
