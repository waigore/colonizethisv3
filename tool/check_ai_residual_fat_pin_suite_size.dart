import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Physical-line ceiling for Phase-8 residual fat pin contracts after
/// case extraction (Refs #3997). Same ≤750-or-cases pattern as colonial
/// military / naval / lite-naval.
const int residualFatPinSuitePhysicalLineCeiling = 750;

const String _planningPrefix = 'packages/colonizethis_ai/test/planning/';
const String _supportTestPrefix =
    'packages/colonizethis_ai/test/support_test/';

/// Basenames gated as residual fat pins are cases-split under Phase 8.
const Set<String> residualFatPinSuiteGatedBasenames = {
  'observer_goal_phase_test.dart',
  'treasury_planner_treasury_budget_test.dart',
  'economy_planner_regiment_build_input_production_test.dart',
  'develop_phase_planner_test.dart',
  'phase_planner_economy_filter_test.dart',
  'phase_planner_priority_weight_resolvers_test.dart',
  'phase_planner_conquest_wiring_test.dart',
  'treasury_planner_test.dart',
  'diplomatic_candidate_scoring_test.dart',
  'expand_phase_planner_focus_minor_target_test.dart',
  'colonial_phase_planner_acquisition_purchase_land_test.dart',
  'seed42_s7d_feedstock_helpers_test.dart',
};

bool aiResidualFatPinSuiteSizePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  final basename = p.basename(normalized);
  if (!residualFatPinSuiteGatedBasenames.contains(basename)) {
    return false;
  }
  return normalized.startsWith(_planningPrefix) ||
      normalized.startsWith(_supportTestPrefix);
}

bool aiResidualFatPinSuiteImportsCases(String content) {
  return RegExp(r'''import\s+['"][^'"]*_cases\.dart['"]''').hasMatch(content);
}

String? aiResidualFatPinSuiteSizeViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiResidualFatPinSuiteSizePathInScope(normalized)) {
    return null;
  }
  final lineCount = content.split('\n').length;
  if (lineCount <= residualFatPinSuitePhysicalLineCeiling) {
    return null;
  }
  if (aiResidualFatPinSuiteImportsCases(content)) {
    return null;
  }
  return 'has $lineCount physical lines (ceiling '
      '$residualFatPinSuitePhysicalLineCeiling) without importing '
      'a sibling `*_cases.dart`; extract case bodies or shrink the contract '
      '(Refs #3997)';
}

int runCheckAiResidualFatPinSuiteSize(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiResidualFatPinSuiteSizeViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_residual_fat_pin_suite_size: no oversize residual fat-pin '
      'contracts without `*_cases.dart` imports.',
    );
    return 0;
  }
  logE(
    'check_ai_residual_fat_pin_suite_size: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiResidualFatPinSuiteSize(Directory.current.path));
}
