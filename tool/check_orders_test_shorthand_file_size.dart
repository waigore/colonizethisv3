import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4109 wave 5 Slice A).
///
/// Physical-line ceiling for `*expectation_shorthand.dart` under
/// `packages/colonizethis_orders/test/orders/support/`.

const String ordersTestShorthandRelativeDir =
    'packages/colonizethis_orders/test/orders/support';

/// Ratchet ceiling for shorthand physical LOC. Wave-5 AC: ≤180.
const int ordersTestShorthandFileSizeCeiling = 180;

int runCheckOrdersTestShorthandFileSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = ordersTestShorthandFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final supportDir = Directory(p.join(repoRoot, ordersTestShorthandRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_orders_test_shorthand_file_size: missing '
      '$ordersTestShorthandRelativeDir',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in supportDir.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final name = p.basename(entity.path);
    if (!name.endsWith('expectation_shorthand.dart')) {
      continue;
    }
    final physicalLines =
        const LineSplitter().convert(entity.readAsStringSync()).length;
    if (physicalLines > ceiling) {
      final relative = p.relative(entity.path, from: repoRoot);
      violations.add('$relative ($physicalLines physical lines > $ceiling)');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_orders_test_shorthand_file_size: no violations found '
      '(ceiling $ceiling; Refs #4109).',
    );
    return 0;
  }

  logE(
    'check_orders_test_shorthand_file_size: found ${violations.length} '
    'violation(s) (ceiling $ceiling; Refs #4109):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersTestShorthandFileSize(Directory.current.path));
}
