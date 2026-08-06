// Physical-line ratchet for `packages/colonizethis_setup/test/setup/support/`
// (`repo.colonizethis_setup_test_support_loc`).
//
// SPEC: SPEC/program/repo-lint.md (Refs #4273 wave 6 slice D).
//
// Counts every `*.dart` file under the support tree (physical lines). Ceiling
// is post-densify measured total plus modest headroom so incidental helper
// extracts do not fail CI; ratchet downward as later densify shrinks the tree.

import 'dart:io';

import 'package:path/path.dart' as p;

const String setupTestSupportRelativeDir =
    'packages/colonizethis_setup/test/setup/support';

/// Post–slice D scenario-table support-tree ceiling (physical LOC) with headroom.
const int setupTestSupportLocCeiling = 2700;

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

  final loc = countSetupTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_colonizethis_setup_test_support_loc: support LOC $loc exceeds '
      'ceiling $ceiling (Refs #4273).',
    );
    return 1;
  }
  logI(
    'check_colonizethis_setup_test_support_loc: support LOC $loc ≤ ceiling '
    '$ceiling (Refs #4273).',
  );
  return 0;
}

void main() {
  exit(runCheckColonizethisSetupTestSupportLoc(Directory.current.path));
}
