// check_gdd_coverage — Report which GDD specs (SPEC/game) are covered by sim_scenarios.
//
// Reads SPEC/project/gdd-scenario-coverage.json and SPEC/game/*.md.
// Covered = spec has at least one scenario listed; otherwise uncovered.
// Exit 0 if all covered, 1 if any uncovered.
//
// Usage (from repo root): melos run check_gdd_coverage

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

void main(List<String> args) {
  final cwd = Directory.current.path;
  final repoRoot = _findRepoRoot(cwd);
  if (repoRoot == null) {
    stderr.writeln('check_gdd_coverage: must run from repo root or a subdir');
    exit(2);
  }

  final specDir = Directory(path.join(repoRoot, 'SPEC', 'game'));
  if (!specDir.existsSync()) {
    stderr.writeln('check_gdd_coverage: SPEC/game not found');
    exit(2);
  }

  final mappingPath = path.join(repoRoot, 'SPEC', 'project', 'gdd-scenario-coverage.json');
  final mappingFile = File(mappingPath);
  if (!mappingFile.existsSync()) {
    stderr.writeln('check_gdd_coverage: mapping not found: $mappingPath');
    exit(2);
  }

  Map<String, dynamic> mapping;
  try {
    mapping = jsonDecode(mappingFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('check_gdd_coverage: invalid JSON in $mappingPath: $e');
    exit(2);
  }

  final allSpecs = specDir
      .listSync()
      .whereType<File>()
      .where((f) => path.extension(f.path) == '.md')
      .map((f) => 'game/${path.basename(f.path)}')
      .toList()
    ..sort();

  final scenariosDir = path.join(repoRoot, 'tool', 'sim_scenarios', 'scenarios');
  final scenarioDirExists = Directory(scenariosDir).existsSync();

  var covered = 0;
  final uncovered = <String>[];
  final missingScenarios = <String, List<String>>{};
  final verifierIssuesBySpec = <String, List<String>>{};

  for (final spec in allSpecs) {
    final value = mapping[spec];
    List<dynamic> scenarioList;
    List<dynamic> issueList;
    if (value == null) {
      scenarioList = [];
      issueList = [];
    } else if (value is List<dynamic>) {
      scenarioList = value;
      issueList = [];
    } else if (value is Map<String, dynamic>) {
      scenarioList = (value['scenarios'] as List<dynamic>?) ?? [];
      issueList = (value['verifierIssues'] as List<dynamic>?) ?? [];
    } else {
      scenarioList = [];
      issueList = [];
    }

    final hasScenarios = scenarioList.isNotEmpty;
    if (hasScenarios) {
      covered++;
      if (scenarioDirExists) {
        final missing = <String>[];
        for (final s in scenarioList) {
          final name = s is String ? s : s.toString();
          final f = File(path.join(scenariosDir, name));
          if (!f.existsSync()) missing.add(name);
        }
        if (missing.isNotEmpty) {
          missingScenarios[spec] = missing;
        }
      }
      if (issueList.isNotEmpty) {
        verifierIssuesBySpec[spec] = issueList
            .map((e) => e is String ? e : e.toString())
            .toList();
      }
    } else {
      uncovered.add(spec);
    }
  }

  final total = allSpecs.length;
  print('GDD scenario coverage');
  print('=====================');
  print('Total specs:  $total');
  print('Covered:      $covered');
  print('Uncovered:    ${uncovered.length}');
  print('');

  if (missingScenarios.isNotEmpty) {
    print('Warnings: scenario file(s) listed in mapping but not found:');
    for (final e in missingScenarios.entries) {
      print('  ${e.key}: ${e.value.join(", ")}');
    }
    print('');
  }

  if (verifierIssuesBySpec.isNotEmpty) {
    print('Verifier issues (coder: rectify and clear from mapping):');
    for (final e in verifierIssuesBySpec.entries) {
      print('  ${e.key}:');
      for (final issue in e.value) {
        print('    - $issue');
      }
    }
    print('');
  }

  if (uncovered.isEmpty) {
    print('All GDD specs have scenario coverage.');
    exit(0);
  }

  print('Uncovered specs (use one per session):');
  for (final spec in uncovered) {
    print('  $spec');
  }
  exit(1);
}

String? _findRepoRoot(String start) {
  var dir = start;
  while (true) {
    final spec = path.join(dir, 'SPEC', 'project', 'gdd-scenario-coverage.json');
    if (File(spec).existsSync()) return dir;
    final parent = path.dirname(dir);
    if (parent == dir) return null;
    dir = parent;
  }
}
