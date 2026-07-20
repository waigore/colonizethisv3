import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for recruitment planner Game scaffolds
/// (Refs #4104 Slice A).
const String recruitmentPlannerSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/planning/'
    'recruitment_planner_test_support.dart';

/// In-scope recruitment planner pin paths (Refs #4104).
const Set<String> recruitmentPlannerSharedFixtureAdopters = <String>{
  'packages/colonizethis_ai/test/planning/recruitment_planner_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'recruitment_planner_paper_ledger_test.dart',
};

final RegExp _localGameWithDecl = RegExp(r'Game\s+_gameWith\b');

/// True when [slashPath] is a recruitment planner adopter pin.
bool aiRecruitmentPlannerSharedFixturesPathInScope(String slashPath) {
  return recruitmentPlannerSharedFixtureAdopters.contains(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation reason when an adopter redeclares local `_gameWith`.
String? aiRecruitmentPlannerSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiRecruitmentPlannerSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localGameWithDecl.hasMatch(content)) {
    return 'redeclares local `_gameWith`; import '
        '`recruitmentPlannerTestGameWith` from '
        '`$recruitmentPlannerSharedFixturesSupportFile` (Refs #4104)';
  }
  return null;
}

int runCheckAiRecruitmentPlannerTestSharedFixtures(
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
    'recruitment_planner_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_recruitment_planner_test_shared_fixtures: missing shared '
      'support file `$recruitmentPlannerSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiRecruitmentPlannerSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_recruitment_planner_test_shared_fixtures: no local '
      '`_gameWith` redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_recruitment_planner_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiRecruitmentPlannerTestSharedFixtures(Directory.current.path),
  );
}
