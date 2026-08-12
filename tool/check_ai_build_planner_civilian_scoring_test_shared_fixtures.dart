import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String buildPlannerCivilianScoringSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'build_planner_civilian_scoring_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> buildPlannerCivilianScoringSharedFixtureAdopterBasenames = {
  'build_planner_civilian_scoring_test.dart',
};

final RegExp _localGameDecl = RegExp(r'Game\s+_game\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return buildPlannerCivilianScoringSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiBuildPlannerCivilianScoringSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameDecl.hasMatch(content)) {
    return 'redeclares local `_game`; import '
        '`buildPlannerCivilianScoringGame` from '
        '`$buildPlannerCivilianScoringSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiBuildPlannerCivilianScoringTestSharedFixtures(
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
    'build_planner_civilian_scoring_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_build_planner_civilian_scoring_test_shared_fixtures: missing '
      'shared support file '
      '`$buildPlannerCivilianScoringSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiBuildPlannerCivilianScoringSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_build_planner_civilian_scoring_test_shared_fixtures: no local '
      'build-planner civilian-scoring fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_build_planner_civilian_scoring_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiBuildPlannerCivilianScoringTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
