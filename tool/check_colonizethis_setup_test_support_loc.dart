// Physical-line ratchet for `packages/colonizethis_setup/test/setup/support/`
// (`repo.colonizethis_setup_test_support_loc`).
//
// SPEC: SPEC/program/repo-lint.md (Refs #4273 wave 6 slice D, #4349 slice D).
//
// Counts every `*.dart` file under the support tree (physical lines). Tree
// ceiling is post-split measured total plus modest headroom so incidental
// helper extracts do not fail CI. Per-file ceiling keeps fat scenario modules
// from re-accumulating after topic splits.

import 'dart:io';

import 'package:path/path.dart' as p;

const String setupTestSupportRelativeDir =
    'packages/colonizethis_setup/test/setup/support';

/// Post–wave-7 slice D support-tree ceiling (physical LOC) with headroom.
/// Measured 3996 after splitting the six ≥336-line scenario modules
/// (Refs #4349). Wave-6 was 2700; slice C densify moved suite bodies into
/// support/ so the tree total cannot return to 2700 without undoing that
/// migration.
const int setupTestSupportLocCeiling = 4100;

/// Fail when any support `*.dart` file has this many physical lines or more.
const int setupTestSupportFilePhysicalLineCeiling = 380;

/// Counts physical lines of all `*.dart` files under [dir].
int countSetupTestSupportPhysicalLoc(Directory dir) {
  var total = 0;
  if (!dir.existsSync()) {
    return 0;
  }
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('.dart')) {
      continue;
    }
    total += entity.readAsLinesSync().length;
  }
  return total;
}

int runCheckColonizethisSetupTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = setupTestSupportLocCeiling,
  int fileCeiling = setupTestSupportFilePhysicalLineCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, setupTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_colonizethis_setup_test_support_loc: missing '
      '$setupTestSupportRelativeDir',
    );
    return 1;
  }

  var failed = false;
  for (final entity in supportDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final lines = entity.readAsLinesSync().length;
    if (lines >= fileCeiling) {
      final relative = p.relative(entity.path, from: repoRoot);
      logE(
        'check_colonizethis_setup_test_support_loc: $relative has $lines '
        'physical lines (≥ $fileCeiling; Refs #4349).',
      );
      failed = true;
    }
  }
  if (failed) {
    return 1;
  }

  final loc = countSetupTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_colonizethis_setup_test_support_loc: support LOC $loc exceeds '
      'ceiling $ceiling (Refs #4273, #4349).',
    );
    return 1;
  }
  logI(
    'check_colonizethis_setup_test_support_loc: support LOC $loc ≤ ceiling '
    '$ceiling; no file ≥ $fileCeiling lines (Refs #4273, #4349).',
  );
  return 0;
}

void main() {
  exit(runCheckColonizethisSetupTestSupportLoc(Directory.current.path));
}
