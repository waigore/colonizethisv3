import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Tests under this prefix that invoke [worldMarketTurnPhaseHandler] directly
/// must import `test/support/world_market_test_support.dart` (Refs #3876).
const _scopedPrefix = 'packages/colonizethis_turn/test/turn/';

const _supportImport = "import '../support/world_market_test_support.dart';";

const _allowlistedBasenames = {
  'world_market_test_support.dart',
};

/// Matches direct handler invocation, not group-title string literals.
final RegExp _directWorldMarketHandlerUse = RegExp(
  r'\bworldMarketTurnPhaseHandler\s*[\(,]',
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
    return null;
  }
  if (content.contains(_supportImport)) {
    return null;
  }
  return 'calls `worldMarketTurnPhaseHandler` directly; import '
      '`test/support/world_market_test_support.dart` and prefer '
      '`runWorldMarketPhase` / `runWorldMarketPhasePipeline` (Refs #3876)';
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
