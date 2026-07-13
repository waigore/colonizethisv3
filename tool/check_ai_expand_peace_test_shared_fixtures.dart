import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for EXPAND peace unit pins that must import
/// shared snapshot / Game fixtures (Refs #3967).
const String _expandPeaceTestPathPrefix =
    'packages/colonizethis_ai/test/planning/expand_phase_planner_';

/// Planning-test directory that also hosts Phase-8 ownSnapshot /
/// ownVsPartner adopters outside the peace-pin glob (Refs #3997).
const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Canonical shared support library that owns [ownSnapshot] and the
/// critical / distraction / zero-regiment / peer / own-vs-partner Game
/// builders.
const String expandPeaceSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'expand_phase_peace_test_support.dart';

/// Phase-8 files that must import [ownSnapshot] instead of redeclaring
/// `_ownSnapshot` (Refs #3997).
const Set<String> _ownSnapshotAdopterBasenames = {
  'expand_phase_planner_focus_minor_target_early_cases.dart',
  'expand_phase_planner_focus_minor_target_later_cases.dart',
  'expand_phase_planner_stalled_minor_or_gp_blocker_pivot_test.dart',
  'observer_goal_phase_survival_great_power_peace_targets_test.dart',
};

/// Sole-GP matrix / peace-pin modules that must import
/// [buildOwnVsPartnerExpandPeaceGame] (Refs #3997).
///
/// Classic expand-peace `*peace*_test.dart` pins are also covered via
/// [_isExpandPeacePinPath] (sole-GP deciders + critical OW-hold).
const Set<String> _ownVsPartnerAdopterBasenames = {
  'expand_phase_peace_matrix_sole_gp_blocker_cases.dart',
};

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
final RegExp _localOwnVsPartnerGameDecl = RegExp(r'Game\s+_ownVsPartnerGame\b');

/// True when [slashPath] is a classic expand-peace `*_peace*_test.dart` pin.
bool _isExpandPeacePinPath(String normalized) {
  if (!normalized.startsWith(_expandPeaceTestPathPrefix)) {
    return false;
  }
  if (!normalized.endsWith('_test.dart')) {
    return false;
  }
  return p.basename(normalized).contains('peace');
}

/// True when [slashPath] is a Phase-8 ownSnapshot adopter.
bool _isOwnSnapshotAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return _ownSnapshotAdopterBasenames.contains(p.basename(normalized));
}

/// True when [slashPath] is a sole-GP matrix ownVsPartner adopter.
bool _isOwnVsPartnerAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return _ownVsPartnerAdopterBasenames.contains(p.basename(normalized));
}

/// True when the repo-relative [slashPath] is in scope for this gate.
bool aiExpandPeaceSharedFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return _isExpandPeacePinPath(normalized) ||
      _isOwnSnapshotAdopterPath(normalized) ||
      _isOwnVsPartnerAdopterPath(normalized);
}

/// Returns a violation reason when [content] redeclares a local expand-peace
/// fixture that must live in the shared support library, or `null` when
/// compliant.
String? aiExpandPeaceSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  final isPeacePin = _isExpandPeacePinPath(normalized);
  final isOwnSnapshotAdopter = _isOwnSnapshotAdopterPath(normalized);
  final isOwnVsPartnerAdopter = _isOwnVsPartnerAdopterPath(normalized);
  if (!isPeacePin && !isOwnSnapshotAdopter && !isOwnVsPartnerAdopter) {
    return null;
  }
  if ((isPeacePin || isOwnSnapshotAdopter) &&
      _localOwnSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_ownSnapshot`; import `ownSnapshot` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967 / #3997)';
  }
  if (isPeacePin && _localCriticalGameDecl.hasMatch(content)) {
    return 'redeclares local `_criticalGame`; import '
        '`buildCriticalExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (isPeacePin && _localDistractionGameDecl.hasMatch(content)) {
    return 'redeclares local `_distractionGame`; import '
        '`buildDistractionExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (isPeacePin && _localZeroRegimentGameDecl.hasMatch(content)) {
    return 'redeclares local `_zeroRegimentGame`; import '
        '`buildZeroRegimentExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if (isPeacePin && _localPeerGameDecl.hasMatch(content)) {
    return 'redeclares local `_peerGame`; import '
        '`buildPeerExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3967)';
  }
  if ((isPeacePin || isOwnVsPartnerAdopter) &&
      _localOwnVsPartnerGameDecl.hasMatch(content)) {
    return 'redeclares local `_ownVsPartnerGame`; import '
        '`buildOwnVsPartnerExpandPeaceGame` from '
        '`$expandPeaceSharedFixturesSupportFile` (Refs #3997)';
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
