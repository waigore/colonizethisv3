// Forbids production imports of colonizethis_logic from colonizethis_ai_contracts (Refs #3290 Phase 4).
import 'dart:io';

import 'package:path/path.dart' as p;

const _aiContractsLibRelative = 'packages/colonizethis_ai_contracts/lib';

final _forbiddenImport = RegExp(r"import\s+'package:colonizethis_logic/");

void main() {
  exit(runCheckAiContractsNoLogicDeps(Directory.current.path));
}

int runCheckAiContractsNoLogicDeps(
  String repoRoot, {
  void Function(String line)? err,
}) {
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _aiContractsLibRelative));
  if (!libDir.existsSync()) {
    logE('check_ai_contracts_no_logic_deps: missing $_aiContractsLibRelative');
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
    'check_ai_contracts_no_logic_deps: colonizethis_ai_contracts/lib must not '
    'import colonizethis_logic:',
  );
  for (final path in violations) {
    logE(' - $path');
  }
  return 1;
}
