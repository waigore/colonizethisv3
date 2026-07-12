import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Physical-line ceiling for COLONIAL military / naval `*_test.dart`
/// contracts after Phase-6 case extraction (Refs #3977).
const int colonialMilitaryNavalPinSuitePhysicalLineCeiling = 750;

const String _planningPrefix = 'packages/colonizethis_ai/test/planning/';

/// Basenames gated after military / naval case extraction.
const Set<String> colonialMilitaryNavalPinSuiteGatedBasenames = {
  'colonial_phase_planner_military_test.dart',
  'colonial_phase_planner_naval_test.dart',
};

bool aiColonialMilitaryNavalPinSuiteSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_planningPrefix)) {
    return false;
  }
  return colonialMilitaryNavalPinSuiteGatedBasenames.contains(
    p.basename(normalized),
  );
}

bool aiColonialMilitaryNavalPinSuiteImportsCases(String content) {
  return RegExp(r'''import\s+['"][^'"]*_cases\.dart['"]''').hasMatch(content);
}

String? aiColonialMilitaryNavalPinSuiteSizeViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiColonialMilitaryNavalPinSuiteSizePathInScope(normalized)) {
    return null;
  }
  final lineCount = content.split('\n').length;
  if (lineCount <= colonialMilitaryNavalPinSuitePhysicalLineCeiling) {
    return null;
  }
  if (aiColonialMilitaryNavalPinSuiteImportsCases(content)) {
    return null;
  }
  return 'has $lineCount physical lines (ceiling '
      '$colonialMilitaryNavalPinSuitePhysicalLineCeiling) without importing '
      'a sibling `*_cases.dart`; extract case bodies or shrink the contract '
      '(Refs #3977)';
}

int runCheckAiColonialMilitaryNavalPinSuiteSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiColonialMilitaryNavalPinSuiteSizeViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_colonial_military_naval_pin_suite_size: no oversize '
      'military/naval contracts without `*_cases.dart` imports.',
    );
    return 0;
  }
  logE(
    'check_ai_colonial_military_naval_pin_suite_size: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiColonialMilitaryNavalPinSuiteSize(Directory.current.path));
}
