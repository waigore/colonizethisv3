import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for phase-planner dispatch COLONIAL Games
/// (Refs #3977).
const String colonialPhaseDispatchSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'colonial_phase_planner_test_support.dart';

/// In-scope dispatch pin path.
const String colonialPhaseDispatchTestPath =
    'packages/colonizethis_ai/test/planning/'
    'phase_planner_dispatch_test.dart';

final RegExp _localColonialLiteGameDecl = RegExp(r'Game\s+_colonialLiteGame\b');
final RegExp _localColonialGameDecl = RegExp(r'Game\s+_colonialGame\b');

/// True when [slashPath] is the phase-planner dispatch pin.
bool aiColonialPhaseDispatchSharedFixturesPathInScope(String slashPath) {
  return slashPath.replaceAll('\\', '/') == colonialPhaseDispatchTestPath;
}

/// Returns a violation reason when dispatch redeclares colonial Game clones.
String? aiColonialPhaseDispatchSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiColonialPhaseDispatchSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localColonialLiteGameDecl.hasMatch(content)) {
    return 'redeclares local `_colonialLiteGame`; import '
        '`buildPhasePlannerDispatchColonialLiteGame` from '
        '`$colonialPhaseDispatchSharedFixturesSupportFile` (Refs #3977)';
  }
  if (_localColonialGameDecl.hasMatch(content)) {
    return 'redeclares local `_colonialGame`; import '
        '`buildPhasePlannerDispatchColonialGame` from '
        '`$colonialPhaseDispatchSharedFixturesSupportFile` (Refs #3977)';
  }
  return null;
}

int runCheckAiColonialPhaseDispatchTestSharedFixtures(
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
    'colonial_phase_planner_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_colonial_phase_dispatch_test_shared_fixtures: missing '
      'shared support file '
      '`$colonialPhaseDispatchSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiColonialPhaseDispatchSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_colonial_phase_dispatch_test_shared_fixtures: no local '
      'dispatch colonial Game redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_colonial_phase_dispatch_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiColonialPhaseDispatchTestSharedFixtures(Directory.current.path),
  );
}
