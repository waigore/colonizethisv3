import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for treasury satellite Game scaffolds
/// (Refs #4104 Slice A). Forecasting uses [treasuryPlannerTestGameWithStockpile]
/// from [treasurySatelliteForecastingSupportFile].
const String treasurySatelliteSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/planning/'
    'treasury_planner_satellite_support.dart';

const String treasurySatelliteForecastingSupportFile =
    'packages/colonizethis_ai/test/planning/'
    'treasury_planner_main_support.dart';

/// In-scope treasury satellite pin paths (Refs #4104).
const Set<String> treasurySatelliteSharedFixtureAdopters = <String>{
  'packages/colonizethis_ai/test/planning/'
      'treasury_planner_forecasting_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'treasury_planner_boycott_suppression_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'treasury_planner_supplier_castiron_source_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'treasury_planner_trade_deal_relation_boost_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'treasury_planner_offerable_fabric_test.dart',
};

final RegExp _localGameWithStockpileDecl = RegExp(
  r'Game\s+_gameWithStockpile\b',
);
final RegExp _localGameDecl = RegExp(r'Game\s+_game\b');

/// True when [slashPath] is a treasury satellite adopter pin.
bool aiTreasurySatelliteSharedFixturesPathInScope(String slashPath) {
  return treasurySatelliteSharedFixtureAdopters.contains(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation reason when an adopter redeclares a local treasury
/// satellite Game factory that must live in shared support.
String? aiTreasurySatelliteSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiTreasurySatelliteSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (normalized.endsWith('treasury_planner_forecasting_test.dart')) {
    if (_localGameWithStockpileDecl.hasMatch(content)) {
      return 'redeclares local `_gameWithStockpile`; import '
          '`treasuryPlannerTestGameWithStockpile` from '
          '`$treasurySatelliteForecastingSupportFile` (Refs #4104)';
    }
    return null;
  }
  if (_localGameDecl.hasMatch(content)) {
    return 'redeclares local `_game`; import the shared factory from '
        '`$treasurySatelliteSharedFixturesSupportFile` (Refs #4104)';
  }
  return null;
}

int runCheckAiTreasurySatelliteTestSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final satelliteSupport = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai',
    'test',
    'planning',
    'treasury_planner_satellite_support.dart',
  );
  final forecastingSupport = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai',
    'test',
    'planning',
    'treasury_planner_main_support.dart',
  );
  if (!File(satelliteSupport).existsSync()) {
    logE(
      'check_ai_treasury_satellite_test_shared_fixtures: missing shared '
      'support file `$treasurySatelliteSharedFixturesSupportFile`.',
    );
    return 1;
  }
  if (!File(forecastingSupport).existsSync()) {
    logE(
      'check_ai_treasury_satellite_test_shared_fixtures: missing shared '
      'support file `$treasurySatelliteForecastingSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiTreasurySatelliteSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_treasury_satellite_test_shared_fixtures: no local treasury '
      'satellite Game factory redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_treasury_satellite_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiTreasurySatelliteTestSharedFixtures(Directory.current.path),
  );
}
