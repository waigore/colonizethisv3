import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3823).
///
/// Forbid new package-local world-market / FRR test-support files under
/// `packages/colonizethis_economy/test/**`. Canonical home is
/// `colonizethis_economy_test_support`.
const String _economyTestPathPrefix = 'packages/colonizethis_economy/test/';

final RegExp _forbiddenSupportBasename = RegExp(
  r'^(world_market_.*|first_right_.*)_test_support\.dart$',
);

bool economyTestNoLocalWorldMarketSupportPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_economyTestPathPrefix);
}

String? economyTestLocalWorldMarketSupportViolationReason(String fileName) {
  if (_forbiddenSupportBasename.hasMatch(fileName)) {
    return 'package-local `$fileName` must live in '
        '`colonizethis_economy_test_support` instead (Refs #3823)';
  }
  return null;
}

int runCheckEconomyTestNoLocalWorldMarketSupport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!economyTestNoLocalWorldMarketSupportPathInScope(rel)) {
      continue;
    }
    final reason = economyTestLocalWorldMarketSupportViolationReason(
      p.basename(rel),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_economy_test_no_local_world_market_support: no local support '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_economy_test_no_local_world_market_support: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestNoLocalWorldMarketSupport(Directory.current.path));
}
