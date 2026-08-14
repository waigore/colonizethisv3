import 'dart:io';

import 'package:path/path.dart' as p;

/// Coord→tile / owned-tile-key helpers must live in
/// `setup_road_wiring_tile_helpers.dart` (Refs #4020; SoT path updated Refs #4349).
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

const _helperModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/setup_road_wiring_tile_helpers.dart';

final RegExp _bannedPrivateNames = RegExp(
  r'(?:Map<String,\s*String>\s+|Set<String>\s+)?'
  r'(?:_coordToTileKey|_allowedTileKeysForFaction|_buildCoordToTileKeyByRegion|'
  r'_addCoordMappingIfPresent|_bfsParentsFromCapital)\s*\(',
);

final RegExp _reimplementedCoordBody = RegExp(
  r'gridCoordKey\s*\([^)]*\)\s*=\s*\w+',
);

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupRoadTileKeyMaps(
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
      'Setup dedup road tile-key maps check skipped (setup lib dir absent).',
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

  final violations = findSetupDedupRoadTileKeyMapsViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup road tile-key maps check passed.');
    return 0;
  }

  logE(
    'ERROR: coord→tile / owned tile-key helpers must live in '
    'setup_road_wiring_tile_helpers.dart (coordToTileKeyForRegion / '
    'ownedTileKeysForFaction / bfsParentsFromTileKey); ban private '
    '_coordToTileKey / _allowedTileKeysForFaction / _bfsParentsFromCapital '
    'clones.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupRoadTileKeyMaps(Directory.current.path));
}

List<SetupDedupRoadTileKeyMapsViolation>
findSetupDedupRoadTileKeyMapsViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupRoadTileKeyMapsViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_helperModuleRelativePath)) continue;
    final content = _stripLineComments(sourcesByPath[path]!);
    if (_bannedPrivateNames.hasMatch(content)) {
      violations.add(
        SetupDedupRoadTileKeyMapsViolation(
          path: path,
          line: 1,
          message:
              'Private road tile-key helper clone; use '
              'setup_road_wiring_tile_helpers.dart.',
        ),
      );
      continue;
    }
    // Public redefinition of coordToTileKeyForRegion / ownedTileKeysForFaction
    // / bfsParentsFromTileKey outside the helper module.
    if (RegExp(
          r'(?:Map<String,\s*String>|Set<String>)\s+'
          r'(?:coordToTileKeyForRegion|ownedTileKeysForFaction|'
          r'bfsParentsFromTileKey|coordToTileKeysFromProvinceLists|'
          r'coordToTileKeyByRegion)\s*\(',
        ).hasMatch(content) &&
        _reimplementedCoordBody.hasMatch(content)) {
      violations.add(
        SetupDedupRoadTileKeyMapsViolation(
          path: path,
          line: 1,
          message:
              'Reimplemented coord/owned tile-key helper; use '
              'setup_road_wiring_tile_helpers.dart.',
        ),
      );
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

class SetupDedupRoadTileKeyMapsViolation {
  const SetupDedupRoadTileKeyMapsViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
