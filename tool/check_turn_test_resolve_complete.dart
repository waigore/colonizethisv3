import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Success-path turn resolution in `packages/colonizethis_turn/test/**` must use
/// [resolveTurnComplete] from `test/support/turn_resolver_test_harness.dart`
/// rather than nesting `requireTurnResolutionComplete(resolveTurnForGame(...))`
/// or calling `resolveTurnForGame(` directly (Refs #4039).
///
/// Pending / resume / alternate-entry tests keep an explicit allowlist.
const _scopedPrefix = 'packages/colonizethis_turn/test/';

const _harnessBasename = 'turn_resolver_test_harness.dart';

/// Basenames allowed to call `resolveTurnForGame(` (pending results, harness).
const _resolveTurnForGameAllowlist = {
  _harnessBasename,
  // Pending intervention resume path — must observe TurnResolutionPending*.
  'diplomacy_intervention_diplomacy_phase_test.dart',
};

final RegExp _nestedRequireResolveTurnForGame = RegExp(
  r'requireTurnResolutionComplete\s*\(\s*resolveTurnForGame\s*\(',
  multiLine: true,
);

final RegExp _directResolveTurnForGame = RegExp(r'\bresolveTurnForGame\s*\(');

bool turnTestResolveCompletePathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_scopedPrefix);
}

String? turnTestResolveCompleteViolationReason(
  String fileName,
  String content,
) {
  if (_resolveTurnForGameAllowlist.contains(fileName)) {
    return null;
  }
  if (_nestedRequireResolveTurnForGame.hasMatch(content)) {
    return 'nests `requireTurnResolutionComplete(resolveTurnForGame(...))`; '
        'call `resolveTurnComplete` from `test/support/turn_resolver_test_harness.dart` '
        '(Refs #4039)';
  }
  if (_directResolveTurnForGame.hasMatch(content)) {
    return 'calls `resolveTurnForGame(` directly; use `resolveTurnComplete` '
        '(or allowlist pending/negative cases) (Refs #4039)';
  }
  return null;
}

int runCheckTurnTestResolveComplete(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnTestResolveCompletePathInScope(rel)) {
      continue;
    }
    final reason = turnTestResolveCompleteViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_turn_test_resolve_complete: no resolve-complete violations.');
    return 0;
  }
  logE('check_turn_test_resolve_complete: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnTestResolveComplete(Directory.current.path));
}
