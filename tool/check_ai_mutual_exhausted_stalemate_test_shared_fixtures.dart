import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for mutual-exhausted GP stalemate Game fixtures
/// (Refs #4310 Slice C).
const String mutualExhaustedStalemateSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'mutual_exhausted_stalemate_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared mutual-exhausted stalemate fixtures.
const Set<String> mutualExhaustedStalemateSharedFixtureAdopterBasenames = {
  'diplomacy_planner_mutual_exhausted_peace_targets_cases.dart',
  'diplomacy_planner_mutual_exhausted_peace_wiring_cases.dart',
  'diplomatic_candidate_scoring_mutual_exhausted_offer_peace_test.dart',
};

final RegExp _localExhaustedStalemateGameDecl =
    RegExp(r'Game\s+_exhaustedStalemateGame\b');
final RegExp _localSnapshotForOwnDecl =
    RegExp(r'AIWorldSnapshot\s+_snapshotForOwn\b');

bool _isMutualExhaustedStalemateAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return mutualExhaustedStalemateSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the mutual-exhausted fixture gate.
bool aiMutualExhaustedStalemateSharedFixturesPathInScope(String slashPath) {
  return _isMutualExhaustedStalemateAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game/snapshot
/// factory that must live in shared support.
String? aiMutualExhaustedStalemateSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isMutualExhaustedStalemateAdopterPath(normalized)) {
    return null;
  }
  if (_localExhaustedStalemateGameDecl.hasMatch(content)) {
    return 'redeclares local `_exhaustedStalemateGame`; import '
        '`mutualExhaustedStalemateGame` from '
        '`$mutualExhaustedStalemateSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localSnapshotForOwnDecl.hasMatch(content)) {
    return 'redeclares local `_snapshotForOwn`; import '
        '`kMutualExhaustedStalemateDefaultSnapshot` / '
        '`mutualExhaustedStalemateSnapshotForOwn` from '
        '`$mutualExhaustedStalemateSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiMutualExhaustedStalemateTestSharedFixtures(
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
    'mutual_exhausted_stalemate_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_mutual_exhausted_stalemate_test_shared_fixtures: missing '
      'shared support file '
      '`$mutualExhaustedStalemateSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiMutualExhaustedStalemateSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_mutual_exhausted_stalemate_test_shared_fixtures: no local '
      'mutual-exhausted stalemate fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_mutual_exhausted_stalemate_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiMutualExhaustedStalemateTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
