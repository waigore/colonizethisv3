import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3983).
///
/// Combat `test/**/*_test.dart` must register scenario tables via
/// `runLabeledScenarios` / `runLabeledScenarioGroup` rather than bare
/// `for (final scenario in …) { test(scenario.label, …); }` loops.
const _combatTestPrefix = 'packages/colonizethis_combat/test/';

final RegExp _bareScenarioLoopPattern = RegExp(
  r'for\s*\(\s*final\s+scenario\s+in\s+',
);

void main() {
  exit(runCheckCombatTestScenarioHarness(Directory.current.path));
}

int runCheckCombatTestScenarioHarness(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!rel.startsWith(_combatTestPrefix) || !rel.endsWith('_test.dart')) {
      continue;
    }
    final content = file.readAsStringSync();
    if (!_bareScenarioLoopPattern.hasMatch(content)) {
      continue;
    }
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (_bareScenarioLoopPattern.hasMatch(lines[i])) {
        violations.add(
          '$rel:${i + 1}: bare `for (final scenario in …)` loop is '
          'disallowed — use runLabeledScenarios / runLabeledScenarioGroup '
          '(Refs #3983)',
        );
      }
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_combat_test_scenario_harness: no bare scenario-loop violations.',
    );
    return 0;
  }

  logE(
    'check_combat_test_scenario_harness: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}
