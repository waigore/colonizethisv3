import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3459, AC3).
///
/// Keeps old/new-world region data selection centralized in the
/// `colonizethis_map` package. Every region-scoped read of a world's
/// provinces or units must resolve the region through the canonical
/// [regionDataForMapRegionId] helper (`region_data_access.dart`) so the
/// view-building (orchestration, cell/unit) and ownership-overlay passes share
/// one source of truth instead of repeating
/// `worldState.oldWorld.provinces` / `worldState.newWorld.units` (or the
/// equivalent `isOldWorld ? ... : ...`) branches.
///
/// Forbidden anywhere under `packages/colonizethis_map/lib/**` except the
/// canonical helper file: an inline `.oldWorld.provinces`, `.oldWorld.units`,
/// `.newWorld.provinces`, or `.newWorld.units` region-data branch.
const _mapLibRoot = 'packages/colonizethis_map/lib';

/// The single sanctioned home for the old/new-world region selector.
const _canonicalRegionAccessFile =
    'packages/colonizethis_map/lib/src/region_data_access.dart';

/// Matches an inline region-data branch such as `.oldWorld.provinces` or
/// `.newWorld.units` (the world-state old/new selection the central helper
/// replaces).
final RegExp _inlineRegionDataPattern = RegExp(
  r'\.(oldWorld|newWorld)\.(provinces|units)\b',
);

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckMapRegionDataAccessCentral(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapRegionDataAccessCentral(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_map_region_data_access_central: missing $libDir');
    return 1;
  }

  final violations = <MapRegionDataAccessViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (relPath == _canonicalRegionAccessFile) {
      continue;
    }
    violations.addAll(
      findMapRegionDataAccessViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map region-data access centralization check passed.');
    return 0;
  }

  logE(
    'ERROR: Region old/new-world data must route through '
    'regionDataForMapRegionId(world, regionId) in $_canonicalRegionAccessFile; '
    'do not branch worldState.oldWorld/.newWorld provinces/units inline.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<MapRegionDataAccessViolation> findMapRegionDataAccessViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <MapRegionDataAccessViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    if (_inlineRegionDataPattern.hasMatch(line)) {
      violations.add(
        MapRegionDataAccessViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Inline old/new-world region branch; use '
              'regionDataForMapRegionId(world, regionId) instead.',
        ),
      );
    }
  }
  return violations;
}

class MapRegionDataAccessViolation {
  const MapRegionDataAccessViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
