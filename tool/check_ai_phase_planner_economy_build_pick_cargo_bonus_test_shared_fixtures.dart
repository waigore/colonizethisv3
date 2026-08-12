import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String phasePlannerEconomyBuildPickCargoBonusSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'phase_planner_economy_build_pick_cargo_bonus_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String>
    phasePlannerEconomyBuildPickCargoBonusSharedFixtureAdopterBasenames = {
  'phase_planner_economy_build_pick_cargo_bonus_test.dart',
};

final RegExp _localBuildGameDecl = RegExp(r'Game\s+_buildGame\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return phasePlannerEconomyBuildPickCargoBonusSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiPhasePlannerEconomyBuildPickCargoBonusSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localBuildGameDecl.hasMatch(content)) {
    return 'redeclares local `_buildGame`; import '
        '`phasePlannerEconomyBuildPickCargoBonusGame` from '
        '`$phasePlannerEconomyBuildPickCargoBonusSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiPhasePlannerEconomyBuildPickCargoBonusTestSharedFixtures(
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
    'phase_planner_economy_build_pick_cargo_bonus_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_phase_planner_economy_build_pick_cargo_bonus_test_shared_fixtures: '
      'missing shared support file '
      '`$phasePlannerEconomyBuildPickCargoBonusSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiPhasePlannerEconomyBuildPickCargoBonusSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_phase_planner_economy_build_pick_cargo_bonus_test_shared_fixtures: '
      'no local economy build-pick cargo-bonus fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_phase_planner_economy_build_pick_cargo_bonus_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPhasePlannerEconomyBuildPickCargoBonusTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
