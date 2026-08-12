import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for planning peace-collector Game / snapshot
/// fixtures (Refs #4310 Slice C).
const String planningPeaceCollectorsSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'planning_peace_collectors_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared peace-collector fixtures.
const Set<String> planningPeaceCollectorsSharedFixtureAdopterBasenames = {
  'planning_peace_collectors_test.dart',
  'planning_peace_collectors_gp_cases.dart',
  'planning_peace_collectors_non_gp_cases.dart',
};

final RegExp _localGameWithGpsDecl = RegExp(r'Game\s+_gameWithGps\b');
final RegExp _localSnapshotWithAtWarDecl =
    RegExp(r'AIWorldSnapshot\s+_snapshotWithAtWar\b');
final RegExp _localGameWithMinorsDecl = RegExp(r'Game\s+gameWithMinors\b');
final RegExp _localGameWithTribesDecl = RegExp(r'Game\s+gameWithTribes\b');
final RegExp _localGameWithMixedFactionsDecl =
    RegExp(r'Game\s+gameWithMixedFactions\b');

bool _isPlanningPeaceCollectorsAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return planningPeaceCollectorsSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the peace-collector fixture gate.
bool aiPlanningPeaceCollectorsSharedFixturesPathInScope(String slashPath) {
  return _isPlanningPeaceCollectorsAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiPlanningPeaceCollectorsSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isPlanningPeaceCollectorsAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithGpsDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithGps`; import '
        '`planningPeaceCollectorsGameWithGps` from '
        '`$planningPeaceCollectorsSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localSnapshotWithAtWarDecl.hasMatch(content)) {
    return 'redeclares local `_snapshotWithAtWar`; import '
        '`planningPeaceCollectorsSnapshotWithAtWar` from '
        '`$planningPeaceCollectorsSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameWithMinorsDecl.hasMatch(content)) {
    return 'redeclares local `gameWithMinors`; import '
        '`planningPeaceCollectorsGameWithMinors` from '
        '`$planningPeaceCollectorsSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameWithTribesDecl.hasMatch(content)) {
    return 'redeclares local `gameWithTribes`; import '
        '`planningPeaceCollectorsGameWithTribes` from '
        '`$planningPeaceCollectorsSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameWithMixedFactionsDecl.hasMatch(content)) {
    return 'redeclares local `gameWithMixedFactions`; import '
        '`planningPeaceCollectorsGameWithMixedFactions` from '
        '`$planningPeaceCollectorsSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiPlanningPeaceCollectorsTestSharedFixtures(
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
    'planning_peace_collectors_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_planning_peace_collectors_test_shared_fixtures: missing '
      'shared support file '
      '`$planningPeaceCollectorsSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPlanningPeaceCollectorsSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_planning_peace_collectors_test_shared_fixtures: no local '
      'planning peace-collector fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_planning_peace_collectors_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPlanningPeaceCollectorsTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
