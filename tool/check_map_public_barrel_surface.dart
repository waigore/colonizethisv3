import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3459, AC4, #4561).
///
/// Keeps the public `colonizethis_map` barrel narrowed to intentional entry
/// points. Internal-only generation primitives and test-only APIs must not be
/// re-exported from `packages/colonizethis_map/lib/colonizethis_map.dart` or
/// any module in its transitive `export` closure; same-package tests import
/// them from `src/` directly.
const _barrelFile = 'packages/colonizethis_map/lib/colonizethis_map.dart';
const _mapLibRoot = 'packages/colonizethis_map/lib/';

/// Internal-only `src/` modules that must stay out of the public barrel closure.
const _forbiddenBarrelExports = <String>[
  'src/gen/grid_voronoi.dart',
  'src/gen/topology_inference.dart',
  'src/gen/tile_map_grid_graph.dart',
  'src/gen/tile_map_generator_lakes_test_api.dart',
];

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

class MapPublicBarrelViolation {
  const MapPublicBarrelViolation({
    required this.file,
    required this.line,
    required this.message,
  });

  final String file;
  final int line;
  final String message;
}

/// Parses `export '…';` targets from [source], ignoring comment lines.
List<String> exportTargetsFromSource(String source) {
  final targets = <String>[];
  for (final line in source.split('\n')) {
    if (_isCommentLine(line)) {
      continue;
    }
    final trimmed = line.trimLeft();
    if (!trimmed.startsWith('export ')) {
      continue;
    }
    final match = RegExp(r'''export\s+['"]([^'"]+)['"]''').firstMatch(trimmed);
    if (match != null) {
      targets.add(match.group(1)!);
    }
  }
  return targets;
}

/// Finds forbidden internal-module re-exports in [source] at [relativeFilePath].
List<MapPublicBarrelViolation> findForbiddenExportViolations({
  required String relativeFilePath,
  required String source,
}) {
  final lines = source.split('\n');
  final violations = <MapPublicBarrelViolation>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) {
      continue;
    }
    final trimmed = line.trimLeft();
    if (!trimmed.startsWith('export ')) {
      continue;
    }
    var forbiddenMatched = false;
    for (final module in _forbiddenBarrelExports) {
      if (trimmed.contains("'$module'") || trimmed.contains('"$module"')) {
        violations.add(
          MapPublicBarrelViolation(
            file: relativeFilePath,
            line: i + 1,
            message:
                'Internal-only module `$module` must not be re-exported from '
                'the public barrel closure; import it from src/ in same-package '
                'tests.',
          ),
        );
        forbiddenMatched = true;
        break;
      }
    }
    if (!forbiddenMatched && trimmed.contains('_test_api.dart')) {
      violations.add(
        MapPublicBarrelViolation(
          file: relativeFilePath,
          line: i + 1,
          message:
              'Test-only API modules (`*_test_api.dart`) must not be '
              're-exported from the public barrel closure.',
        ),
      );
    }
  }
  return violations;
}

/// Collects the transitive `export` closure starting at [barrelRelativePath].
List<String> collectTransitiveExportClosure({
  required String repoRoot,
  required String barrelRelativePath,
}) {
  final visited = <String>{};
  final queue = <String>[barrelRelativePath.replaceAll('\\', '/')];

  while (queue.isNotEmpty) {
    final relativePath = queue.removeLast();
    if (!visited.add(relativePath)) {
      continue;
    }
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      continue;
    }
    for (final target in exportTargetsFromSource(file.readAsStringSync())) {
      final resolved = _resolveExportTarget(
        fromRelativePath: relativePath,
        exportTarget: target,
      );
      if (resolved == null) {
        continue;
      }
      if (!visited.contains(resolved)) {
        queue.add(resolved);
      }
    }
  }
  return visited.toList()..sort();
}

String? _resolveExportTarget({
  required String fromRelativePath,
  required String exportTarget,
}) {
  if (exportTarget.startsWith('package:')) {
    return null;
  }
  final fromDir = p.dirname(fromRelativePath);
  final resolved = p
      .normalize(p.join(fromDir, exportTarget))
      .replaceAll('\\', '/');
  if (!resolved.startsWith(_mapLibRoot)) {
    return null;
  }
  return resolved;
}

/// Finds forbidden internal-module re-exports across the barrel closure.
List<MapPublicBarrelViolation> findMapPublicBarrelViolations({
  required String repoRoot,
  required Iterable<String> closureRelativePaths,
}) {
  final violations = <MapPublicBarrelViolation>[];
  for (final relativePath in closureRelativePaths) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      continue;
    }
    violations.addAll(
      findForbiddenExportViolations(
        relativeFilePath: relativePath,
        source: file.readAsStringSync(),
      ),
    );
  }
  violations.sort((a, b) {
    final fileCompare = a.file.compareTo(b.file);
    if (fileCompare != 0) return fileCompare;
    return a.line.compareTo(b.line);
  });
  return violations;
}

void main() {
  exit(runCheckMapPublicBarrelSurface(Directory.current.path));
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckMapPublicBarrelSurface(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final barrel = File(p.join(root, _barrelFile));
  if (!barrel.existsSync()) {
    logE('check_map_public_barrel_surface: missing $_barrelFile');
    return 1;
  }

  final closure = collectTransitiveExportClosure(
    repoRoot: root,
    barrelRelativePath: _barrelFile,
  );
  final violations = findMapPublicBarrelViolations(
    repoRoot: root,
    closureRelativePaths: closure,
  );

  if (violations.isEmpty) {
    logI('colonizethis_map public barrel surface check passed.');
    return 0;
  }

  logE(
    'ERROR: $_barrelFile transitive export closure must not re-export '
    'internal-only generation primitives or test-only APIs (Refs #3459 AC4, '
    '#4561).',
  );
  for (final v in violations) {
    logE('${v.file}:${v.line} ${v.message}');
  }
  return 1;
}
