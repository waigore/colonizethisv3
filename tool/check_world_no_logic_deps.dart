// Forbids production imports of colonizethis_logic from colonizethis_world (Refs #3290 Phase 1).
import 'dart:io';

import 'package:path/path.dart' as p;

const _worldLibRelative = 'packages/colonizethis_world/lib';

final _forbiddenImport = RegExp(
  r"import\s+'package:colonizethis_logic/",
);

void main() {
  exit(runCheckWorldNoLogicDeps(Directory.current.path));
}

int runCheckWorldNoLogicDeps(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _worldLibRelative));
  if (!libDir.existsSync()) {
    logE('check_world_no_logic_deps: missing $_worldLibRelative');
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
    'check_world_no_logic_deps: colonizethis_world/lib must not import colonizethis_logic:',
  );
  for (final path in violations) {
    logE(' - $path');
  }
  return 1;
}
