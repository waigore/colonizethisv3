import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3459, AC4).
///
/// Keeps the public `colonizethis_map` barrel narrowed to intentional entry
/// points. Internal-only generation primitives must not be re-exported from
/// `packages/colonizethis_map/lib/colonizethis_map.dart`; same-package tests
/// import them from `src/` directly. Forbidding their re-export prevents the
/// public surface from silently widening again after the #3459 narrowing.
const _barrelFile = 'packages/colonizethis_map/lib/colonizethis_map.dart';

/// Internal-only `src/` modules that must stay out of the public barrel.
const _forbiddenBarrelExports = <String>[
  'src/grid_voronoi.dart',
  'src/topology_inference.dart',
  'src/tile_map_grid_graph.dart',
];

/// True when [line] is a pure comment line so a mention in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

class MapPublicBarrelViolation {
  const MapPublicBarrelViolation({
    required this.line,
    required this.message,
  });

  final int line;
  final String message;
}

/// Finds forbidden internal-module re-exports in the barrel [source].
List<MapPublicBarrelViolation> findMapPublicBarrelViolations({
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
    for (final module in _forbiddenBarrelExports) {
      if (trimmed.contains("'$module'") || trimmed.contains('"$module"')) {
        violations.add(
          MapPublicBarrelViolation(
            line: i + 1,
            message:
                'Internal-only module `$module` must not be re-exported from '
                'the public barrel; import it from src/ in same-package tests.',
          ),
        );
      }
    }
  }
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

  final violations = findMapPublicBarrelViolations(
    source: barrel.readAsStringSync(),
  );

  if (violations.isEmpty) {
    logI('colonizethis_map public barrel surface check passed.');
    return 0;
  }

  logE(
    'ERROR: $_barrelFile must not re-export internal-only generation '
    'primitives (Refs #3459 AC4).',
  );
  for (final v in violations) {
    logE('$_barrelFile:${v.line} ${v.message}');
  }
  return 1;
}
