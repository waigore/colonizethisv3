import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3971).
///
/// Physical-line ceilings for `colonizethis_orders` test trees so wave-4
/// fixture/shorthand densification cannot regress.
///
/// - Support: `test/orders/support/` (wave-4 AC ≤14,900)
/// - Package: `test/` (wave-4 AC ≤16,400)

const String ordersTestSupportRelativeDir =
    'packages/colonizethis_orders/test/orders/support';

const String ordersTestPackageRelativeDir = 'packages/colonizethis_orders/test';

/// Ratchet ceiling for support physical LOC (`find … | xargs cat | wc -l`).
/// Wave-4 AC target: 14900. Lower this constant as slices land.
const int ordersTestSupportLocCeiling = 14500;

/// Ratchet ceiling for package `test/` physical LOC.
/// Wave-4 AC target: 16400.
const int ordersTestPackageLocCeiling = 16400;

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
      '$ceiling (wave-4 target ≤14900; Refs #3971).',
    );
    return 1;
  }
  logI(
    'check_orders_test_support_loc: support LOC $loc ≤ ceiling $ceiling '
    '(wave-4 target ≤14900; Refs #3971).',
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
      'ceiling $packageCeiling (wave-4 target ≤16400; Refs #3971).',
    );
    return 1;
  }
  logI(
    'check_orders_test_support_loc: package test/ LOC $packageLoc ≤ ceiling '
    '$packageCeiling (wave-4 target ≤16400; Refs #3971).',
  );
  return 0;
}

void main() {
  exit(runCheckOrdersTestSupportLoc(Directory.current.path));
}
