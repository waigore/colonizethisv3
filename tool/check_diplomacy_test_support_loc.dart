import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4028).
///
/// Physical-line ceiling for `colonizethis_diplomacy_test_support/lib` so
/// wave-3 densify cannot regress.

const String diplomacyTestSupportRelativeDir =
    'packages/colonizethis_diplomacy_test_support/lib';

/// Ratchet ceiling for support physical LOC. Wave-3 AC target ≤2800; start at
/// post-slice measured total and lower as densify lands (Refs #4028).
const int diplomacyTestSupportLocCeiling = 3271;

/// Counts physical lines of all `*.dart` files under [dir].
int countDiplomacyTestSupportPhysicalLoc(Directory dir) {
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

int runCheckDiplomacyTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = diplomacyTestSupportLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir =
      Directory(p.join(repoRoot, diplomacyTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_diplomacy_test_support_loc: missing $diplomacyTestSupportRelativeDir',
    );
    return 1;
  }

  final loc = countDiplomacyTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_diplomacy_test_support_loc: support LOC $loc exceeds ceiling '
      '$ceiling (wave-3 target ≤2800; Refs #4028).',
    );
    return 1;
  }
  logI(
    'check_diplomacy_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(wave-3 target ≤2800; Refs #4028).',
  );
  return 0;
}

void main() {
  exit(runCheckDiplomacyTestSupportLoc(Directory.current.path));
}
