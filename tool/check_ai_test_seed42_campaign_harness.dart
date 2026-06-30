import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose `*_test.dart` sources must drive seed-42
/// Full-AI observer campaigns through the shared harness (Refs #3749 step 2).
const String _aiTestPathPrefix = 'packages/colonizethis_ai/test/';

/// Canonical shared observer-campaign harness entrypoint. New seed-42 observer
/// campaigns must call this instead of re-inlining the
/// `runInitGame(seed: 42)` -> handoff -> per-turn resolve loop.
const String seed42CampaignHarnessSymbol = 'runSeed42ObserverCampaign';

/// Shared harness support file (the single source of truth that legitimately
/// owns the inline loop) — always exempt.
const String _seed42CampaignHarnessFile =
    'packages/colonizethis_ai/test/support/seed42_observer_campaign.dart';

/// Seed-42 campaign init signature literal, e.g.
/// `runInitGame(config: GameSetupConfig(seed: 42))`. Tolerates whitespace
/// around `seed:` and `42`. The harness itself uses `GameSetupConfig(seed:
/// seed)` (parameter, not the `42` literal) so it never matches here.
final RegExp _seed42InitLiteral = RegExp(
  r'GameSetupConfig\(\s*seed:\s*42\s*\)',
);

/// Trusted-order turn-resolution call that closes the per-turn observer loop.
const String _trustedOrderResolveCall =
    'validateOrdersAndResolveTurnFromTrustedOrders';

/// Existing inline seed-42 observer campaigns grandfathered at the time the
/// harness landed (Refs #3749 step 2). These pre-date the shared harness and
/// are migrated incrementally; the gate freezes the set so **new** inline
/// seed-42 campaign loops are forbidden while migration of the existing files
/// to [seed42CampaignHarnessSymbol] proceeds as a follow-up. Diagnostics, perf
/// budget pins, and regression suites are intentionally allowlisted per
/// `SPEC/program/repo-lint.md`.
const Set<String> seed42CampaignHarnessAllowlist = <String>{
  'packages/colonizethis_ai/test/perf/seed42_first_turn_trade_enabled_wall_clock_budget_test.dart',
  'packages/colonizethis_ai/test/planning/seed42_expand_phase_first10turns_trace_test.dart',
  'packages/colonizethis_ai/test/planning/seed42_expand_phase_first25turns_field_army_trace_test.dart',
  'packages/colonizethis_ai/test/seed42_invadable_probe_test.dart',
  'packages/colonizethis_ai/test/seed42_observer_colonial_c0_diagnostic_test.dart',
  'packages/colonizethis_ai/test/seed42_observer_conquest_s7d_diagnostic_test.dart',
  'packages/colonizethis_ai/test/seed42_observer_nw_acquisition_chain_diagnostic_test.dart',
  'packages/colonizethis_ai/test/seed42_observer_world_market_diagnostic_test.dart',
  'packages/colonizethis_ai/test/seed42_observer_world_market_lock_recovery_diagnostic_test.dart',
};

/// True when the repo-relative [slashPath] is an in-scope AI package
/// `*_test.dart` source (not the harness support file itself).
bool aiTestSeed42HarnessPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_aiTestPathPrefix)) {
    return false;
  }
  if (normalized == _seed42CampaignHarnessFile) {
    return false;
  }
  return normalized.endsWith('_test.dart');
}

/// True when [content] contains an inline seed-42 Full-AI observer campaign
/// loop: the seed-42 campaign init literal plus the trusted-order turn
/// resolution call, and it does **not** delegate to the shared harness
/// ([seed42CampaignHarnessSymbol]).
bool aiTestSeed42HarnessContentIsInlineCampaign(String content) {
  if (content.contains(seed42CampaignHarnessSymbol)) {
    return false;
  }
  if (!_seed42InitLiteral.hasMatch(content)) {
    return false;
  }
  return content.contains(_trustedOrderResolveCall);
}

/// Returns a violation reason when the in-scope AI test file at repo-relative
/// [slashPath] (with [content]) re-introduces an inline seed-42 observer
/// campaign loop outside the allowlist, or `null` when compliant.
String? aiTestSeed42HarnessViolationReason(String slashPath, String content) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiTestSeed42HarnessPathInScope(normalized)) {
    return null;
  }
  if (seed42CampaignHarnessAllowlist.contains(normalized)) {
    return null;
  }
  if (!aiTestSeed42HarnessContentIsInlineCampaign(content)) {
    return null;
  }
  return "re-inlines a seed-42 Full-AI observer campaign loop "
      "(`GameSetupConfig(seed: 42)` + `$_trustedOrderResolveCall`); drive it "
      "through the shared `$seed42CampaignHarnessSymbol` harness "
      "(`$_seed42CampaignHarnessFile`) (Refs #3749)";
}

int runCheckAiTestSeed42CampaignHarness(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!aiTestSeed42HarnessPathInScope(rel)) {
      continue;
    }
    final reason = aiTestSeed42HarnessViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_test_seed42_campaign_harness: no inline seed-42 observer '
      'campaign violations.',
    );
    return 0;
  }
  logE(
    'check_ai_test_seed42_campaign_harness: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiTestSeed42CampaignHarness(Directory.current.path));
}
