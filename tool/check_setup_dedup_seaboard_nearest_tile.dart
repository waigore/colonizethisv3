import 'dart:io';

import 'package:path/path.dart' as p;

/// Nearest seaboard tile selection must live in `setup_road_wiring.dart`
/// (Refs #4020).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _helperModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/setup_road_wiring.dart';

final RegExp _bannedNearestNames = RegExp(
  r'(?:_nearestCoastalTileInProvinceForSeaZone|_closestSeaboardTileInProvince|'
  r'nearestSeaboardTileInProvinceForSeaZone)\s*\(',
);

/// Nested full-grid walk + Manhattan + tileAdjacentToSeaZone signature.
final RegExp _nestedGridWalk = RegExp(
  r'for\s*\(\s*var\s+y\s*=\s*0\s*;\s*y\s*<\s*map\.height',
);

final RegExp _tileAdjacentMarker = RegExp(r'tileAdjacentToSeaZone\s*\(');

final RegExp _manhattanMarker = RegExp(
  r'\.abs\(\)\s*\+\s*\([^)]*\)\.abs\(\)|'
  r'\(x\s*-\s*\w+\)\.abs\(\)\s*\+\s*\(y\s*-\s*\w+\)\.abs\(\)',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupSeaboardNearestTile(
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
      'Setup dedup seaboard nearest-tile check skipped (setup lib dir absent).',
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

  final violations = findSetupDedupSeaboardNearestTileViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup seaboard nearest-tile check passed.');
    return 0;
  }

  logE(
    'ERROR: nearest seaboard tile selection must live in setup_road_wiring.dart '
    '(nearestSeaboardTileInProvinceForSeaZone); ban a second nested full-grid + '
    'tileAdjacentToSeaZone Manhattan scan outside that module.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupSeaboardNearestTile(Directory.current.path));
}

List<SetupDedupSeaboardNearestTileViolation>
findSetupDedupSeaboardNearestTileViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupSeaboardNearestTileViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_helperModuleRelativePath)) continue;
    final content = _stripLineComments(sourcesByPath[path]!);

    // Private/historical names (definitions or local wrappers).
    if (RegExp(
      r'(?:_nearestCoastalTileInProvinceForSeaZone|'
      r'_closestSeaboardTileInProvince)\s*\(',
    ).hasMatch(content)) {
      violations.add(
        SetupDedupSeaboardNearestTileViolation(
          path: path,
          line: 1,
          message:
              'Private nearest-seaboard clone; use '
              'nearestSeaboardTileInProvinceForSeaZone.',
        ),
      );
      continue;
    }

    // Public redefinition outside helper.
    if (RegExp(
          r'\(int(?:\s+x)?,\s*int(?:\s+y)?\)\?\s+'
          r'nearestSeaboardTileInProvinceForSeaZone\s*\(',
        ).hasMatch(content) ||
        RegExp(
          r'nearestSeaboardTileInProvinceForSeaZone\s*\{',
        ).hasMatch(content)) {
      // Function signature alone may be a re-export; require body markers.
      if (_nestedGridWalk.hasMatch(content) &&
          _tileAdjacentMarker.hasMatch(content) &&
          _manhattanMarker.hasMatch(content)) {
        violations.add(
          SetupDedupSeaboardNearestTileViolation(
            path: path,
            line: 1,
            message:
                'Reimplemented nearest-seaboard scan; use setup_road_wiring.dart.',
          ),
        );
        continue;
      }
    }

    // Anonymous nested scan without naming the helper.
    if (_nestedGridWalk.hasMatch(content) &&
        _tileAdjacentMarker.hasMatch(content) &&
        _manhattanMarker.hasMatch(content) &&
        _bannedNearestNames.hasMatch(content) == false) {
      // Only flag when the body looks like a named nearest helper (bestDist).
      if (content.contains('bestDist') && content.contains('bestX')) {
        violations.add(
          SetupDedupSeaboardNearestTileViolation(
            path: path,
            line: 1,
            message:
                'Inline nearest-seaboard full-grid walk; use '
                'nearestSeaboardTileInProvinceForSeaZone.',
          ),
        );
      }
    }
  }
  return violations;
}

String _stripLineComments(String source) {
  final buf = StringBuffer();
  for (final line in source.split('\n')) {
    final idx = line.indexOf('//');
    buf.writeln(idx < 0 ? line : line.substring(0, idx));
  }
  return buf.toString();
}

class SetupDedupSeaboardNearestTileViolation {
  const SetupDedupSeaboardNearestTileViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
