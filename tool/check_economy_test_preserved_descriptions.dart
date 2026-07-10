import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_economy_test_duplicate_descriptions.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3939).
///
/// Ensures every single-line `test('…')` / `testWidgets('…')` description
/// committed in [descriptionBaselineRelativePath] still appears exactly once
/// in the economy test tree after runner consolidation.
const descriptionBaselineRelativePath =
    'packages/colonizethis_economy/test/DESCRIPTION_BASELINE.txt';

const _economyTestDir = 'packages/colonizethis_economy/test';
const _economyScenarioSupportDir =
    'packages/colonizethis_economy_test_support/lib/src';

/// Captures `label: '…'` / `label: "…"` on scenario table rows in test_support.
final RegExp economyScenarioLabelPattern = RegExp(
  r"""label:\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""",
);

void main() {
  exit(runCheckEconomyTestPreservedDescriptions(Directory.current.path));
}

int runCheckEconomyTestPreservedDescriptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final baselineFile = File(p.join(root, descriptionBaselineRelativePath));
  if (!baselineFile.existsSync()) {
    logE(
      'check_economy_test_preserved_descriptions: missing baseline '
      '$descriptionBaselineRelativePath',
    );
    return 1;
  }

  final baselineDescriptions = baselineFile
      .readAsStringSync()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final testDir = Directory(p.join(root, _economyTestDir));
  if (!testDir.existsSync()) {
    logE(
      'check_economy_test_preserved_descriptions: missing $_economyTestDir',
    );
    return 1;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in testDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('_test.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final scenarioSourcesByPath = <String, String>{};
  final scenarioDir = Directory(p.join(root, _economyScenarioSupportDir));
  if (scenarioDir.existsSync()) {
    for (final entity in scenarioDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('_scenarios.dart')) continue;
      final relativePath = p.relative(entity.path, from: root);
      scenarioSourcesByPath[relativePath] = entity.readAsStringSync();
    }
  }

  final presentDescriptions = collectEconomyTestDescriptions(
    sourcesByPath: sourcesByPath,
    scenarioSourcesByPath: scenarioSourcesByPath,
  );
  final missing = <String>[];
  for (final description in baselineDescriptions) {
    if (!presentDescriptions.contains(description)) {
      missing.add(description);
    }
  }

  if (missing.isEmpty) {
    logI('Economy test preserved-description check passed.');
    return 0;
  }

  logE(
    'ERROR: ${missing.length} baseline test description(s) missing from '
    'packages/colonizethis_economy/test after consolidation:',
  );
  for (final description in missing) {
    logE("  '$description'");
  }
  return 1;
}

/// Returns the set of single-line `test`/`testWidgets` descriptions found in
/// [sourcesByPath] (relative path -> source), plus scenario `label:` strings
/// from [scenarioSourcesByPath] when provided.
Set<String> collectEconomyTestDescriptions({
  required Map<String, String> sourcesByPath,
  Map<String, String> scenarioSourcesByPath = const {},
}) {
  final descriptions = <String>{};
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final lines = sourcesByPath[path]!.split('\n');
    for (final line in lines) {
      if (economyTestDescriptionIsCommentLine(line)) continue;
      for (final match
          in economyTestDescriptionPattern.allMatches(line)) {
        final description = match.group(1) ?? match.group(2);
        if (description == null || description.isEmpty) continue;
        descriptions.add(description);
      }
    }
  }

  final scenarioPaths = scenarioSourcesByPath.keys.toList()..sort();
  for (final path in scenarioPaths) {
    // Match against the full file so `dart format` may place the string on the
    // line after `label:` without dropping the pin (Refs #3939 / #3949).
    // Drop full-line comments first so `// label: '…'` is not counted.
    final source = scenarioSourcesByPath[path]!
        .split('\n')
        .map((line) => economyTestDescriptionIsCommentLine(line) ? '' : line)
        .join('\n');
    for (final match in economyScenarioLabelPattern.allMatches(source)) {
      final description = match.group(1) ?? match.group(2);
      if (description == null || description.isEmpty) continue;
      descriptions.add(description);
    }
  }
  return descriptions;
}
