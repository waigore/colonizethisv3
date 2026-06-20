import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup package whose Great Power Old World tile-scan helpers must stay
/// deduplicated behind the shared `gp_old_world_tile_scan.dart` module
/// (Refs #3449). The resource redistribution and terrain redistribution
/// concerns each previously carried verbatim private copies of the owner map,
/// the tile-key builder, the GP-id predicate, and the eligible-tile collector.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

/// The shared module that owns the canonical (public, package-internal) tile
/// scan helpers. It is the only file allowed to define them.
const _sharedModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/gp_old_world_tile_scan.dart';

/// Private helper identifiers that were duplicated across the two GP OW
/// redistribution libraries before #3449. They are now public and live solely
/// in [_sharedModuleRelativePath] as `gpOwTileKey`, `gpOwnerByLocalProvinceId`,
/// and `isGpOwner`. Any reappearance of an underscore-prefixed clone signals a
/// re-inlined, duplicated tile-scan helper.
final List<RegExp> _bannedPrivateHelperPatterns = <RegExp>[
  RegExp(r'\b_ownerByLocalProvinceId\b'),
  RegExp(r'\b_owTileKey\b'),
  RegExp(r'\b_isGpId\b'),
  RegExp(r'\b_collectEligibleTilesSorted\b'),
];

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupGpOwTileScans(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI('Setup dedup GP OW tile-scans check skipped (setup lib dir absent).');
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

  final violations = findSetupDedupGpOwTileScansViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup GP OW tile-scans check passed.');
    return 0;
  }

  logE(
    'ERROR: Found duplicated Great Power Old World tile-scan helpers in the '
    'setup package. Delegate to the shared gp_old_world_tile_scan.dart module '
    '(gpOwTileKey, gpOwnerByLocalProvinceId, isGpOwner, visitGpOwLandTiles, '
    'collectGpOwEligibleTilesSorted) instead of re-inlining private copies.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupGpOwTileScans(Directory.current.path));
}

/// Scans [sourcesByPath] (relative path -> source) for re-inlined GP OW
/// tile-scan helpers. The shared module ([_sharedModuleRelativePath]) is
/// exempt because it owns the canonical public helpers; every other setup
/// source must use those public helpers rather than redefining the private
/// clones.
List<SetupDedupGpOwTileScansViolation> findSetupDedupGpOwTileScansViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupGpOwTileScansViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_sharedModuleRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      for (final pattern in _bannedPrivateHelperPatterns) {
        if (pattern.hasMatch(line)) {
          violations.add(
            SetupDedupGpOwTileScansViolation(
              path: path,
              line: i + 1,
              message:
                  'Duplicated GP OW tile-scan helper (${pattern.pattern}); '
                  'use the shared gp_old_world_tile_scan.dart helpers.',
            ),
          );
        }
      }
    }
  }
  return violations;
}

class SetupDedupGpOwTileScansViolation {
  const SetupDedupGpOwTileScansViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
