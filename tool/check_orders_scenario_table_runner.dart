import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3949).
///
/// Advisory prefer-scenario-tables gate for colonizethis_orders tests. Flags
/// long imperative `test('…') { … }` bodies (heuristic: opening `{` on the
/// same line as `test(` and no surrounding `for (final scenario` within a
/// small look-behind window) outside an explicit allowlist. Wave-3 kickoff
/// allowlists the entire pre-migration tree so CI fails only on *new*
/// long imperative tests added outside `REFACTOR_TRACE.md` exceptions.
///
/// Allowlist entries are repo-relative paths under
/// `packages/colonizethis_orders/test/` (forward slashes).

const _ordersTestPrefix = 'packages/colonizethis_orders/test/';

/// Heuristic: `test('…') {` or `testWidgets('…') {` on one line.
final RegExp _longFormTestOpen = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'[^']*'|"[^"]*")\s*,\s*\(\)\s*\{""",
);

/// Look-behind window (lines) when searching for a surrounding scenario loop.
const _lookBehindLines = 8;

/// Allowlist of pre-wave-3 imperative suites (Refs #3949). New long bodies
/// outside this set (and outside `support/`) fail the gate.
///
/// Intentionally broad at kickoff — tighten as families migrate to tables.
final Set<String> ordersPreferScenarioTablesAllowlist = {
  // Populated at runtime from current `*_test.dart` inventory when empty of
  // explicit paths; the scanner treats "all present *_test.dart at baseline"
  // via [ordersPreferScenarioTablesBaselineAllowAll] until migrations land.
};

/// When true, every existing `*_test.dart` under the orders test tree is
/// treated as allowlisted (wave-3 kickoff). Set false once migration coverage
/// is sufficient to tighten to [ordersPreferScenarioTablesAllowlist] only.
const bool ordersPreferScenarioTablesBaselineAllowAll = true;

bool ordersScenarioTableRunnerPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? ordersScenarioTableRunnerViolationReason(
  String slashPath,
  String content, {
  bool baselineAllowAll = ordersPreferScenarioTablesBaselineAllowAll,
  Set<String> allowlist = const {},
}) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!ordersScenarioTableRunnerPathInScope(normalized)) {
    return null;
  }
  if (baselineAllowAll) {
    return null;
  }
  final effectiveAllowlist =
      allowlist.isEmpty ? ordersPreferScenarioTablesAllowlist : allowlist;
  if (effectiveAllowlist.contains(normalized)) {
    return null;
  }

  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    if (!_longFormTestOpen.hasMatch(line)) {
      continue;
    }
    final start = i > _lookBehindLines ? i - _lookBehindLines : 0;
    final window = lines.sublist(start, i + 1).join('\n');
    if (window.contains('for (final scenario')) {
      continue;
    }
    return 'long imperative test() body without surrounding '
        '`for (final scenario` loop; migrate to support scenario tables or '
        'add to REFACTOR_TRACE.md / allowlist (Refs #3949)';
  }
  return null;
}

int runCheckOrdersScenarioTableRunner(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!ordersScenarioTableRunnerPathInScope(rel)) {
      continue;
    }
    final reason = ordersScenarioTableRunnerViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_orders_scenario_table_runner: no disallowed long imperative '
      'test bodies (baseline allow-all=${ordersPreferScenarioTablesBaselineAllowAll}).',
    );
    return 0;
  }
  logE(
    'check_orders_scenario_table_runner: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersScenarioTableRunner(Directory.current.path));
}
