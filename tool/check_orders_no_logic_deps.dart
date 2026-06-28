// Forbids production imports of colonizethis_logic from colonizethis_orders (Refs #3290 Phase 2).
import 'dart:io';

import 'package:path/path.dart' as p;

const _ordersLibRelative = 'packages/colonizethis_orders/lib';

final _forbiddenImport = RegExp(r"import\s+'package:colonizethis_logic/");

void main() {
  exit(runCheckOrdersNoLogicDeps(Directory.current.path));
}

int runCheckOrdersNoLogicDeps(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _ordersLibRelative));
  if (!libDir.existsSync()) {
    logE('check_orders_no_logic_deps: missing $_ordersLibRelative');
    return 1;
  }

  final violations = <String>[];
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final content = entity.readAsStringSync();
    if (_forbiddenImport.hasMatch(content)) {
      violations.add(p.relative(entity.path, from: repoRoot));
    }
  }

  if (violations.isEmpty) {
    return 0;
  }

  logE(
    'check_orders_no_logic_deps: colonizethis_orders/lib must not import colonizethis_logic:',
  );
  for (final path in violations) {
    logE(' - $path');
  }
  return 1;
}
