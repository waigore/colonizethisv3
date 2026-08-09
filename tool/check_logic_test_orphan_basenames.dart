import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md, SPEC/program/logic-package-split-phase0.md
/// (Refs #4090 Slice E / AC3 + AC5).
///
/// Forbidden basenames are the pre-purge domain collisions that must not
/// reappear under `packages/colonizethis_logic/test/**`.

const String logicTestRelativeDir = 'packages/colonizethis_logic/test';

/// Basename collisions from #4090 Current behavior (AC3).
const Set<String> logicTestForbiddenOrphanBasenames = {
  'economy_production_test.dart',
  'build_cost_test.dart',
  'economy_consumption_test.dart',
  'economy_extraction_test.dart',
  'economy_riches_to_treasury_test.dart',
  'worker_action_cost_test.dart',
  'sea_transport_test.dart',
  'world_market_trade_order_suggester_test.dart',
  'world_market_trade_order_validator_test.dart',
  'province_lookup_test.dart',
  'minor_military_parity_test.dart',
  'tile_control_test.dart',
  'turn_resolution_result_test.dart',
};

int runCheckLogicTestOrphanBasenames(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
  Set<String> forbidden = logicTestForbiddenOrphanBasenames,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final testDir = Directory(p.join(repoRoot, logicTestRelativeDir));
  if (!testDir.existsSync()) {
    logE('check_logic_test_orphan_basenames: missing $logicTestRelativeDir');
    return 1;
  }

  final hits = <String>[];
  for (final entity in testDir.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    if (!entity.path.endsWith('.dart')) {
      continue;
    }
    final base = p.basename(entity.path);
    if (forbidden.contains(base)) {
      hits.add(p.relative(entity.path, from: repoRoot));
    }
  }

  if (hits.isEmpty) {
    logI(
      'check_logic_test_orphan_basenames: no forbidden collision basenames '
      '(Refs #4090 AC3/AC5).',
    );
    return 0;
  }

  logE(
    'check_logic_test_orphan_basenames: ${hits.length} forbidden basename(s) '
    'under $logicTestRelativeDir (Refs #4090):',
  );
  for (final hit in hits) {
    logE(' - $hit');
  }
  return 1;
}

void main() {
  exit(runCheckLogicTestOrphanBasenames(Directory.current.path));
}
