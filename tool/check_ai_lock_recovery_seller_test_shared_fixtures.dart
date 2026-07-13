import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for lock-recovery seller Game scaffolds
/// (Refs #3997).
const String lockRecoverySellerSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'lock_recovery_seller_test_support.dart';

/// In-scope lock-recovery seller pin paths.
const Set<String> lockRecoverySellerSharedFixtureAdopters = <String>{
  'packages/colonizethis_ai/test/planning/cast_iron_labour_gate_test.dart',
  'packages/colonizethis_ai/test/planning/'
      'domain_planner_orchestrator_h8_feedstock_civilian_work_test.dart',
};

final RegExp _localLockRecoverySellerGameDecl = RegExp(
  r'Game\s+_lockRecoverySellerGame\b',
);

/// True when [slashPath] is a lock-recovery seller adopter pin.
bool aiLockRecoverySellerSharedFixturesPathInScope(String slashPath) {
  return lockRecoverySellerSharedFixtureAdopters.contains(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation reason when an adopter redeclares a local
/// `_lockRecoverySellerGame` clone.
String? aiLockRecoverySellerSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!aiLockRecoverySellerSharedFixturesPathInScope(normalized)) {
    return null;
  }
  if (_localLockRecoverySellerGameDecl.hasMatch(content)) {
    return 'redeclares local `_lockRecoverySellerGame`; import '
        '`buildCastIronLabourLockRecoverySellerGame` / '
        '`buildH8FeedstockLockRecoverySellerGame` from '
        '`$lockRecoverySellerSharedFixturesSupportFile` (Refs #3997)';
  }
  return null;
}

int runCheckAiLockRecoverySellerTestSharedFixtures(
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
    'lock_recovery_seller_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_lock_recovery_seller_test_shared_fixtures: missing '
      'shared support file '
      '`$lockRecoverySellerSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiLockRecoverySellerSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_lock_recovery_seller_test_shared_fixtures: no local '
      '`_lockRecoverySellerGame` redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_lock_recovery_seller_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiLockRecoverySellerTestSharedFixtures(Directory.current.path),
  );
}
