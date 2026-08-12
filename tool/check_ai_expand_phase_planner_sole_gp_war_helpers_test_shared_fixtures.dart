import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for sole-GP-war helper Game / snapshot
/// fixtures (Refs #4310 Slice C).
const String expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'expand_phase_planner_sole_gp_war_helpers_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared sole-GP-war helper fixtures.
const Set<String> expandPhasePlannerSoleGpWarHelpersSharedFixtureAdopterBasenames =
    {
  'expand_phase_planner_sole_gp_war_helpers_test.dart',
  'expand_phase_planner_sole_gp_war_helpers_sole_at_war_cases.dart',
  'expand_phase_planner_sole_gp_war_helpers_pivot_cases.dart',
};

final RegExp _localGameWithGpsAndMinorsDecl =
    RegExp(r'Game\s+_gameWithGpsAndMinors\b');
final RegExp _localGameWithProvincesDecl =
    RegExp(r'Game\s+_gameWithProvinces\b');
final RegExp _localSnapshotAtWarWithDecl =
    RegExp(r'AIWorldSnapshot\s+_snapshotAtWarWith\b');
final RegExp _localPivotSnapshotForDecl =
    RegExp(r'AIWorldSnapshot\s+_pivotSnapshotFor\b');
final RegExp _localGp1OwProvincesDecl =
    RegExp(r'List<Province>\s+_gp1OwProvinces\b');

bool _isExpandPhasePlannerSoleGpWarHelpersAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return expandPhasePlannerSoleGpWarHelpersSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the sole-GP-war fixture gate.
bool aiExpandPhasePlannerSoleGpWarHelpersSharedFixturesPathInScope(
  String slashPath,
) {
  return _isExpandPhasePlannerSoleGpWarHelpersAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local factory that
/// must live in shared support.
String? aiExpandPhasePlannerSoleGpWarHelpersSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isExpandPhasePlannerSoleGpWarHelpersAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithGpsAndMinorsDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithGpsAndMinors`; import '
        '`soleGpWarHelpersGameWithGpsAndMinors` from '
        '`$expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localGameWithProvincesDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithProvinces`; import '
        '`soleGpWarHelpersGameWithProvinces` from '
        '`$expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localSnapshotAtWarWithDecl.hasMatch(content)) {
    return 'redeclares local `_snapshotAtWarWith`; import '
        '`soleGpWarHelpersSnapshotAtWarWith` from '
        '`$expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localPivotSnapshotForDecl.hasMatch(content)) {
    return 'redeclares local `_pivotSnapshotFor`; import '
        '`soleGpWarHelpersPivotSnapshotFor` from '
        '`$expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localGp1OwProvincesDecl.hasMatch(content)) {
    return 'redeclares local `_gp1OwProvinces`; import '
        '`soleGpWarHelpersGp1OwProvinces` from '
        '`$expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures(
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
    'expand_phase_planner_sole_gp_war_helpers_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_expand_phase_planner_sole_gp_war_helpers_test_shared_fixtures: '
      'missing shared support file '
      '`$expandPhasePlannerSoleGpWarHelpersSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiExpandPhasePlannerSoleGpWarHelpersSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_expand_phase_planner_sole_gp_war_helpers_test_shared_fixtures: '
      'no local sole-GP-war helper fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_expand_phase_planner_sole_gp_war_helpers_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiExpandPhasePlannerSoleGpWarHelpersTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
