import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for observer goal phase transition boundary
/// Game / snapshot fixtures (Refs #4310 Slice C).
const String observerGoalPhaseTransitionBoundarySharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'observer_goal_phase_transition_boundary_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared transition-boundary fixtures.
const Set<String> observerGoalPhaseTransitionBoundarySharedFixtureAdopterBasenames =
    {
  'observer_goal_phase_transition_boundary_test.dart',
  'observer_goal_phase_transition_boundary_phase_cases.dart',
  'observer_goal_phase_transition_boundary_orchestrator_cases.dart',
};

final RegExp _localScenarioGameDecl = RegExp(r'Game\s+_scenarioGame\b');

bool _isObserverGoalPhaseTransitionBoundaryAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return observerGoalPhaseTransitionBoundarySharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the transition-boundary fixture gate.
bool aiObserverGoalPhaseTransitionBoundarySharedFixturesPathInScope(
  String slashPath,
) {
  return _isObserverGoalPhaseTransitionBoundaryAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiObserverGoalPhaseTransitionBoundarySharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isObserverGoalPhaseTransitionBoundaryAdopterPath(normalized)) {
    return null;
  }
  if (_localScenarioGameDecl.hasMatch(content)) {
    return 'redeclares local `_scenarioGame`; import '
        '`observerGoalPhaseTransitionBoundaryGameAtQuota` / '
        '`observerGoalPhaseTransitionBoundaryGameJustBelowQuota` from '
        '`$observerGoalPhaseTransitionBoundarySharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiObserverGoalPhaseTransitionBoundaryTestSharedFixtures(
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
    'observer_goal_phase_transition_boundary_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_observer_goal_phase_transition_boundary_test_shared_fixtures: '
      'missing shared support file '
      '`$observerGoalPhaseTransitionBoundarySharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiObserverGoalPhaseTransitionBoundarySharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_observer_goal_phase_transition_boundary_test_shared_fixtures: '
      'no local transition-boundary fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_observer_goal_phase_transition_boundary_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiObserverGoalPhaseTransitionBoundaryTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
