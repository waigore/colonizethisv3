import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3971).
///
/// Physical-line ceiling for `packages/colonizethis_orders/test/orders/support/`
/// so wave-4 fixture/shorthand dedup cannot regress. Final wave-4 target is
/// ≤14,900; this gate ratchets from the post-slice-1 baseline so each PR can
/// lower the constant without waiting for the full cut.

const String ordersTestSupportRelativeDir =
    'packages/colonizethis_orders/test/orders/support';

/// Ratchet ceiling (physical LOC via `find … | xargs cat | wc -l` equivalent).
/// Wave-4 AC target: 14900. Lower this constant as slices land.
const int ordersTestSupportLocCeiling = 15800;

/// Counts physical lines of all `*.dart` files under [supportDir].
int countOrdersTestSupportPhysicalLoc(Directory supportDir) {
  var total = 0;
  if (!supportDir.existsSync()) {
    return 0;
  }
  for (final entity in supportDir.listSync(recursive: true)) {
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

int runCheckOrdersTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = ordersTestSupportLocCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, ordersTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_orders_test_support_loc: missing $ordersTestSupportRelativeDir',
    );
    return 1;
  }

  final loc = countOrdersTestSupportPhysicalLoc(supportDir);
  if (loc <= ceiling) {
    logI(
      'check_orders_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
      '(wave-4 target ≤14900; Refs #3971).',
    );
    return 0;
  }
  logE(
    'check_orders_test_support_loc: support LOC $loc exceeds ceiling '
    '$ceiling (wave-4 target ≤14900; Refs #3971).',
  );
  return 1;
}

void main() {
  exit(runCheckOrdersTestSupportLoc(Directory.current.path));
}
