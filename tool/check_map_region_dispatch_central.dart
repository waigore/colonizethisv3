import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3574).
///
/// Keeps old/new-world region *dispatch* centralized in the `colonizethis_map`
/// package. Beyond the region-*data* selector guarded by
/// `repo.map_region_data_access_central`, the colour, capital-scope, port-tile
/// bucketing, and view-data assembly paths must resolve old/new branching
/// through the canonical [selectByMapRegionId] /
/// [selectByMapRegionIdOrNull] helpers (`map_region_dispatch.dart`) instead of
/// repeating inline `regionId == kRegionOldWorld` / `kRegionNewWorld`
/// comparisons. Using the region constants as map keys, list elements, named
/// arguments, or string-interpolation operands is unaffected — only `==` / `!=`
/// comparisons against [kRegionOldWorld] / [kRegionNewWorld] are forbidden.
///
/// Forbidden anywhere under `packages/colonizethis_map/lib/**` except the
/// canonical dispatch file: an inline `== kRegionOldWorld`,
/// `kRegionNewWorld ==`, or `!=` comparison against either region constant.
const _mapLibRoot = 'packages/colonizethis_map/lib';

/// The single sanctioned home for the old/new-world dispatch helpers.
const _canonicalRegionDispatchFile =
    'packages/colonizethis_map/lib/src/map_region_dispatch.dart';

/// Matches a comparison (`==` or `!=`) against either region constant on either
/// side of the operator (for example `regionId == kRegionOldWorld` or
/// `kRegionNewWorld != parsed.regionId`).
final RegExp _inlineRegionComparePattern = RegExp(
  r'(==|!=)\s*kRegion(OldWorld|NewWorld)\b'
  r'|\bkRegion(OldWorld|NewWorld)\s*(==|!=)',
);

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

void main() {
  exit(runCheckMapRegionDispatchCentral(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapRegionDispatchCentral(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final libDir = Directory(p.join(root, _mapLibRoot));
  if (!libDir.existsSync()) {
    logE('check_map_region_dispatch_central: missing $libDir');
    return 1;
  }

  final violations = <MapRegionDispatchViolation>[];
  for (final file in libDir.listSync(recursive: true, followLinks: false)) {
    if (file is! File || !file.path.endsWith('.dart')) {
      continue;
    }
    final relPath = p.normalize(p.relative(file.path, from: root));
    if (relPath == _canonicalRegionDispatchFile) {
      continue;
    }
    violations.addAll(
      findMapRegionDispatchViolations(
        relativePath: relPath,
        source: file.readAsStringSync(),
      ),
    );
  }

  if (violations.isEmpty) {
    logI('colonizethis_map region dispatch centralization check passed.');
    return 0;
  }

  logE(
    'ERROR: Region old/new-world dispatch must route through '
    'selectByMapRegionId(...) / selectByMapRegionIdOrNull(...) in '
    '$_canonicalRegionDispatchFile; do not branch '
    '`regionId == kRegionOldWorld` / `kRegionNewWorld` inline.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

List<MapRegionDispatchViolation> findMapRegionDispatchViolations({
  required String relativePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <MapRegionDispatchViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    if (_inlineRegionComparePattern.hasMatch(line)) {
      violations.add(
        MapRegionDispatchViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Inline old/new-world region comparison; use '
              'selectByMapRegionId(...) / selectByMapRegionIdOrNull(...) instead.',
        ),
      );
    }
  }
  return violations;
}

class MapRegionDispatchViolation {
  const MapRegionDispatchViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
