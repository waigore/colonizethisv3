import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for domain-planner orchestrator integration pins
/// that must import shared OW-quota fixtures (Refs #3941).
const String _orchestratorTestPathPrefix =
    'packages/colonizethis_ai/test/planning/domain_planner_orchestrator_';

/// Canonical shared support library that owns
/// [kGp1OwProvincesBelowQuota] / [kGp1OwProvincesAtQuota].
const String orchestratorSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'domain_planner_orchestrator_test_support.dart';

/// Forbidden local below-quota OW province list declarations in orchestrator
/// pins. After the shared harness lands, every pin must import
/// `kGp1OwProvincesBelowQuota` instead of re-copying the list.
final RegExp _localBelowQuotaConst = RegExp(
  r'const\s+List<String>\s+_gp1OwProvincesBelowQuota\b',
);

/// Forbidden local at-quota OW province list declarations.
final RegExp _localAtQuotaConst = RegExp(
  r'const\s+List<String>\s+_gp1OwProvincesAtQuota\b',
);

/// Forbidden bare `_gp1OwProvinces` copies (COLONIAL / DEVELOP two-GP peace
/// pins historically used this name for the shared at-quota set).
final RegExp _localBareGp1OwProvincesConst = RegExp(
  r'const\s+List<String>\s+_gp1OwProvinces\b',
);

/// Forbidden local EXPAND two-GP local `_gp1Provinces` copies; use
/// [kGp1OwProvincesExpandTwoGp] instead (Refs #3941).
final RegExp _localExpandTwoGpProvincesConst = RegExp(
  r'const\s+List<String>\s+_gp1Provinces\b',
);

/// Forbidden local minor-war at-war EXPAND snapshot clones; use
/// [buildOrchestratorExpandMinorWarAtWarSnapshot] (Refs #3997).
final RegExp _localExpandMinorWarAtWarSnapshotFn = RegExp(
  r'AIWorldSnapshot\s+_expandSnapshot\s*\(\s*\)\s*\{',
);

/// True when [content] uses a Game builder that pairs with the shared
/// minor-war at-war snapshot (those pins must not redeclare it locally).
bool _usesExpandMinorWarAtWarSnapshotPairing(String content) {
  return content.contains('buildOrchestratorExpandMinorWarScenarioGame') ||
      content.contains('buildOrchestratorPendingCostTradeScenarioGame');
}

/// True when the repo-relative [slashPath] is an in-scope orchestrator
/// `*_test.dart` (not the shared support library).
bool aiOrchestratorSharedFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_orchestratorTestPathPrefix)) {
    return false;
  }
  return normalized.endsWith('_test.dart');
}

/// Returns a violation reason when [content] redeclares a local OW-quota
/// province list that must live in the shared support library, or `null`
/// when compliant.
String? aiOrchestratorSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiOrchestratorSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localBelowQuotaConst.hasMatch(content)) {
    return 'redeclares local `_gp1OwProvincesBelowQuota`; import '
        '`kGp1OwProvincesBelowQuota` from '
        '`$orchestratorSharedFixturesSupportFile` (Refs #3941)';
  }
  if (_localAtQuotaConst.hasMatch(content)) {
    return 'redeclares local `_gp1OwProvincesAtQuota`; import '
        '`kGp1OwProvincesAtQuota` from '
        '`$orchestratorSharedFixturesSupportFile` (Refs #3941)';
  }
  if (_localBareGp1OwProvincesConst.hasMatch(content)) {
    return 'redeclares local `_gp1OwProvinces`; import '
        '`kGp1OwProvincesAtQuota` (or the phase-appropriate shared list) from '
        '`$orchestratorSharedFixturesSupportFile` (Refs #3941)';
  }
  if (_localExpandTwoGpProvincesConst.hasMatch(content)) {
    return 'redeclares local `_gp1Provinces`; import '
        '`kGp1OwProvincesExpandTwoGp` from '
        '`$orchestratorSharedFixturesSupportFile` (Refs #3941)';
  }
  if (_usesExpandMinorWarAtWarSnapshotPairing(content) &&
      _localExpandMinorWarAtWarSnapshotFn.hasMatch(content)) {
    return 'redeclares local `_expandSnapshot`; call '
        '`buildOrchestratorExpandMinorWarAtWarSnapshot` from '
        '`$orchestratorSharedFixturesSupportFile` (Refs #3997)';
  }
  return null;
}

int runCheckAiOrchestratorTestSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportPath = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai',
    'test',
    'support',
    'domain_planner_orchestrator_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_orchestrator_test_shared_fixtures: missing shared support '
      'file `$orchestratorSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiOrchestratorSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_orchestrator_test_shared_fixtures: no local OW-quota '
      'fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_orchestrator_test_shared_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiOrchestratorTestSharedFixtures(Directory.current.path));
}
