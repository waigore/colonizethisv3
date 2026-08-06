import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4273).
///
/// Prefer-scenario-tables gate for colonizethis_setup tests. Flags long
/// imperative `test('…') { … }` bodies outside
/// [setupPreferScenarioTablesAllowlist]. Wave-6 slice D migrates the fat
/// creation/redistribution/naming suites; baseline allow-all stays on until
/// remaining imperative suites are table-driven.
///
/// Allowlist entries are repo-relative paths under
/// `packages/colonizethis_setup/test/` (forward slashes).

const _setupTestPrefix = 'packages/colonizethis_setup/test/';

/// Heuristic: `test('…') {` or `testWidgets('…') {` on one line.
final RegExp _longFormTestOpen = RegExp(
  r"""(?:test|testWidgets)\(\s*(?:'[^']*'|"[^"]*")\s*,\s*\(\)\s*\{""",
);

/// Look-behind window (lines) when searching for a surrounding scenario loop.
const _lookBehindLines = 8;

/// Documented-exception imperative suites after wave-6 slice D migrations.
final Set<String> setupPreferScenarioTablesAllowlist = {};

/// When true, every existing `*_test.dart` under the setup test tree is
/// treated as allowlisted (wave-6 kickoff). Set false once migration coverage
/// is sufficient to tighten to [setupPreferScenarioTablesAllowlist] only.
const bool setupPreferScenarioTablesBaselineAllowAll = true;

bool setupScenarioTableRunnerPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_setupTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? setupScenarioTableRunnerViolationReason(
  String slashPath,
  String content, {
  bool baselineAllowAll = setupPreferScenarioTablesBaselineAllowAll,
  Set<String> allowlist = const {},
}) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!setupScenarioTableRunnerPathInScope(normalized)) {
    return null;
  }
  if (baselineAllowAll) {
    return null;
  }
  final effectiveAllowlist = allowlist.isEmpty
      ? setupPreferScenarioTablesAllowlist
      : allowlist;
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
        'add to allowlist (Refs #4273)';
  }
  return null;
}

int runCheckColonizethisSetupScenarioTableRunner(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!setupScenarioTableRunnerPathInScope(rel)) {
      continue;
    }
    final reason = setupScenarioTableRunnerViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_colonizethis_setup_scenario_table_runner: no disallowed long '
      'imperative test bodies (baseline allow-all='
      '$setupPreferScenarioTablesBaselineAllowAll).',
    );
    return 0;
  }
  logE(
    'check_colonizethis_setup_scenario_table_runner: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckColonizethisSetupScenarioTableRunner(Directory.current.path));
}
