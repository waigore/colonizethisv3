// Physical-line ratchet for `packages/colonizethis_turn/test/support/`
// (`repo.turn_test_support_loc`).
//
// SPEC: SPEC/program/repo-lint.md (§ turn test support LOC). Refs #4039.
//
// Counts every `*.dart` file under the support tree (physical lines). Ceiling
// is post-densify measured total plus modest headroom so incidental helper
// extracts do not fail CI; ratchet downward as later densify shrinks the tree.

import 'dart:io';

import 'package:path/path.dart' as p;

const String turnTestSupportRelativeDir =
    'packages/colonizethis_turn/test/support';

/// Post-#4039 densify support-tree ceiling (physical LOC) with headroom.
/// Wave 4 (#4113) **5800**; wave 5 slice A (#4168) **5675** (shrink-only).
const int turnTestSupportLocCeiling = 5675;

/// Counts physical lines of all `*.dart` files under [dir].
int countTurnTestSupportPhysicalLoc(Directory dir) {
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

int runCheckTurnTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = turnTestSupportLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, turnTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE('check_turn_test_support_loc: missing $turnTestSupportRelativeDir');
    return 1;
  }

  final loc = countTurnTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_turn_test_support_loc: support LOC $loc exceeds ceiling '
      '$ceiling (Refs #4039).',
    );
    return 1;
  }
  logI(
    'check_turn_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(Refs #4039).',
  );
  return 0;
}

void main() {
  exit(runCheckTurnTestSupportLoc(Directory.current.path));
}
