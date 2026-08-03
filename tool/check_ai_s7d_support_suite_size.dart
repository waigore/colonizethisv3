import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Soft physical-line ceiling for S7D support modules (Refs #3997 / #4079 /
/// #4104). Phase-8 was 800; Phase-9 Slice D tightened to 650; Phase-10
/// Slice C densify ratchets to 600 (Refs #4104); Phase-11 Slice C →550 (#4239).
const int aiS7dSupportSuitePhysicalLineCeiling = 550;

/// Repo-relative path prefix for S7D support modules.
const String _aiS7dSupportPathPrefix =
    'packages/colonizethis_ai/test/support/s7d/';

/// True when [slashPath] is an in-scope S7D support Dart module.
bool aiS7dSupportSuiteSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiS7dSupportPathPrefix)) {
    return false;
  }
  return normalized.endsWith('.dart');
}

/// Returns a violation reason when an in-scope S7D support module exceeds
/// the soft ceiling.
String? aiS7dSupportSuiteSizeViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiS7dSupportSuiteSizePathInScope(normalized)) {
    return null;
  }
  final lineCount = content.split('\n').length;
  if (lineCount <= aiS7dSupportSuitePhysicalLineCeiling) {
    return null;
  }
  return 'has $lineCount physical lines (soft ceiling '
      '$aiS7dSupportSuitePhysicalLineCeiling); further topic-split the '
      'S7D support module (Refs #3997)';
}

int runCheckAiS7dSupportSuiteSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiS7dSupportSuiteSizeViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_s7d_support_suite_size: no oversize S7D support modules.',
    );
    return 0;
  }
  logE(
    'check_ai_s7d_support_suite_size: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiS7dSupportSuiteSize(Directory.current.path));
}
