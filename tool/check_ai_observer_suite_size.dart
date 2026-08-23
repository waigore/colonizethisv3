import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Physical-line ceiling for AI observer/diagnostic suites (Refs #4530 Slice C).
const int aiObserverSuitePhysicalLineCeiling = 300;

/// Repo-relative path prefix for observer campaign tests.
const String _aiObserverPathPrefix = 'packages/colonizethis_ai/test/observer/';

bool aiObserverSuiteSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiObserverPathPrefix)) {
    return false;
  }
  return normalized.endsWith('.dart');
}

String? aiObserverSuiteSizeViolationReason(String slashPath, String content) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiObserverSuiteSizePathInScope(normalized)) {
    return null;
  }
  final lineCount = content.split('\n').length;
  if (lineCount <= aiObserverSuitePhysicalLineCeiling) {
    return null;
  }
  return 'has $lineCount physical lines (ceiling '
      '$aiObserverSuitePhysicalLineCeiling); split the observer suite '
      '(Refs #4530)';
}

int runCheckAiObserverSuiteSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiObserverSuiteSizeViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_ai_observer_suite_size: no oversize observer suites.');
    return 0;
  }
  logE('check_ai_observer_suite_size: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiObserverSuiteSize(Directory.current.path));
}
