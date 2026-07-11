import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3971).
///
/// Counts `return Game(` / `=> Game(` under
/// `packages/colonizethis_orders/test/orders/support/` excluding
/// `common/` (shared builders). Wave-4 ratchets this ceiling down as
/// family fixtures migrate onto `game_graphs.dart` /
/// `TestFixtures.minimalGame`.

const String ordersTestSupportRelativeDir =
    'packages/colonizethis_orders/test/orders/support';

/// Ratchet ceiling for raw Game constructions outside `support/common/`.
/// Lower as migrations land (Refs #3971).
const int ordersTestSupportRawGameCeiling = 5;

final RegExp _rawGameConstruction = RegExp(r'(?:return|=>)\s+Game\s*\(');

int countOrdersTestSupportRawGameConstructions(Directory supportDir) {
  var total = 0;
  if (!supportDir.existsSync()) {
    return 0;
  }
  for (final entity in supportDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: supportDir.path);
    final normalized = rel.replaceAll('\\', '/');
    if (normalized.startsWith('common/')) {
      continue;
    }
    final content = entity.readAsStringSync();
    total += _rawGameConstruction.allMatches(content).length;
  }
  return total;
}

int runCheckOrdersTestSupportRawGame(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = ordersTestSupportRawGameCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportDir = Directory(p.join(repoRoot, ordersTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_orders_test_support_raw_game: missing $ordersTestSupportRelativeDir',
    );
    return 1;
  }

  final count = countOrdersTestSupportRawGameConstructions(supportDir);
  if (count <= ceiling) {
    logI(
      'check_orders_test_support_raw_game: raw Game( count $count ≤ ceiling '
      '$ceiling (Refs #3971).',
    );
    return 0;
  }
  logE(
    'check_orders_test_support_raw_game: raw Game( count $count exceeds '
    'ceiling $ceiling (Refs #3971).',
  );
  return 1;
}

void main() {
  exit(runCheckOrdersTestSupportRawGame(Directory.current.path));
}
