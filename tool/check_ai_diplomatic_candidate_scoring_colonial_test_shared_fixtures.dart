import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for COLONIAL diplomatic candidate scoring Game
/// fixtures (Refs #4310 Slice C).
const String diplomaticCandidateScoringColonialSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'diplomatic_candidate_scoring_colonial_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared COLONIAL scoring fixtures.
const Set<String> diplomaticCandidateScoringColonialSharedFixtureAdopterBasenames =
    {
  'diplomatic_candidate_scoring_personality_colonial_divergence_test.dart',
  'diplomatic_candidate_scoring_intervention_tribe_tolerance_test.dart',
};

final RegExp _localColonialScenarioGameDecl =
    RegExp(r'Game\s+_colonialScenarioGame\b');
final RegExp _localColonialTribeScenarioGameDecl =
    RegExp(r'Game\s+_colonialTribeScenarioGame\b');

bool _isDiplomaticCandidateScoringColonialAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return diplomaticCandidateScoringColonialSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the COLONIAL scoring fixture gate.
bool aiDiplomaticCandidateScoringColonialSharedFixturesPathInScope(
  String slashPath,
) {
  return _isDiplomaticCandidateScoringColonialAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game factory that
/// must live in shared support.
String? aiDiplomaticCandidateScoringColonialSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isDiplomaticCandidateScoringColonialAdopterPath(normalized)) {
    return null;
  }
  if (_localColonialScenarioGameDecl.hasMatch(content)) {
    return 'redeclares local `_colonialScenarioGame`; import '
        '`diplomaticCandidateScoringColonialTribeScenarioGame` from '
        '`$diplomaticCandidateScoringColonialSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localColonialTribeScenarioGameDecl.hasMatch(content)) {
    return 'redeclares local `_colonialTribeScenarioGame`; import '
        '`diplomaticCandidateScoringColonialTribeScenarioGame` from '
        '`$diplomaticCandidateScoringColonialSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures(
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
    'diplomatic_candidate_scoring_colonial_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_diplomatic_candidate_scoring_colonial_test_shared_fixtures: '
      'missing shared support file '
      '`$diplomaticCandidateScoringColonialSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiDiplomaticCandidateScoringColonialSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_diplomatic_candidate_scoring_colonial_test_shared_fixtures: '
      'no local COLONIAL diplomatic scoring fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_diplomatic_candidate_scoring_colonial_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiDiplomaticCandidateScoringColonialTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
