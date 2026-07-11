import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for EXPAND peace unit pins that must import
/// shared snapshot / Game fixtures (Refs #3967).
const String _expandPeaceTestPathPrefix =
    'packages/colonizethis_ai/test/planning/expand_phase_planner_';

/// Canonical shared support library that owns [ownSnapshot] and the
/// critical / distraction / zero-regiment / peer Game builders.
const String expandPeaceSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'expand_phase_peace_test_support.dart';

/// Forbidden local snapshot helper declarations in expand-peace pins.
final RegExp _localOwnSnapshotDecl = RegExp(
  r'(?:AIWorldSnapshot|PerceptionSnapshot)\s+_ownSnapshot\b',
);

/// Forbidden local Game builders that must live in the shared support
/// library after the harness lands (Refs #3967 AC-2).
final RegExp _localCriticalGameDecl = RegExp(r'Game\s+_criticalGame\b');
final RegExp _localDistractionGameDecl = RegExp(r'Game\s+_distractionGame\b');
final RegExp _localZeroRegimentGameDecl = RegExp(r'Game\s+_zeroRegimentGame\b');
final RegExp _localPeerGameDecl = RegExp(r'Game\s+_peerGame\b');

/// True when the repo-relative [slashPath] is an in-scope expand-peace
/// `*_peace*_test.dart` pin (not the shared support library).
bool aiExpandPeaceSharedFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_expandPeaceTestPathPrefix)) {
    return false;
  }
  if (!normalized.endsWith('_test.dart')) {
    return false;
  }
  final fileName = p.basename(normalized);
  return fileName.contains('peace');
}

/// Returns a violation reason when [content] redeclares a local expand-peace
/// fixture that must live in the shared support library, or `null` when
/// compliant.
String? aiExpandPeaceSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiExpandPeaceSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localOwnSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_ownSnapshot`; import `ownSnapshot` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (_localCriticalGameDecl.hasMatch(content)) {
    return 'redeclares local `_criticalGame`; import '
        '`buildCriticalExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (_localDistractionGameDecl.hasMatch(content)) {
    return 'redeclares local `_distractionGame`; import '
        '`buildDistractionExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (_localZeroRegimentGameDecl.hasMatch(content)) {
    return 'redeclares local `_zeroRegimentGame`; import '
        '`buildZeroRegimentExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (_localPeerGameDecl.hasMatch(content)) {
    return 'redeclares local `_peerGame`; import '
        '`buildPeerExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  return null;
}

int runCheckAiExpandPeaceTestSharedFixtures(
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
    'expand_phase_peace_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_expand_peace_test_shared_fixtures: missing shared support '
      'file `$expandPeaceSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiExpandPeaceSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_expand_peace_test_shared_fixtures: no local expand-peace '
      'fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_expand_peace_test_shared_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiExpandPeaceTestSharedFixtures(Directory.current.path));
}
