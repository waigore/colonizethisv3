import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4014, #4049).
///
/// Physical-line ceiling for `colonizethis_economy_test_support/lib` so
/// densification waves cannot silently regenerate toward the old soft
/// ≤8,200 target.

const String economyTestSupportRelativeDir =
    'packages/colonizethis_economy_test_support/lib';

/// Ratchet ceiling for support physical LOC (`find … | xargs cat | wc -l`).
/// Phase-7 densify measured 7,490 (Refs #4049; phase-6 target was ≤7,999).
/// Lower this constant as further densify slices land.
const int economyTestSupportLocCeiling = 7495;

/// Counts physical lines of all `*.dart` files under [dir].
int countEconomyTestSupportPhysicalLoc(Directory dir) {
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

int runCheckEconomyTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = economyTestSupportLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, economyTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_economy_test_support_loc: missing $economyTestSupportRelativeDir',
    );
    return 1;
  }

  final loc = countEconomyTestSupportPhysicalLoc(supportDir);
  if (loc > ceiling) {
    logE(
      'check_economy_test_support_loc: support LOC $loc exceeds ceiling '
      '$ceiling (phase-7 target ≤7495; Refs #4014, #4049).',
    );
    return 1;
  }
  logI(
    'check_economy_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(phase-7 target ≤7495; Refs #4014, #4049).',
  );
  return 0;
}

void main() {
  exit(runCheckEconomyTestSupportLoc(Directory.current.path));
}
