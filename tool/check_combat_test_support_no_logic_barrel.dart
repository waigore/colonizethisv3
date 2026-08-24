// Forbids colonizethis_logic imports under colonizethis_combat_test_support/lib
// (Refs #4633). Unpublished combat `src/` imports remain allowed.
import 'dart:io';

import 'package:path/path.dart' as p;

const combatTestSupportLibRelative =
    'packages/colonizethis_combat_test_support/lib';

final _forbiddenImport = RegExp(r"import\s+'package:colonizethis_logic/");

void main() {
  exit(runCheckCombatTestSupportNoLogicBarrel(Directory.current.path));
}

int runCheckCombatTestSupportNoLogicBarrel(
  String repoRoot, {
  Directory? libDir,
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final dir =
      libDir ?? Directory(p.join(repoRoot, combatTestSupportLibRelative));
  if (!dir.existsSync()) {
    logE(
      'check_combat_test_support_no_logic_barrel: missing '
      '$combatTestSupportLibRelative',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
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
    'check_combat_test_support_no_logic_barrel: '
    'colonizethis_combat_test_support/lib must not import colonizethis_logic:',
  );
  for (final path in violations) {
    logE(' - $path');
  }
  return 1;
}
