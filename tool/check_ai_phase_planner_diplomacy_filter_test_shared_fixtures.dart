import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for phase-diplomacy filter Game scaffolds
/// (Refs #4104 Slice A).
const String phasePlannerDiplomacyFilterSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'phase_planner_diplomacy_filter_test_support.dart';

/// In-scope phase-diplomacy filter pin paths (Refs #4104).
const Set<String> phasePlannerDiplomacyFilterSharedFixtureAdopters =
    <String>{
  'packages/colonizethis_ai/test/planning/'
      'phase_planner_diplomacy_ow_bonus_scaling_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'phase_planner_diplomacy_declare_war_nw_suppression_test.dart',
};

final RegExp _localBuildGameDecl = RegExp(r'Game\s+_buildGame\b');

/// True when [slashPath] is a phase-diplomacy filter adopter pin.
bool aiPhasePlannerDiplomacyFilterSharedFixturesPathInScope(String slashPath) {
  return phasePlannerDiplomacyFilterSharedFixtureAdopters.contains(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation reason when an adopter redeclares local `_buildGame`.
String? aiPhasePlannerDiplomacyFilterSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiPhasePlannerDiplomacyFilterSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localBuildGameDecl.hasMatch(content)) {
    return 'redeclares local `_buildGame`; import '
        '`buildPhasePlannerDiplomacyOwBonusScalingGame` / '
        '`buildPhasePlannerDiplomacyNwSuppressionGame` from '
        '`$phasePlannerDiplomacyFilterSharedFixturesSupportFile` '
        '(Refs #4104)';
  }
  return null;
}

int runCheckAiPhasePlannerDiplomacyFilterTestSharedFixtures(
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
    'phase_planner_diplomacy_filter_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_phase_planner_diplomacy_filter_test_shared_fixtures: missing '
      'shared support file '
      '`$phasePlannerDiplomacyFilterSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPhasePlannerDiplomacyFilterSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_phase_planner_diplomacy_filter_test_shared_fixtures: no local '
      '`_buildGame` redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_phase_planner_diplomacy_filter_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPhasePlannerDiplomacyFilterTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
