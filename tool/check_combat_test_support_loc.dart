import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4196).
///
/// Physical-line ceiling for `colonizethis_combat_test_support/lib` so
/// densification waves cannot silently regenerate toward the pre-wave
/// 7,307-line baseline.

const String combatTestSupportRelativeDir =
    'packages/colonizethis_combat_test_support/lib';

/// Ratchet ceiling for support physical LOC (`find … | xargs cat | wc -l`).
/// #4633 wave 2 measured 6997 (Refs #4633; #4196 was ≤7250).
const int combatTestSupportLocCeiling = 6997;

/// Counts physical lines of all `*.dart` files under [dir].
int countCombatTestSupportPhysicalLoc(Directory dir) {
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

int runCheckCombatTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = combatTestSupportLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, combatTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_combat_test_support_loc: missing $combatTestSupportRelativeDir',
    );
    return 1;
  }

  final loc = countCombatTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_combat_test_support_loc: support LOC $loc exceeds ceiling '
      '$ceiling (#4633 target ≤6997; Refs #4633).',
    );
    return 1;
  }
  logI(
    'check_combat_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(#4633 target ≤6997; Refs #4633).',
  );
  return 0;
}

void main() {
  exit(runCheckCombatTestSupportLoc(Directory.current.path));
}
