import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for Full AI planner Game fixtures (Refs #4310).
const String fullAiPlannerSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/full_ai_planner_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared Full AI planner fixtures.
const Set<String> fullAiPlannerSharedFixtureAdopterBasenames = {
  'full_ai_planner_test.dart',
  'full_ai_planner_determinism_test.dart',
};

final RegExp _localMinimalGameDecl = RegExp(r'Game\s+_minimalGame\b');
final RegExp _localScenarioGameDecl = RegExp(r'Game\s+_scenarioGame\b');

bool _isFullAiPlannerAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return fullAiPlannerSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the Full AI planner fixture gate.
bool aiFullAiPlannerSharedFixturesPathInScope(String slashPath) {
  return _isFullAiPlannerAdopterPath(slashPath.replaceAll('\\', '/'));
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiFullAiPlannerSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isFullAiPlannerAdopterPath(normalized)) {
    return null;
  }
  if (_localMinimalGameDecl.hasMatch(content)) {
    return 'redeclares local `_minimalGame`; import '
        '`fullAiPlannerMinimalGame` from '
        '`$fullAiPlannerSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localScenarioGameDecl.hasMatch(content)) {
    return 'redeclares local `_scenarioGame`; import '
        '`fullAiPlannerDeterminismScenarioGame` from '
        '`$fullAiPlannerSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiFullAiPlannerTestSharedFixtures(
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
    'full_ai_planner_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_full_ai_planner_test_shared_fixtures: missing shared support '
      'file `$fullAiPlannerSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiFullAiPlannerSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_full_ai_planner_test_shared_fixtures: no local Full AI planner '
      'fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_full_ai_planner_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiFullAiPlannerTestSharedFixtures(Directory.current.path));
}
