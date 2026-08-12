import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String expandPhasePlannerFocusMinorTargetSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'expand_phase_planner_focus_minor_target_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> expandPhasePlannerFocusMinorTargetSharedFixtureAdopterBasenames =
    {
  'expand_phase_planner_focus_minor_target_early_cases.dart',
  'expand_phase_planner_focus_minor_target_later_cases.dart',
};

final RegExp _localFocusMinorGameDecl =
    RegExp(r'Game\s+_focusMinorGame\b|Game\s+expandPhasePlannerFocusMinorTargetGame\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return expandPhasePlannerFocusMinorTargetSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiExpandPhasePlannerFocusMinorTargetSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localFocusMinorGameDecl.hasMatch(content)) {
    return 'redeclares local focus-minor Game factory; import '
        '`expandPhasePlannerFocusMinorTargetGame` from '
        '`$expandPhasePlannerFocusMinorTargetSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiExpandPhasePlannerFocusMinorTargetTestSharedFixtures(
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
    'expand_phase_planner_focus_minor_target_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_expand_phase_planner_focus_minor_target_test_shared_fixtures: '
      'missing shared support file '
      '`$expandPhasePlannerFocusMinorTargetSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiExpandPhasePlannerFocusMinorTargetSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_expand_phase_planner_focus_minor_target_test_shared_fixtures: '
      'no local focus-minor fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_expand_phase_planner_focus_minor_target_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiExpandPhasePlannerFocusMinorTargetTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
