import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for COLONIAL acquisition unit pins (Refs #3972).
const String _acquisitionTestPathPrefix =
    'packages/colonizethis_ai/test/planning/'
    'colonial_phase_planner_acquisition_';

/// Canonical shared support library for acquisition Game / relation helpers.
const String colonialAcquisitionSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'colonial_acquisition_test_support.dart';

/// Forbidden local Game builders that must live in the shared support library.
final RegExp _localAcquisitionGameDecl = RegExp(r'Game\s+_acquisitionGame\b');
final RegExp _localPurchaseLandGameDecl = RegExp(r'Game\s+_purchaseLandGame\b');
final RegExp _localDeclareWarGameDecl = RegExp(r'Game\s+_declareWarGame\b');
final RegExp _localBothValidGameDecl = RegExp(r'Game\s+_bothValidGame\b');

/// Forbidden local DiplomacyRelation helpers.
final RegExp _localFriendlyDecl = RegExp(r'DiplomacyRelation\s+_friendly\b');
final RegExp _localPeaceFriendlyDecl = RegExp(
  r'DiplomacyRelation\s+_peaceFriendly\b',
);
final RegExp _localAtWarDecl = RegExp(r'DiplomacyRelation\s+_atWar\b');

/// True when the repo-relative [slashPath] is an in-scope acquisition pin.
bool aiColonialAcquisitionSharedFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_acquisitionTestPathPrefix)) {
    return false;
  }
  return normalized.endsWith('_test.dart');
}

/// Returns a violation reason when [content] redeclares a local acquisition
/// fixture that must live in the shared support library, or `null` when
/// compliant.
String? aiColonialAcquisitionSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiColonialAcquisitionSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localAcquisitionGameDecl.hasMatch(content)) {
    return 'redeclares local `_acquisitionGame`; import '
        '`buildColonialAcquisitionGame` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localPurchaseLandGameDecl.hasMatch(content)) {
    return 'redeclares local `_purchaseLandGame`; import '
        '`buildColonialAcquisitionGame` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localDeclareWarGameDecl.hasMatch(content)) {
    return 'redeclares local `_declareWarGame`; import '
        '`buildColonialAcquisitionGame` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localBothValidGameDecl.hasMatch(content)) {
    return 'redeclares local `_bothValidGame`; import '
        '`buildColonialAcquisitionBothValidGame` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localFriendlyDecl.hasMatch(content)) {
    return 'redeclares local `_friendly`; import '
        '`colonialAcquisitionFriendly` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localPeaceFriendlyDecl.hasMatch(content)) {
    return 'redeclares local `_peaceFriendly`; import '
        '`colonialAcquisitionFriendly` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  if (_localAtWarDecl.hasMatch(content)) {
    return 'redeclares local `_atWar`; import '
        '`colonialAcquisitionAtWar` from '
        '`$colonialAcquisitionSharedFixturesSupportFile` (Refs #3972)';
  }
  return null;
}

int runCheckAiColonialAcquisitionTestSharedFixtures(
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
    'colonial_acquisition_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_colonial_acquisition_test_shared_fixtures: missing shared '
      'support file `$colonialAcquisitionSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiColonialAcquisitionSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_colonial_acquisition_test_shared_fixtures: no local '
      'acquisition fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_colonial_acquisition_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiColonialAcquisitionTestSharedFixtures(Directory.current.path));
}
