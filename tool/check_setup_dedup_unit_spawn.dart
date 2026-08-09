import 'dart:io';

import 'package:path/path.dart' as p;

/// Capital unit spawn and home-fleet merge must live in `setup_unit_spawn.dart`
/// (Refs #4054). Callers in base bootstrap and advanced-start units must not
/// re-inline a second `Unit(` capital-spawn loop or `mintShipInstances` home-
/// fleet merge scaffold.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _canonicalRelativePath =
    'packages/colonizethis_setup/lib/src/setup/setup_unit_spawn.dart';

/// Private clone names that previously owned the duplicated spawn/merge bodies.
final RegExp _bannedPrivateClone = RegExp(
  r'\b(_spawnCivilianUnitsOfType|_addStartingRegimentsForPlayer|'
  r'_spawnRegimentsForPlayer|_mergeHomeFleetShipsForPlayer)\b',
);

/// Home-fleet mint call that belongs only in the shared merge helper.
final RegExp _mintShipInstances = RegExp(r'\bmintShipInstances\s*\(');

/// Capital civilian spawn marker (`tileKey: capitalTileKey` on a Unit).
final RegExp _capitalTileKeyUnit = RegExp(r'tileKey:\s*capitalTileKey');

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

int runCheckSetupDedupUnitSpawn(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI('Setup dedup unit-spawn check skipped (setup lib dir absent).');
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

  final violations = findSetupDedupUnitSpawnViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup unit-spawn check passed.');
    return 0;
  }

  logE(
    'ERROR: Found duplicated capital unit spawn or home-fleet merge outside '
    'setup_unit_spawn.dart. Call spawnCivilianUnitsOfType / '
    'spawnRegimentsAtCapital / mergeHomeFleetShips / '
    'prepareHomeFleetMergeScratch instead (Refs #4054).',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupUnitSpawn(Directory.current.path));
}

List<SetupDedupUnitSpawnViolation> findSetupDedupUnitSpawnViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupUnitSpawnViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_canonicalRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      if (_bannedPrivateClone.hasMatch(line)) {
        violations.add(
          SetupDedupUnitSpawnViolation(
            path: path,
            line: i + 1,
            message:
                'Private spawn/merge clone; use setup_unit_spawn.dart helpers.',
          ),
        );
      }
      if (_mintShipInstances.hasMatch(line)) {
        violations.add(
          SetupDedupUnitSpawnViolation(
            path: path,
            line: i + 1,
            message:
                'Home-fleet mintShipInstances; call mergeHomeFleetShips.',
          ),
        );
      }
      if (_capitalTileKeyUnit.hasMatch(line)) {
        violations.add(
          SetupDedupUnitSpawnViolation(
            path: path,
            line: i + 1,
            message:
                'Capital civilian Unit spawn; call spawnCivilianUnitsOfType.',
          ),
        );
      }
    }
  }
  return violations;
}

class SetupDedupUnitSpawnViolation {
  const SetupDedupUnitSpawnViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
