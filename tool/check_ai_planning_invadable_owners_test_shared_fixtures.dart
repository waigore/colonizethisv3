import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for planning invadable-owner Game / snapshot
/// fixtures (Refs #4310 Slice C).
const String planningInvadableOwnersSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'planning_invadable_owners_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared invadable-owner fixtures.
const Set<String> planningInvadableOwnersSharedFixtureAdopterBasenames = {
  'planning_invadable_owners_test.dart',
  'planning_invadable_owners_predicate_cases.dart',
  'planning_invadable_owners_wiring_cases.dart',
};

final RegExp _localGameWithGpsDecl = RegExp(r'Game\s+_gameWithGps\b');
final RegExp _localGameWithTwoMinorsDecl =
    RegExp(r'Game\s+gameWithTwoMinors\b');

bool _isPlanningInvadableOwnersAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return planningInvadableOwnersSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the invadable-owner fixture gate.
bool aiPlanningInvadableOwnersSharedFixturesPathInScope(String slashPath) {
  return _isPlanningInvadableOwnersAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiPlanningInvadableOwnersSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isPlanningInvadableOwnersAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithGpsDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithGps`; import '
        '`planningInvadableOwnersGameWithGps` from '
        '`$planningInvadableOwnersSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameWithTwoMinorsDecl.hasMatch(content)) {
    return 'redeclares local `gameWithTwoMinors`; import '
        '`planningInvadableOwnersGameWithTwoMinors` from '
        '`$planningInvadableOwnersSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiPlanningInvadableOwnersTestSharedFixtures(
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
    'planning_invadable_owners_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_planning_invadable_owners_test_shared_fixtures: missing '
      'shared support file '
      '`$planningInvadableOwnersSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPlanningInvadableOwnersSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_planning_invadable_owners_test_shared_fixtures: no local '
      'planning invadable-owner fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_planning_invadable_owners_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPlanningInvadableOwnersTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
