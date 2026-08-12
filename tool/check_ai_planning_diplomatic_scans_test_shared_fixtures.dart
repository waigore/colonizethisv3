import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const String planningDiplomaticScansSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'planning_diplomatic_scans_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> planningDiplomaticScansSharedFixtureAdopterBasenames = {
  'planning_diplomatic_scans_test.dart',
};

final RegExp _localGameWithEventsDecl = RegExp(r'Game\s+_gameWithEvents\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return planningDiplomaticScansSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

String? aiPlanningDiplomaticScansSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithEventsDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithEvents`; import '
        '`planningDiplomaticScansGameWithEvents` from '
        '`$planningDiplomaticScansSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiPlanningDiplomaticScansTestSharedFixtures(
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
    'planning_diplomatic_scans_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_planning_diplomatic_scans_test_shared_fixtures: missing '
      'shared support file '
      '`$planningDiplomaticScansSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPlanningDiplomaticScansSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_planning_diplomatic_scans_test_shared_fixtures: no local '
      'planning-diplomatic-scans fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_planning_diplomatic_scans_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPlanningDiplomaticScansTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
