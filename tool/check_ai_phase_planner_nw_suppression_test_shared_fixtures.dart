import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for EXPAND / DEVELOP NW-suppression Games
/// and snapshots (Refs #3997).
const String phasePlannerNwSuppressionSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'phase_planner_nw_suppression_test_support.dart';

/// In-scope NW-suppression pin paths.
const Set<String> phasePlannerNwSuppressionSharedFixtureAdopters =
    <String>{
      'packages/colonizethis_ai/test/planning/'
          'expand_phase_planner_nw_suppression_test.dart',
      'packages/colonizethis_ai/test/planning/'
          'develop_phase_planner_nw_suppression_test.dart',
    };

final RegExp _localExpandGameDecl = RegExp(r'Game\s+_expandGame\b');
final RegExp _localDevelopGameDecl = RegExp(r'Game\s+_developGame\b');
final RegExp _localExpandSnapshotDecl = RegExp(
  r'AIWorldSnapshot\s+_expandSnapshot\b',
);
final RegExp _localDevelopSnapshotDecl = RegExp(
  r'AIWorldSnapshot\s+_developSnapshot\b',
);

/// True when [slashPath] is an NW-suppression planner-set pin.
bool aiPhasePlannerNwSuppressionSharedFixturesPathInScope(String slashPath) {
  return phasePlannerNwSuppressionSharedFixtureAdopters.contains(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation reason when an NW-suppression pin redeclares a
/// local Game/snapshot clone that must live in shared support.
String? aiPhasePlannerNwSuppressionSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiPhasePlannerNwSuppressionSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localExpandGameDecl.hasMatch(content)) {
    return 'redeclares local `_expandGame`; import '
        '`buildExpandPhaseNwSuppressionGame` from '
        '`$phasePlannerNwSuppressionSharedFixturesSupportFile` (Refs #3997)';
  }
  if (_localDevelopGameDecl.hasMatch(content)) {
    return 'redeclares local `_developGame`; import '
        '`buildDevelopPhaseNwSuppressionGame` from '
        '`$phasePlannerNwSuppressionSharedFixturesSupportFile` (Refs #3997)';
  }
  if (_localExpandSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_expandSnapshot`; import '
        '`buildExpandPhaseNwSuppressionSnapshot` from '
        '`$phasePlannerNwSuppressionSharedFixturesSupportFile` (Refs #3997)';
  }
  if (_localDevelopSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_developSnapshot`; import '
        '`buildDevelopPhaseNwSuppressionSnapshot` from '
        '`$phasePlannerNwSuppressionSharedFixturesSupportFile` (Refs #3997)';
  }
  return null;
}

int runCheckAiPhasePlannerNwSuppressionTestSharedFixtures(
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
    'phase_planner_nw_suppression_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_phase_planner_nw_suppression_test_shared_fixtures: missing '
      'shared support file '
      '`$phasePlannerNwSuppressionSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPhasePlannerNwSuppressionSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_phase_planner_nw_suppression_test_shared_fixtures: no local '
      'NW-suppression Game/snapshot redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_phase_planner_nw_suppression_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPhasePlannerNwSuppressionTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
