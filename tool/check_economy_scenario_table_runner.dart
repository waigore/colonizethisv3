import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3939).
///
/// Flags new imperative economy tests whose `test()` body exceeds
/// [_maxImperativeTestBodyLines] without a surrounding scenario-table loop.
const _economyTestPrefix = 'packages/colonizethis_economy/test/';
const _maxImperativeTestBodyLines = 15;

/// Permanent micro-exceptions for the scenario-table preference.
///
/// Empty after Phase 5 (#3979): former allowlisted runners already use
/// `runLabeledScenarios` / `runLabeledScenarioGroup`. Keep this set at
/// ≤2 paths if a future constant-pin suite needs a documented exemption
/// (see `packages/colonizethis_economy/REFACTOR_TRACE.md`).
const _allowlistedRelativePaths = <String>{};

final RegExp _scenarioLoopPattern = RegExp(
  r'for\s*\(\s*final\s+scenario\s+in\s+',
);

final RegExp _testOpenPattern = RegExp(
  r'^\s*(?:test|testWidgets)\(',
);

void main() {
  exit(runCheckEconomyScenarioTableRunner(Directory.current.path));
}

int runCheckEconomyScenarioTableRunner(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!rel.startsWith(_economyTestPrefix) || !rel.endsWith('_test.dart')) {
      continue;
    }
    if (_allowlistedRelativePaths.contains(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    if (_scenarioLoopPattern.hasMatch(content)) {
      continue;
    }
    if (runLabeledScenarioGroupPattern.hasMatch(content) ||
        runLabeledScenariosPattern.hasMatch(content)) {
      continue;
    }
    final reason = economyScenarioTableRunnerViolationReason(content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_economy_scenario_table_runner: no imperative-test violations.');
    return 0;
  }

  logE(
    'check_economy_scenario_table_runner: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

final RegExp runLabeledScenarioGroupPattern = RegExp(
  r'runLabeledScenarioGroup\s*\(',
);

final RegExp runLabeledScenariosPattern = RegExp(
  r'runLabeledScenarios\s*\(',
);

String? economyScenarioTableRunnerViolationReason(String content) {
  final lines = content.split('\n');
  var insideLongTest = false;
  var testBodyLines = 0;
  var braceDepth = 0;

  for (final line in lines) {
    if (!insideLongTest && _testOpenPattern.hasMatch(line)) {
      insideLongTest = true;
      testBodyLines = 0;
      braceDepth = 0;
    }
    if (!insideLongTest) {
      continue;
    }

    testBodyLines++;
    braceDepth += _netBraceDelta(line);

    if (braceDepth <= 0 && testBodyLines > 1) {
      if (testBodyLines > _maxImperativeTestBodyLines) {
        return 'imperative test() body spans $testBodyLines lines without a '
            'scenario-table loop (cap $_maxImperativeTestBodyLines; '
            'Refs #3939)';
      }
      insideLongTest = false;
      testBodyLines = 0;
      braceDepth = 0;
    }
  }

  return null;
}

int _netBraceDelta(String line) {
  final code = line.split('//').first;
  var delta = 0;
  for (var i = 0; i < code.length; i++) {
    final ch = code[i];
    if (ch == '{') delta++;
    if (ch == '}') delta--;
  }
  return delta;
}
