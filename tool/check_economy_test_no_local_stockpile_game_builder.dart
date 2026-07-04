import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3831, #3856).
///
/// Forbid local stockpile-player game builders under
/// `packages/colonizethis_economy/test/**` when they duplicate the shared
/// test_support builder shape.
const _economyTestPrefix = 'packages/colonizethis_economy/test/';

final RegExp _forbiddenLocalGameBuilder = RegExp(
  r'^\s*Game\s+_?buildGame\s*\(',
  multiLine: true,
);

final RegExp _forbiddenLocalGameWithFactory = RegExp(
  r'^\s*Game\s+_gameWith\w*\s*\(',
  multiLine: true,
);

bool economyTestNoLocalStockpileGameBuilderPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_economyTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? economyTestLocalStockpileGameBuilderViolationReason(String content) {
  if (_forbiddenLocalGameBuilder.hasMatch(content)) {
    return 'use buildStockpilePlayerGame / buildTreasuryBidBudgetGame from '
        'colonizethis_economy_test_support instead (Refs #3831)';
  }
  if (_forbiddenLocalGameWithFactory.hasMatch(content)) {
    return 'use shared game builders from colonizethis_economy_test_support '
        'instead of local _gameWith* factories (Refs #3856)';
  }
  return null;
}

int runCheckEconomyTestNoLocalStockpileGameBuilder(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!economyTestNoLocalStockpileGameBuilderPathInScope(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    final reason = economyTestLocalStockpileGameBuilderViolationReason(content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_economy_test_no_local_stockpile_game_builder: no local builder '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_economy_test_no_local_stockpile_game_builder: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestNoLocalStockpileGameBuilder(Directory.current.path));
}
