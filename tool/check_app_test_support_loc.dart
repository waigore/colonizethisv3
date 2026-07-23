// Physical-line ratchet for `app/test/support/` (`repo.app_test_support_loc`).
//
// SPEC: SPEC/program/repo-lint.md (§ app test support LOC). Refs #4021.
//
// Counts every `*.dart` file under `app/test/support/` (physical lines, matching
// `find … | xargs cat | wc -l` / `readAsLinesSync().length`). The ceiling is the
// post-wave measured total; CI fails on net regrowth.

import 'dart:io';

import 'package:path/path.dart' as p;

const String appTestSupportRelativeDir = 'app/test/support';

/// Post-#4035 densify support-tree ceiling (physical LOC).
/// Ratcheted after wave-9 slice F units-panel + resource-cell densify (Refs #4117).
const int appTestSupportLocCeiling = 8302;

/// Counts physical lines of all `*.dart` files under [dir].
int countAppTestSupportPhysicalLoc(Directory dir) {
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

int runCheckAppTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = appTestSupportLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, appTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE('check_app_test_support_loc: missing $appTestSupportRelativeDir');
    return 1;
  }

  final loc = countAppTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_app_test_support_loc: support LOC $loc exceeds ceiling '
      '$ceiling (Refs #4021).',
    );
    return 1;
  }
  logI(
    'check_app_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(Refs #4021).',
  );
  return 0;
}

void main() {
  exit(runCheckAppTestSupportLoc(Directory.current.path));
}
