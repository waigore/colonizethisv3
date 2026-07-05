import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative prefixes whose tests must not inline `as TurnPhaseStepContinue`
/// casts when the shared phase harness exists (Refs #3876).
const _scopedPrefixes = [
  'packages/colonizethis_turn/test/turn/',
  'packages/colonizethis_turn/test/integration/',
];

/// Support modules allowed to reference turn phase step types directly.
const _allowlistedBasenames = {
  'turn_phase_test_harness.dart',
  'turn_phase_test_harness_test.dart',
};

final RegExp _turnPhaseStepContinueCast = RegExp(
  r'\bas\s+TurnPhaseStepContinue\b',
);

bool turnTestPhaseHarnessPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith('packages/colonizethis_turn/test/')) {
    return false;
  }
  if (normalized.startsWith('packages/colonizethis_turn/test/support/')) {
    return false;
  }
  return _scopedPrefixes.any(normalized.startsWith);
}

String? turnTestPhaseHarnessCastViolationReason(String fileName, String content) {
  if (_allowlistedBasenames.contains(fileName)) {
    return null;
  }
  if (!_turnPhaseStepContinueCast.hasMatch(content)) {
    return null;
  }
  return 'uses `as TurnPhaseStepContinue`; call '
      '`runTurnPhaseHandler` / `runTurnPhaseHandlerPipeline` from '
      '`test/support/turn_phase_test_harness.dart` instead (Refs #3876)';
}

int runCheckTurnTestPhaseHarness(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnTestPhaseHarnessPathInScope(rel)) {
      continue;
    }
    final reason = turnTestPhaseHarnessCastViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_turn_test_phase_harness: no inline phase-harness cast violations.');
    return 0;
  }
  logE(
    'check_turn_test_phase_harness: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnTestPhaseHarness(Directory.current.path));
}
