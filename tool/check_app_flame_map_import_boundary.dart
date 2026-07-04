import 'dart:io';

import 'package:path/path.dart' as p;

const _flameRootRelative = 'app/lib/features/game/flame';

/// Enforces one-way import graph among Flame map submodules (Refs #3878 Phase 3):
/// - `flame/map_area/` must not import `flame/map_state/`
/// - `flame/region_map/` must not import `flame/map_state/`
/// - `flame/map_state/` may import `flame/map_area/` only via the public barrel
///   (`map_area/map_area.dart`).
///
/// SPEC: SPEC/program/repo-and-packages.md § App shell submodule layout
int runCheckAppFlameMapImportBoundary(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final flameRoot = Directory(p.join(repoRoot, _flameRootRelative));
  if (!flameRoot.existsSync()) {
    logE('check_app_flame_map_import_boundary: missing $_flameRootRelative');
    return 1;
  }

  final violations = <String>[];

  void scanDir(String relativeSubdir, bool Function(String importLine) isViolation) {
    final dir = Directory(p.join(flameRoot.path, relativeSubdir));
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relPath = p.relative(entity.path, from: repoRoot);
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final trimmed = lines[i].trim();
        if (trimmed.startsWith('//') || !trimmed.startsWith('import ')) {
          continue;
        }
        if (isViolation(trimmed)) {
          violations.add('$relPath:${i + 1}: disallowed import in $relativeSubdir');
        }
      }
    }
  }

  bool importsMapState(String line) =>
      line.contains('/map_state/') ||
      line.contains("import 'map_state/") ||
      line.contains('features/game/flame/map_state/');

  bool importsMapAreaNonPublic(String line) {
    if (!line.contains('/map_area/') && !line.contains("import 'map_area/")) {
      return false;
    }
    return !line.contains('/map_area/map_area.dart') &&
        !line.contains("import 'map_area/map_area.dart'");
  }

  scanDir('map_area', importsMapState);
  scanDir('region_map', importsMapState);
  scanDir('map_state', importsMapAreaNonPublic);

  if (violations.isEmpty) {
    logI('check_app_flame_map_import_boundary: no violations found.');
    return 0;
  }

  logE(
    'check_app_flame_map_import_boundary: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppFlameMapImportBoundary(Directory.current.path));
}
