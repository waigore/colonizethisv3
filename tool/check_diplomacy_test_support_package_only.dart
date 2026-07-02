import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #3837).
///
/// Forbid package-local diplomacy test fixture modules after migration to
/// `colonizethis_diplomacy_test_support`.
const _forbiddenSupportDirPrefix =
    'packages/colonizethis_diplomacy/test/support/';

/// Legacy shim paths removed during #3837 slice 2; no new local support files.
const _legacyLocalSupportPaths = <String>{
  'packages/colonizethis_diplomacy/test/support/call_to_arms_fixtures.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_game_fixtures.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_game_fixtures_base.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_game_fixtures_domain.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_game_fixtures_scenarios.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_game_fixtures_scenarios_gp_tribe.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_phase_scenarios.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_relation_fixtures.dart',
  'packages/colonizethis_diplomacy/test/support/diplomacy_resolver_phase_test_support.dart',
  'packages/colonizethis_diplomacy/test/support/event_dialogue_test_support.dart',
  'packages/colonizethis_diplomacy/test/dossier/evidence_rules_test_support.dart',
};

final RegExp _localTestSupportFile = RegExp(
  r'packages/colonizethis_diplomacy/test/.+_test_support\.dart$',
);

String? diplomacyTestSupportPackageOnlyViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (normalized.startsWith(_forbiddenSupportDirPrefix)) {
    return 'move fixtures to colonizethis_diplomacy_test_support (Refs #3837)';
  }
  if (_localTestSupportFile.hasMatch(normalized) &&
      !_legacyLocalSupportPaths.contains(normalized)) {
    return 'add shared helpers to colonizethis_diplomacy_test_support instead '
        'of package-local *_test_support.dart (Refs #3837)';
  }
  return null;
}

int runCheckDiplomacyTestSupportPackageOnly(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final diplomacyTestDir = Directory(
    p.join(repoRoot, 'packages/colonizethis_diplomacy/test'),
  );
  if (!diplomacyTestDir.existsSync()) {
    logE(
      'check_diplomacy_test_support_package_only: diplomacy test tree missing.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final entity in diplomacyTestDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final rel = p.relative(entity.path, from: repoRoot).replaceAll('\\', '/');
    final reason = diplomacyTestSupportPackageOnlyViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_test_support_package_only: no local fixture violations.',
    );
    return 0;
  }
  logE(
    'check_diplomacy_test_support_package_only: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyTestSupportPackageOnly(Directory.current.path));
}
