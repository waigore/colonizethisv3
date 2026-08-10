import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for composite peace-target Game / snapshot
/// fixtures (Refs #4310 Slice C).
const String observerGoalPhaseCompositePeaceSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'observer_goal_phase_composite_peace_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String> observerGoalPhaseCompositePeaceSharedFixtureAdopterBasenames =
    {
  'observer_goal_phase_composite_peace_test.dart',
};

final RegExp _localPristineOwProvincesDecl =
    RegExp(r'Game\s+_pristineOwProvinces\b');
final RegExp _localZeroRegimentAtWarGameDecl =
    RegExp(r'Game\s+_zeroRegimentAtWarGame\b');
final RegExp _localSnapshotForDecl = RegExp(r'AIWorldSnapshot\s+_snapshotFor\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return observerGoalPhaseCompositePeaceSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

bool aiObserverGoalPhaseCompositePeaceSharedFixturesPathInScope(
  String slashPath,
) {
  return _isAdopterPath(slashPath.replaceAll('\\', '/'));
}

String? aiObserverGoalPhaseCompositePeaceSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localPristineOwProvincesDecl.hasMatch(content)) {
    return 'redeclares local `_pristineOwProvinces`; import '
        '`observerGoalPhaseCompositePeacePristineOwProvinces` from '
        '`$observerGoalPhaseCompositePeaceSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localZeroRegimentAtWarGameDecl.hasMatch(content)) {
    return 'redeclares local `_zeroRegimentAtWarGame`; import '
        '`observerGoalPhaseCompositePeaceZeroRegimentAtWarGame` from '
        '`$observerGoalPhaseCompositePeaceSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localSnapshotForDecl.hasMatch(content)) {
    return 'redeclares local `_snapshotFor`; import '
        '`observerGoalPhaseCompositePeaceSnapshotFor` from '
        '`$observerGoalPhaseCompositePeaceSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiObserverGoalPhaseCompositePeaceTestSharedFixtures(
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
    'observer_goal_phase_composite_peace_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_observer_goal_phase_composite_peace_test_shared_fixtures: '
      'missing shared support file '
      '`$observerGoalPhaseCompositePeaceSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiObserverGoalPhaseCompositePeaceSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_observer_goal_phase_composite_peace_test_shared_fixtures: '
      'no local composite peace fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_observer_goal_phase_composite_peace_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiObserverGoalPhaseCompositePeaceTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
