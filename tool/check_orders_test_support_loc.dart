import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3971).
///
/// Physical-line ceilings for `colonizethis_orders` test trees so wave-5
/// fixture/shorthand densification cannot regress.
///
/// - Support: `test/orders/support/` (wave-5 AC ≤13,950)
/// - Package: `test/` (wave-5 AC ≤15,800)

const String ordersTestSupportRelativeDir =
    'packages/colonizethis_orders/test/orders/support';

const String ordersTestPackageRelativeDir = 'packages/colonizethis_orders/test';

/// Ratchet ceiling for support physical LOC (`find … | xargs cat | wc -l`).
/// Wave-5 AC target: 13950. Lower this constant as slices land.
const int ordersTestSupportLocCeiling = 13950;

/// Ratchet ceiling for package `test/` physical LOC.
/// Wave-6 Slice E (#4246): connectivity dev fixture densify 16200 → 15900.
/// Raised to 16050 for civilian work affordance scenario suite (Refs #4262).
/// Raised to 16100 for work-order affordance projection parity tests (Refs #4281).
const int ordersTestPackageLocCeiling = 16100;

/// Counts physical lines of all `*.dart` files under [dir].
int countOrdersTestSupportPhysicalLoc(Directory dir) {
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

/// Alias for package-tree counting (same physical-line method).
int countOrdersTestPackagePhysicalLoc(Directory testDir) =>
    countOrdersTestSupportPhysicalLoc(testDir);

int runCheckOrdersTestSupportLoc(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = ordersTestSupportLocCeiling,
  int packageCeiling = ordersTestPackageLocCeiling,
  bool checkPackage = true,
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
  if (loc > ceiling) {
    logE(
      'check_orders_test_support_loc: support LOC $loc exceeds ceiling '
      '$ceiling (wave-5 target ≤13950; Refs #4109).',
    );
    return 1;
  }
  logI(
    'check_orders_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(wave-5 target ≤13950; Refs #4109).',
  );

  if (!checkPackage) {
    return 0;
  }

  final testDir = Directory(p.join(repoRoot, ordersTestPackageRelativeDir));
  if (!testDir.existsSync()) {
    logE(
      'check_orders_test_support_loc: missing $ordersTestPackageRelativeDir',
    );
    return 1;
  }

  final packageLoc = countOrdersTestPackagePhysicalLoc(testDir);
  if (packageLoc > packageCeiling) {
    logE(
      'check_orders_test_support_loc: package test/ LOC $packageLoc exceeds '
      'ceiling $packageCeiling (wave-6 target ≤16100; Refs #4246, #4262, #4281).',
    );
    return 1;
  }
  logI(
    'check_orders_test_support_loc: package test/ LOC $packageLoc ≤ ceiling '
    '$packageCeiling (wave-6 target ≤16100; Refs #4246, #4262, #4281).',
  );
  return 0;
}

void main() {
  exit(runCheckOrdersTestSupportLoc(Directory.current.path));
}
