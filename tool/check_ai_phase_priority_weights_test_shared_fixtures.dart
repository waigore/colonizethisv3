import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for phase priority weights Game fixtures
/// (Refs #4310 Slice C).
const String phasePriorityWeightsSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'phase_priority_weights_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared phase priority weights fixtures.
const Set<String> phasePriorityWeightsSharedFixtureAdopterBasenames = {
  'phase_priority_weights_curve_cases.dart',
  'phase_priority_weights_override_cases.dart',
};

final RegExp _localGameWithRegimentsDecl =
    RegExp(r'Game\s+_gameWithRegiments\b');
final RegExp _localSnapshotDecl = RegExp(r'AIWorldSnapshot\s+_snapshot\b');

bool _isPhasePriorityWeightsAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return phasePriorityWeightsSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the phase priority weights gate.
bool aiPhasePriorityWeightsSharedFixturesPathInScope(String slashPath) {
  return _isPhasePriorityWeightsAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game/snapshot
/// factory that must live in shared support.
String? aiPhasePriorityWeightsSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isPhasePriorityWeightsAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithRegimentsDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithRegiments`; import '
        '`phasePriorityWeightsGameWithRegiments` from '
        '`$phasePriorityWeightsSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_snapshot`; import '
        '`phasePriorityWeightsSnapshot` from '
        '`$phasePriorityWeightsSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiPhasePriorityWeightsTestSharedFixtures(
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
    'phase_priority_weights_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_phase_priority_weights_test_shared_fixtures: missing '
      'shared support file '
      '`$phasePriorityWeightsSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPhasePriorityWeightsSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_phase_priority_weights_test_shared_fixtures: no local '
      'phase priority weights fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_phase_priority_weights_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPhasePriorityWeightsTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
