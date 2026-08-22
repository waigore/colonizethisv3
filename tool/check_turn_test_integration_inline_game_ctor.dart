import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4252, #4168, #4583).
///
/// Forbid inline `Game(` constructor calls under
/// `packages/colonizethis_turn/test/support/integration/**`. Wave 8 emptied
/// the wave-5 grandfather allowlist; use harness builders instead.
const _integrationPrefix =
    'packages/colonizethis_turn/test/support/integration/';

/// Empty after wave 8 (#4583); shrink-only if any path is ever re-added.
const _allowlistedRelativePaths = <String>{};

/// Matches an inline `Game(` constructor call (standalone identifier, not
/// `gameWithTwoGps(` etc.).
final RegExp _inlineGameConstructor = RegExp(r'(?<![A-Za-z0-9_])Game\(');

bool turnTestIntegrationInlineGameCtorPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_integrationPrefix) ||
      !normalized.endsWith('.dart')) {
    return false;
  }
  return !_allowlistedRelativePaths.contains(normalized);
}

String? turnTestIntegrationInlineGameCtorViolationReason(
  String slashPath,
  String content,
) {
  if (!turnTestIntegrationInlineGameCtorPathInScope(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  if (!_inlineGameConstructor.hasMatch(code)) {
    return null;
  }
  return 'constructs Game(...) inline; use harness builders from '
      '`test/support/turn_*_test_harness.dart` or '
      '`turn_resolver_test_harness.dart` (Refs #4252, #4168, #4583)';
}

String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    out.writeln(line);
  }
  return out.toString();
}

int runCheckTurnTestIntegrationInlineGameCtor(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = turnTestIntegrationInlineGameCtorViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_turn_test_integration_inline_game_ctor: no inline Game(...) '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_turn_test_integration_inline_game_ctor: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnTestIntegrationInlineGameCtor(Directory.current.path));
}
