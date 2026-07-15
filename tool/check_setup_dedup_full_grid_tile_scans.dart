import 'dart:io';

import 'package:path/path.dart' as p;

/// Full-grid nested `for y { for x { ... } }` walks under setup lib must live
/// in `tile_cell_scan.dart` (Refs #4029). Specialty edge walks (e.g. warp-zone
/// border scans without a nested width loop) are unaffected.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _sharedModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/tile_cell_scan.dart';

final RegExp _yOuter = RegExp(
  r'for\s*\(\s*var\s+y\s*=\s*0\s*;\s*y\s*<\s*[^;]+\.height',
);

final RegExp _xInner = RegExp(
  r'for\s*\(\s*var\s+x\s*=\s*0\s*;\s*x\s*<\s*[^;]+\.width',
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupFullGridTileScans(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI(
      'Setup dedup full-grid tile-scans check skipped (setup lib dir absent).',
    );
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findSetupDedupFullGridTileScansViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup full-grid tile-scans check passed.');
    return 0;
  }

  logE(
    'ERROR: Found nested full-grid `for y { for x }` walks outside '
    'tile_cell_scan.dart. Route production full-grid scans through '
    'forEachTileCell / forEachProvinceCell / visitGpOwLandTiles (Refs #4029).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupFullGridTileScans(Directory.current.path));
}

/// Flags nested height×width double-loops outside [_sharedModuleRelativePath].
List<SetupDedupFullGridTileScansViolation>
findSetupDedupFullGridTileScansViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupFullGridTileScansViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_sharedModuleRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (!_yOuter.hasMatch(line)) continue;
      // Look ahead a short window for the nested x/width loop.
      final lookEnd = (i + 6).clamp(0, lines.length);
      var nested = false;
      for (var j = i + 1; j < lookEnd; j++) {
        if (_isCommentLine(lines[j])) continue;
        if (_xInner.hasMatch(lines[j])) {
          nested = true;
          break;
        }
      }
      if (!nested) continue;
      violations.add(
        SetupDedupFullGridTileScansViolation(
          path: path,
          line: i + 1,
          message:
              'Nested full-grid tile walk; use forEachTileCell / '
              'forEachProvinceCell instead.',
        ),
      );
    }
  }
  return violations;
}

class SetupDedupFullGridTileScansViolation {
  const SetupDedupFullGridTileScansViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
