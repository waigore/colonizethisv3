import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Physical-line ceiling for EXPAND-peace `*_test.dart` contracts once
/// Phase-6 case extraction has landed (Refs #3977). Phase-10 Slice C
/// densify ratchets 650→600 (Refs #4104); Phase-11 Slice C →550 (#4239);
/// Phase-12 Slice D →500 (Refs #4291); Phase-13 Slice D →450 (Refs #4310).
const int expandPeacePinSuitePhysicalLineCeiling = 450;

/// Repo-relative path prefix for EXPAND peace unit pins.
const String _expandPeaceTestPathPrefix =
    'packages/colonizethis_ai/test/planning/expand_phase_planner_';

/// True when [slashPath] is an in-scope expand-peace `*_test.dart` pin.
bool aiExpandPeacePinSuiteSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_expandPeaceTestPathPrefix)) {
    return false;
  }
  if (!normalized.endsWith('_test.dart')) {
    return false;
  }
  final fileName = p.basename(normalized);
  return fileName.contains('peace');
}

/// True when [content] imports a sibling `*_cases.dart` (or shared runner)
/// that indicates the suite was case-extracted.
bool aiExpandPeacePinSuiteImportsCases(String content) {
  return RegExp(r'''import\s+['"][^'"]*_cases\.dart['"]''').hasMatch(content);
}

/// Returns a violation reason when an oversize peace pin lacks case import.
String? aiExpandPeacePinSuiteSizeViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiExpandPeacePinSuiteSizePathInScope(normalized)) {
    return null;
  }
  final lineCount = content.split('\n').length;
  if (lineCount <= expandPeacePinSuitePhysicalLineCeiling) {
    return null;
  }
  if (aiExpandPeacePinSuiteImportsCases(content)) {
    return null;
  }
  return 'has $lineCount physical lines (ceiling '
      '$expandPeacePinSuitePhysicalLineCeiling) without importing a sibling '
      '`*_cases.dart`; extract case bodies or shrink the contract '
      '(Refs #3977)';
}

int runCheckAiExpandPeacePinSuiteSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiExpandPeacePinSuiteSizeViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_expand_peace_pin_suite_size: no oversize expand-peace '
      'contracts without `*_cases.dart` imports.',
    );
    return 0;
  }
  logE(
    'check_ai_expand_peace_pin_suite_size: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiExpandPeacePinSuiteSize(Directory.current.path));
}
