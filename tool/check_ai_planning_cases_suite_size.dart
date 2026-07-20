import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Physical-line ceiling for AI planning `*_cases.dart` modules
/// (Refs #3997). Phase-10 Slice C densify ratchets 650→600 (Refs #4104).
const int aiPlanningCasesSuitePhysicalLineCeiling = 600;

/// Repo-relative path prefix for AI planning case libraries.
const String _aiPlanningCasesPathPrefix =
    'packages/colonizethis_ai/test/planning/';

/// Indivisible allowlist entries (path → issue Ref). Prefer split over allowlist.
const Map<String, String> aiPlanningCasesSuiteSizeAllowlist =
    <String, String>{};

/// True when [slashPath] is an in-scope planning `*_cases.dart` module.
bool aiPlanningCasesSuiteSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiPlanningCasesPathPrefix)) {
    return false;
  }
  return normalized.endsWith('_cases.dart');
}

/// Returns a violation reason when an in-scope cases module exceeds the ceiling
/// without an allowlist entry.
String? aiPlanningCasesSuiteSizeViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiPlanningCasesSuiteSizePathInScope(normalized)) {
    return null;
  }
  if (aiPlanningCasesSuiteSizeAllowlist.containsKey(normalized)) {
    return null;
  }
  final lineCount = content.split('\n').length;
  if (lineCount <= aiPlanningCasesSuitePhysicalLineCeiling) {
    return null;
  }
  return 'has $lineCount physical lines (ceiling '
      '$aiPlanningCasesSuitePhysicalLineCeiling); topic-split the module or '
      'register an indivisible allowlist entry with issue Ref '
      '(Refs #3997)';
}

int runCheckAiPlanningCasesSuiteSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPlanningCasesSuiteSizeViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_planning_cases_suite_size: no oversize planning '
      '`*_cases.dart` modules.',
    );
    return 0;
  }
  logE(
    'check_ai_planning_cases_suite_size: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiPlanningCasesSuiteSize(Directory.current.path));
}
