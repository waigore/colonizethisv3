// Forbids production imports of colonizethis_logic from colonizethis_combat (Refs #3290 Phase 1).
import 'dart:io';

import 'package:path/path.dart' as p;

const _combatLibRelative = 'packages/colonizethis_combat/lib';

final _forbiddenImport = RegExp(
  r"import\s+'package:colonizethis_logic/",
);

void main() {
  exit(runCheckCombatNoLogicDeps(Directory.current.path));
}

int runCheckCombatNoLogicDeps(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _combatLibRelative));
  if (!libDir.existsSync()) {
    logE('check_combat_no_logic_deps: missing $_combatLibRelative');
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
    'check_combat_no_logic_deps: colonizethis_combat/lib must not import colonizethis_logic:',
  );
  for (final path in violations) {
    logE(' - $path');
  }
  return 1;
}
