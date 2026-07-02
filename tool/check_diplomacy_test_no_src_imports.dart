import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3837).
///
/// Forbid `package:colonizethis_diplomacy/src/` imports in diplomacy tests.
/// Tests must use the public barrel or shared test_support fixtures.
const _diplomacyTestPrefix = 'packages/colonizethis_diplomacy/test/';

/// Tests that intentionally deep-import split phase-type files (Refs #3419).
const _srcImportAllowlist = <String>{
  'packages/colonizethis_diplomacy/test/diplomacy/diplomacy_phase_types_split_test.dart',
};

final RegExp _forbiddenSrcImport = RegExp(
  r'''import\s+['"]package:colonizethis_diplomacy/src/[^'"]+['"]\s*;''',
);

bool diplomacyTestNoSrcImportsPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_diplomacyTestPrefix) &&
      normalized.endsWith('.dart');
}

String? diplomacyTestNoSrcImportsViolationReason(
  String slashPath,
  String content,
) {
  if (_srcImportAllowlist.contains(slashPath.replaceAll('\\', '/'))) {
    return null;
  }
  if (_forbiddenSrcImport.hasMatch(content)) {
    return 'use `package:colonizethis_diplomacy/colonizethis_diplomacy.dart` '
        'or colonizethis_diplomacy_test_support instead of src/ imports '
        '(Refs #3837)';
  }
  return null;
}

int runCheckDiplomacyTestNoSrcImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!diplomacyTestNoSrcImportsPathInScope(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    final reason = diplomacyTestNoSrcImportsViolationReason(rel, content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_diplomacy_test_no_src_imports: no src/ import violations.');
    return 0;
  }
  logE(
    'check_diplomacy_test_no_src_imports: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyTestNoSrcImports(Directory.current.path));
}
