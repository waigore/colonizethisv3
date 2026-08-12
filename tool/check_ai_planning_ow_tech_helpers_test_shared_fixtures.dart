import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for planning OW / tech helper Game fixtures
/// (Refs #4310 Slice C).
const String planningOwTechHelpersSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'planning_ow_tech_helpers_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared OW / tech helper fixtures.
const Set<String> planningOwTechHelpersSharedFixtureAdopterBasenames = {
  'planning_ow_tech_helpers_test.dart',
};

final RegExp _localGameOwningDecl = RegExp(r'Game\s+_gameOwning\b');
final RegExp _localGameWithTechsDecl = RegExp(r'Game\s+_gameWithTechs\b');
final RegExp _localGameWithExhaustedGpDecl =
    RegExp(r'Game\s+_gameWithExhaustedGp\b');

bool _isPlanningOwTechHelpersAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return planningOwTechHelpersSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the OW / tech helper fixture gate.
bool aiPlanningOwTechHelpersSharedFixturesPathInScope(String slashPath) {
  return _isPlanningOwTechHelpersAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiPlanningOwTechHelpersSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isPlanningOwTechHelpersAdopterPath(normalized)) {
    return null;
  }
  if (_localGameOwningDecl.hasMatch(content)) {
    return 'redeclares local `_gameOwning`; import '
        '`planningOwTechHelpersGameOwning` from '
        '`$planningOwTechHelpersSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameWithTechsDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithTechs`; import '
        '`planningOwTechHelpersGameWithTechs` from '
        '`$planningOwTechHelpersSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameWithExhaustedGpDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithExhaustedGp`; import '
        '`planningOwTechHelpersGameWithExhaustedGp` from '
        '`$planningOwTechHelpersSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiPlanningOwTechHelpersTestSharedFixtures(
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
    'planning_ow_tech_helpers_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_planning_ow_tech_helpers_test_shared_fixtures: missing '
      'shared support file '
      '`$planningOwTechHelpersSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPlanningOwTechHelpersSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_planning_ow_tech_helpers_test_shared_fixtures: no local '
      'planning OW / tech helper fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_planning_ow_tech_helpers_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPlanningOwTechHelpersTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
