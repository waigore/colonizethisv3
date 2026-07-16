import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Tests under this prefix that invoke [worldMarketTurnPhaseHandler] directly
/// must import support and call a shared runner (Refs #3876 / #4039).
const _scopedPrefix = 'packages/colonizethis_turn/test/turn/';

const _supportImport = "import '../support/world_market_test_support.dart';";

/// Pure unit suites for world-market helpers (not phase-handler wiring).
const _allowlistedBasenames = {
  'world_market_test_support.dart',
  'world_market_phase_orders_helpers_test.dart',
  'world_market_phase_completed_trade_pairs_test.dart',
  'world_market_phase_deals_subsidy_test.dart',
};

/// Matches direct handler invocation, not group-title string literals.
final RegExp _directWorldMarketHandlerUse = RegExp(
  r'\bworldMarketTurnPhaseHandler\s*[\(,]',
);

/// Shared runners / specialized wrappers that drive the phase handler.
final RegExp _sharedWorldMarketRunnerUse = RegExp(
  r'\b(?:runWorldMarketPhase(?:Pipeline)?(?:From)?|'
  r'runWorldMarketFrrCreditPhase|runTreasuryClampPhase|'
  r'runWorldMarketTradePhase)\s*\(',
);

bool turnWorldMarketTestSupportPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_scopedPrefix)) {
    return false;
  }
  if (normalized.startsWith('packages/colonizethis_turn/test/support/')) {
    return false;
  }
  return normalized.contains('world_market');
}

String? turnWorldMarketTestSupportImportViolationReason(
  String fileName,
  String content,
) {
  if (_allowlistedBasenames.contains(fileName)) {
    return null;
  }
  if (!_directWorldMarketHandlerUse.hasMatch(content)) {
    // Phase-handler integration files (basename contains `_phase_`) must
    // drive the phase via a shared runner even when they never spell the
    // handler symbol (group titles alone do not count as invocation).
    if (fileName.contains('_phase_') &&
        !_sharedWorldMarketRunnerUse.hasMatch(content)) {
      return 'phase-handler suite must call `runWorldMarketPhase` / '
          '`runWorldMarketPhasePipeline` (or a support wrapper that does) '
          '(Refs #4039)';
    }
    return null;
  }
  if (!content.contains(_supportImport)) {
    return 'calls `worldMarketTurnPhaseHandler` directly; import '
        '`test/support/world_market_test_support.dart` and prefer '
        '`runWorldMarketPhase` / `runWorldMarketPhasePipeline` (Refs #3876)';
  }
  if (!_sharedWorldMarketRunnerUse.hasMatch(content)) {
    return 'calls `worldMarketTurnPhaseHandler` directly; prefer '
        '`runWorldMarketPhase` / `runWorldMarketPhasePipeline` (or a '
        'support wrapper) rather than local handler+pipeline wiring '
        '(Refs #4039)';
  }
  return null;
}

int runCheckTurnWorldMarketTestSupport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnWorldMarketTestSupportPathInScope(rel)) {
      continue;
    }
    final reason = turnWorldMarketTestSupportImportViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_turn_world_market_test_support: no direct handler violations.',
    );
    return 0;
  }
  logE(
    'check_turn_world_market_test_support: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnWorldMarketTestSupport(Directory.current.path));
}
