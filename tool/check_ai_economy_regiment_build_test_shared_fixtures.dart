import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for economy regiment-build production pins
/// (Refs #3972).
const String _economyRegimentBuildTestPathPrefix =
    'packages/colonizethis_ai/test/planning/'
    'economy_planner_regiment_build';

/// Canonical shared support library for economy regiment-build Game factories.
const String economyRegimentBuildSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/planning/'
    'economy_planner_regiment_build_input_support.dart';

/// Forbidden local Game builders that must live in the shared support library.
final RegExp _localRegimentRebuildGameDecl = RegExp(
  r'Game\s+_regimentRebuildProductionGame\b',
);
final RegExp _localCastIronImprovementGameDecl = RegExp(
  r'Game\s+_castIronImprovementInputGame\b',
);
final RegExp _localSupplierCastIronGameDecl = RegExp(
  r'Game\s+_supplierCastIronSourceGame\b',
);
final RegExp _localCastIronFeedstockGameDecl = RegExp(
  r'Game\s+_castIronFeedstockCoavailabilityGame\b',
);
final RegExp _localCastIronStagingGameDecl = RegExp(
  r'Game\s+_castIronStagingNoFabricGateGame\b',
);
final RegExp _localCastIronLabourGameDecl = RegExp(
  r'Game\s+_castIronLabourPeasantRecruitFabricStagingGame\b',
);

/// True when the repo-relative [slashPath] is an in-scope economy regiment-build
/// pin (not the shared support library itself).
bool aiEconomyRegimentBuildSharedFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_economyRegimentBuildTestPathPrefix)) {
    return false;
  }
  if (normalized.endsWith('_support.dart')) {
    return false;
  }
  return normalized.endsWith('_test.dart') ||
      normalized.endsWith('_cases.dart');
}

/// Returns a violation reason when [content] redeclares a local economy
/// regiment-build Game factory that must live in the shared support library,
/// or `null` when compliant.
String? aiEconomyRegimentBuildSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiEconomyRegimentBuildSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localRegimentRebuildGameDecl.hasMatch(content)) {
    return 'redeclares local `_regimentRebuildProductionGame`; import '
        '`regimentRebuildProductionGame` from '
        '`$economyRegimentBuildSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localCastIronImprovementGameDecl.hasMatch(content)) {
    return 'redeclares local `_castIronImprovementInputGame`; import '
        '`castIronImprovementInputGame` from '
        '`$economyRegimentBuildSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localSupplierCastIronGameDecl.hasMatch(content)) {
    return 'redeclares local `_supplierCastIronSourceGame`; import '
        '`supplierCastIronSourceGame` from '
        '`$economyRegimentBuildSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localCastIronFeedstockGameDecl.hasMatch(content)) {
    return 'redeclares local `_castIronFeedstockCoavailabilityGame`; import '
        '`castIronFeedstockCoavailabilityGame` from '
        '`$economyRegimentBuildSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localCastIronStagingGameDecl.hasMatch(content)) {
    return 'redeclares local `_castIronStagingNoFabricGateGame`; import '
        '`castIronStagingNoFabricGateGame` from '
        '`$economyRegimentBuildSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localCastIronLabourGameDecl.hasMatch(content)) {
    return 'redeclares local `_castIronLabourPeasantRecruitFabricStagingGame`; '
        'import `castIronLabourPeasantRecruitFabricStagingGame` from '
        '`$economyRegimentBuildSharedFixturesSupportFile` (Refs #3972)';
  }
  return null;
}

int runCheckAiEconomyRegimentBuildTestSharedFixtures(
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
    'planning',
    'economy_planner_regiment_build_input_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_economy_regiment_build_test_shared_fixtures: missing shared '
      'support file `$economyRegimentBuildSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiEconomyRegimentBuildSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_economy_regiment_build_test_shared_fixtures: no local '
      'economy regiment-build Game factory redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_economy_regiment_build_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiEconomyRegimentBuildTestSharedFixtures(Directory.current.path),
  );
}
