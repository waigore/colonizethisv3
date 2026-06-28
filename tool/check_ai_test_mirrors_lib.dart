import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the AI package test tree (Refs #3717).
///
/// AI production code lives under `lib/src/{perception,planning,social,
/// tactical,util}/`; the testing rule (`colonizethis-testing.mdc`) mandates
/// that `test/` mirrors `lib/`. This gate keeps the AI test tree mirrored by
/// forbidding `*_test.dart` sources directly at the `test/` root: every AI
/// unit test must live in a subdirectory that mirrors its owning `lib/src/`
/// subtree (for example `test/planning/`), rather than flat in `test/`.
const String _aiTestRootPrefix = 'packages/colonizethis_ai/test/';

/// Documented allowlist of `*_test.dart` files that legitimately remain at the
/// `test/` root because they do not mirror a single `lib/src/` source file.
///
/// Two categories are permitted:
/// 1. **Package-level surface tests** that exercise the public barrel / DI
///    exports (`lib/colonizethis_ai.dart`), not a `lib/src/` unit.
/// 2. **Cross-cutting integration / diagnostic tests** (the `seed42_*` and
///    `observer_*` families plus `full_ai_*`) that drive whole-AI / observer
///    runs and assert end-to-end behaviour rather than a single unit.
///
/// New entries must be justified in the PR/issue (Refs #3717): a regular unit
/// test for a `lib/src/<subtree>/<file>.dart` source belongs under
/// `test/<subtree>/`, not on this list.
const Set<String> aiTestMirrorsLibAllowlist = <String>{
  // Package-level surface (public barrel / DI exports).
  'ai_config_test.dart',
  'ai_di_export_test.dart',
  'seed_bundle_test.dart',
  // Cross-cutting integration / diagnostic (whole-AI / observer runs).
  'full_ai_no_order_engine_validate_test.dart',
  'observer_conquest_geography_seed42_test.dart',
  'seed42_gp3_gp4_war_activity_test.dart',
  'seed42_gp4_war_focus_test.dart',
  'seed42_growth_stage_conquest_regression_test.dart',
  'seed42_invadable_probe_test.dart',
  'seed42_nw_invadable_diag_test.dart',
  'seed42_observer_colonial_c0_diagnostic_test.dart',
  'seed42_observer_colonial_phase_entry_budget_test.dart',
  'seed42_observer_colonial_regression_test.dart',
  'seed42_observer_conquest_regression_test.dart',
  'seed42_observer_conquest_s7d_diagnostic_test.dart',
  'seed42_observer_nw_acquisition_chain_diagnostic_test.dart',
  'seed42_observer_nw_lock_recovery_declare_war_regression_test.dart',
  'seed42_observer_treasury_planner_trade_emission_test.dart',
  'seed42_observer_world_market_diagnostic_test.dart',
  'seed42_observer_world_market_lock_recovery_diagnostic_test.dart',
  'seed42_observer_world_market_lock_recovery_regression_test.dart',
  'seed42_s7d_feedstock_helpers_test.dart',
};

/// True when the repo-relative [slashPath] is under the AI package `test/`.
bool aiTestMirrorsLibPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_aiTestRootPrefix);
}

/// Returns a violation reason when the AI test source at repo-relative
/// [slashPath] is a `*_test.dart` sitting directly in the `test/` root (no
/// mirroring subdirectory) and not present in [aiTestMirrorsLibAllowlist], or
/// `null` when the file is nested in a subdirectory (compliant), allowlisted,
/// not a test file, or out of scope.
///
/// A loose root test is one whose remainder after the
/// `packages/colonizethis_ai/test/` prefix contains no further path separator
/// (for example `test/war_desire_score_test.dart`). Nested tests such as
/// `test/planning/war_desire_score_test.dart` are compliant. Non-`_test.dart`
/// scaffolding helpers at the root are out of scope here (governed by
/// `repo.ai_test_no_duplicate_scaffolding`).
String? aiTestMirrorsLibViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiTestRootPrefix)) {
    return null;
  }
  final remainder = normalized.substring(_aiTestRootPrefix.length);
  if (remainder.isEmpty || remainder.contains('/')) {
    return null;
  }
  if (!remainder.endsWith('_test.dart')) {
    return null;
  }
  if (aiTestMirrorsLibAllowlist.contains(remainder)) {
    return null;
  }
  return 'lives directly in `test/`; move it under a subdirectory that mirrors '
      '`lib/src/` (for example `test/planning/`) per the testing-rule '
      '`test/`-mirrors-`lib/` policy, or add it to the documented allowlist if '
      'it is a package-level/integration test (Refs #3717)';
}

int runCheckAiTestMirrorsLib(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!aiTestMirrorsLibPathInScope(rel)) {
      continue;
    }
    final reason = aiTestMirrorsLibViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_ai_test_mirrors_lib: no flat-root AI test sources.');
    return 0;
  }
  logE('check_ai_test_mirrors_lib: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiTestMirrorsLib(Directory.current.path));
}
