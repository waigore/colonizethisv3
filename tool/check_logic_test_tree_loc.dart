import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md, SPEC/program/logic-package-split-phase0.md
/// (Refs #4090 Slice E / AC5).
///
/// Physical-line ceiling for the entire `colonizethis_logic/test` tree so
/// orphan domain suites cannot silently regrow past the post-purge target.

const String logicTestRelativeDir = 'packages/colonizethis_logic/test';

/// Issue AC2/AC5 ceiling (≤5,800). Residual thin-core tree is far below this;
/// lower the constant as further shrinks land.
const int logicTestTreeLocCeiling = 5800;

/// Counts physical lines of all `*.dart` files under [dir].
int countLogicTestTreePhysicalLoc(Directory dir) {
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

int runCheckLogicTestTreeLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = logicTestTreeLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final testDir = Directory(p.join(repoRoot, logicTestRelativeDir));
  if (!testDir.existsSync()) {
    logE('check_logic_test_tree_loc: missing $logicTestRelativeDir');
    return 1;
  }

  final loc = countLogicTestTreePhysicalLoc(testDir);
  if (loc > ceiling) {
    logE(
      'check_logic_test_tree_loc: test tree LOC $loc exceeds ceiling '
      '$ceiling (Refs #4090 AC2/AC5).',
    );
    return 1;
  }
  logI(
    'check_logic_test_tree_loc: test tree LOC $loc ≤ ceiling $ceiling '
    '(Refs #4090).',
  );
  return 0;
}

void main() {
  exit(runCheckLogicTestTreeLoc(Directory.current.path));
}
