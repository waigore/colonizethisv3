import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for economy / orchestrator satellite Game fixtures
/// (Refs #4310 Slice C).
const String economySatelliteSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/economy_satellite_test_support.dart';

/// Adopters that must import shared economy satellite fixtures.
const Set<String> economySatelliteSharedFixtureAdopterBasenames = {
  'domain_planner_orchestrator_castiron_peasant_recruit_test.dart',
  'economy_planner_cotton_weaving_gate_test.dart',
  'economy_planner_phase_plan_injection_test.dart',
  'phase_planner_economy_first_naval_transport_bootstrap_test.dart',
};

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

final RegExp _localSellerGameDecl = RegExp(r'Game\s+_sellerGame\b');
final RegExp _localCottonOnlyGameDecl = RegExp(r'Game\s+_cottonOnlyGame\b');
final RegExp _localBrokeAtPeaceGameDecl = RegExp(r'Game\s+_brokeAtPeaceGame\b');
final RegExp _localBootstrapGameDecl = RegExp(r'Game\s+_bootstrapGame\b');

bool _isEconomySatelliteAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return economySatelliteSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the economy satellite fixture gate.
bool aiEconomySatelliteSharedFixturesPathInScope(String slashPath) {
  return _isEconomySatelliteAdopterPath(slashPath.replaceAll('\\', '/'));
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiEconomySatelliteSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isEconomySatelliteAdopterPath(normalized)) {
    return null;
  }
  final basename = p.basename(normalized);
  if (basename == 'domain_planner_orchestrator_castiron_peasant_recruit_test.dart' &&
      _localSellerGameDecl.hasMatch(content)) {
    return 'redeclares local `_sellerGame`; import '
        '`economyCastIronSellerGame` from '
        '`$economySatelliteSharedFixturesSupportFile` (Refs #4310)';
  }
  if (basename == 'economy_planner_cotton_weaving_gate_test.dart' &&
      _localCottonOnlyGameDecl.hasMatch(content)) {
    return 'redeclares local `_cottonOnlyGame`; import '
        '`economyCottonOnlyGame` from '
        '`$economySatelliteSharedFixturesSupportFile` (Refs #4310)';
  }
  if (basename == 'economy_planner_phase_plan_injection_test.dart' &&
      _localBrokeAtPeaceGameDecl.hasMatch(content)) {
    return 'redeclares local `_brokeAtPeaceGame`; import '
        '`economyBrokeAtPeaceGame` from '
        '`$economySatelliteSharedFixturesSupportFile` (Refs #4310)';
  }
  if (basename ==
          'phase_planner_economy_first_naval_transport_bootstrap_test.dart' &&
      _localBootstrapGameDecl.hasMatch(content)) {
    return 'redeclares local `_bootstrapGame`; import '
        '`economyNavalBootstrapGame` from '
        '`$economySatelliteSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiEconomySatelliteTestSharedFixtures(
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
    'economy_satellite_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_economy_satellite_test_shared_fixtures: missing shared support '
      'file `$economySatelliteSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiEconomySatelliteSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_economy_satellite_test_shared_fixtures: no local economy '
      'satellite Game fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_economy_satellite_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiEconomySatelliteTestSharedFixtures(Directory.current.path));
}
