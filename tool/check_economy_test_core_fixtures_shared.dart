import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3836).
///
/// Forbid inline `Game(` construction in the 18 core economy test files that
/// must use shared builders from `colonizethis_economy_test_support`.
const _guardedRelativePaths = <String>{
  'packages/colonizethis_economy/test/build_cost_test.dart',
  'packages/colonizethis_economy/test/cost_check_test.dart',
  'packages/colonizethis_economy/test/economy/commodity_totals_test.dart',
  'packages/colonizethis_economy/test/economy/projected_cost_engine_test.dart',
  'packages/colonizethis_economy/test/economy/trade_cargo_capacity_test.dart',
  'packages/colonizethis_economy/test/economy_consumption_phases_test.dart',
  'packages/colonizethis_economy/test/economy_consumption_test.dart',
  'packages/colonizethis_economy/test/economy_extraction_test.dart',
  'packages/colonizethis_economy/test/economy_production_test.dart',
  'packages/colonizethis_economy/test/economy_riches_to_treasury_test.dart',
  'packages/colonizethis_economy/test/economy_tech_effects_test.dart',
  'packages/colonizethis_economy/test/game_lookup_helpers_test.dart',
  'packages/colonizethis_economy/test/sea_transport_test.dart',
  'packages/colonizethis_economy/test/trade_interception_scan_test.dart',
  'packages/colonizethis_economy/test/trade_interception_test.dart',
  'packages/colonizethis_economy/test/worker_action_cost_test.dart',
  'packages/colonizethis_economy/test/worker_economy_test.dart',
};

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');

String? economyTestCoreFixturesSharedViolationReason(String content) {
  if (_inlineGameConstructor.hasMatch(content)) {
    return 'use shared game builders from colonizethis_economy_test_support '
        'instead of inline Game(...) (Refs #3836)';
  }
  return null;
}

int runCheckEconomyTestCoreFixturesShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final violations = <String>[];
  for (final rel in _guardedRelativePaths) {
    final file = File(p.join(root, rel));
    if (!file.existsSync()) {
      continue;
    }
    final reason = economyTestCoreFixturesSharedViolationReason(
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_economy_test_core_fixtures_shared: no inline Game(...) violations.');
    return 0;
  }

  logE(
    'check_economy_test_core_fixtures_shared: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestCoreFixturesShared(Directory.current.path));
}
