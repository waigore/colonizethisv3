import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative paths under `packages/colonizethis_diplomacy/test/**` that may
/// still construct `Game(` inline (exceptions-only allowlist; Refs #4028).
///
/// Empty after absorption/dedup/shared-helpers migration — keep empty unless a
/// suite must test construction itself.
const _allowlistedRelativePaths = <String>{};

/// Matches an inline `Game(` constructor call (standalone identifier, not
/// `gpGpEmbassyGame(` etc.).
final RegExp _inlineGameConstructor = RegExp(r'(?<![A-Za-z0-9_])Game\(');

/// True when [slashPath] is a diplomacy package test file subject to the ban.
bool diplomacyTestInlineGameCtorPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith('packages/colonizethis_diplomacy/test/') ||
      !normalized.endsWith('.dart')) {
    return false;
  }
  return !_allowlistedRelativePaths.contains(normalized);
}

/// Returns a violation reason when [content] constructs `Game(` inline instead
/// of importing shared fixtures from `colonizethis_diplomacy_test_support`.
String? diplomacyTestInlineGameCtorViolationReason(String slashPath, String content) {
  if (!diplomacyTestInlineGameCtorPathInScope(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  if (!_inlineGameConstructor.hasMatch(code)) {
    return null;
  }
  return "constructs Game(...) inline; import shared builders from "
      "'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart' "
      "(Refs #3825, #3837, #4028)";
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

int runCheckDiplomacyTestInlineGameCtor(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = diplomacyTestInlineGameCtorViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_test_inline_game_ctor: no inline Game(...) violations.',
    );
    return 0;
  }
  logE(
    'check_diplomacy_test_inline_game_ctor: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyTestInlineGameCtor(Directory.current.path));
}
