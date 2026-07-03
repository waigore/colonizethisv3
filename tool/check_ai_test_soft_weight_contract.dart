import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the AI package test tree whose soft-weight
/// wiring contract tests this gate freezes (Refs #3749 step 3).
const String _aiTestPathPrefix = 'packages/colonizethis_ai/test/';

/// Filename suffix reserved for the **parameterized** soft-weight wiring
/// *contract* tests. The Phase-3 soft-weight migration (Refs #2847) produced
/// many near-identical per-helper wiring suites; #3749 § Test streamlining
/// consolidated the shared contracts into the two table-driven files in
/// [softWeightContractAllowlist]. This gate keeps the consolidation by
/// forbidding any **new** `*soft_weight_wiring_test.dart` clone: new
/// soft-weight wiring assertions for a `scaleWeightedBonus`-shaped or
/// threshold-cap helper must extend one of the allowlisted parameterized
/// contract files (add a row to its helper table), not spawn a new per-helper
/// suite.
const String _softWeightContractSuffix = 'soft_weight_wiring_test.dart';

/// The two consolidated parameterized soft-weight wiring *contract* tests that
/// legitimately carry the [_softWeightContractSuffix] name. These own the
/// shared `scaleWeightedBonus` scaled-magnitude contract and the
/// colonial-pressure threshold-cap contract respectively (Refs #3749).
///
/// Behavioural integration pins that observe soft-weight wiring through
/// `pickBuildOrder` / `evaluateStrategicGoalScores` /
/// `computeDiplomaticCandidateScores` deliberately do **not** use this suffix
/// (they live in `*_cargo_bonus_test.dart`, `*_colonial_pressure_test.dart`,
/// `*_nw_suppression_test.dart`, `*_ow_bonus_scaling_test.dart`) so this gate
/// counts only the parameterized contract files.
const Set<String> softWeightContractAllowlist = <String>{
  'packages/colonizethis_ai/test/planning/phase_planner_colonial_pressure_scaled_bonus_soft_weight_wiring_test.dart',
  'packages/colonizethis_ai/test/planning/phase_planner_threshold_cap_soft_weight_wiring_test.dart',
};

/// True when the repo-relative [slashPath] is an AI package test source whose
/// filename ends with [_softWeightContractSuffix] (the reserved parameterized
/// contract-file suffix).
bool aiTestSoftWeightContractPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiTestPathPrefix)) {
    return false;
  }
  return normalized.endsWith(_softWeightContractSuffix);
}

/// Returns a violation reason when the AI test source at repo-relative
/// [slashPath] carries the reserved [_softWeightContractSuffix] but is not one
/// of the [softWeightContractAllowlist] parameterized contract files, or `null`
/// when compliant / out of scope.
String? aiTestSoftWeightContractViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiTestSoftWeightContractPathInScope(normalized)) {
    return null;
  }
  if (softWeightContractAllowlist.contains(normalized)) {
    return null;
  }
  return "uses the reserved `*$_softWeightContractSuffix` parameterized "
      "soft-weight contract suffix but is not one of the consolidated contract "
      "files; extend an existing parameterized contract "
      "(${softWeightContractAllowlist.join(', ')}) by adding a helper-table "
      "row instead of spawning a new per-helper wiring suite, or rename a "
      "behavioural pin off this suffix (Refs #3749)";
}

int runCheckAiTestSoftWeightContract(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!aiTestSoftWeightContractPathInScope(rel)) {
      continue;
    }
    final reason = aiTestSoftWeightContractViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_test_soft_weight_contract: soft-weight wiring stays '
      'consolidated in the parameterized contract files.',
    );
    return 0;
  }
  logE(
    'check_ai_test_soft_weight_contract: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiTestSoftWeightContract(Directory.current.path));
}
