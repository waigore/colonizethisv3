import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3831).
///
/// Guards the shared GP-treasury roll-up result helper beside
/// `gp_treasury_credit_accumulator.dart`. Both `first_right_credits.dart` and
/// `purchased_tile_riches.dart` must reference `GpTreasuryCreditRollup`.
const _targetRelativePaths = <String>[
  'packages/colonizethis_economy/lib/src/economy/world_market/first_right_credits.dart',
  'packages/colonizethis_economy/lib/src/economy/world_market/purchased_tile_riches.dart',
];

const _requiredSymbol = 'GpTreasuryCreditRollup';

void main() {
  exit(runCheckEconomyGpTreasuryRollupShared(Directory.current.path));
}

int runCheckEconomyGpTreasuryRollupShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final violations = <String>[];

  for (final relative in _targetRelativePaths) {
    final file = File(p.join(root, relative));
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    if (!content.contains(_requiredSymbol)) {
      violations.add(
        '$relative: missing reference to shared $_requiredSymbol',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_economy_gp_treasury_rollup_shared: passed.');
    return 0;
  }

  logE(
    'check_economy_gp_treasury_rollup_shared: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> findEconomyGpTreasuryRollupSharedViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <String>[];
  for (final relative in _targetRelativePaths) {
    final content = sourcesByPath[relative];
    if (content == null) continue;
    if (!content.contains(_requiredSymbol)) {
      violations.add('$relative: missing $_requiredSymbol');
    }
  }
  return violations;
}
