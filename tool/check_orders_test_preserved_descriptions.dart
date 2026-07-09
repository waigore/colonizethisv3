import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_economy_test_duplicate_descriptions.dart';
import 'check_economy_test_preserved_descriptions.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3949).
///
/// Ensures every single-line `test('…')` / `testWidgets('…')` description
/// committed in [ordersDescriptionBaselineRelativePath] still appears in the
/// orders test tree (including scenario `label:` strings under
/// `test/orders/support/`) after wave-3 runner consolidation.
const ordersDescriptionBaselineRelativePath =
    'packages/colonizethis_orders/test/DESCRIPTION_BASELINE.txt';

const _ordersTestDir = 'packages/colonizethis_orders/test';
const _ordersSupportDir = 'packages/colonizethis_orders/test/orders/support';

void main() {
  exit(runCheckOrdersTestPreservedDescriptions(Directory.current.path));
}

int runCheckOrdersTestPreservedDescriptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final baselineFile = File(p.join(root, ordersDescriptionBaselineRelativePath));
  if (!baselineFile.existsSync()) {
    logE(
      'check_orders_test_preserved_descriptions: missing baseline '
      '$ordersDescriptionBaselineRelativePath',
    );
    return 1;
  }

  final baselineDescriptions = baselineFile
      .readAsStringSync()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final testDir = Directory(p.join(root, _ordersTestDir));
  if (!testDir.existsSync()) {
    logE(
      'check_orders_test_preserved_descriptions: missing $_ordersTestDir',
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
  final supportDir = Directory(p.join(root, _ordersSupportDir));
  if (supportDir.existsSync()) {
    for (final entity in supportDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      final relativePath = p.relative(entity.path, from: root);
      scenarioSourcesByPath[relativePath] = entity.readAsStringSync();
    }
  }

  final presentDescriptions = collectEconomyTestDescriptions(
    sourcesByPath: sourcesByPath,
    scenarioSourcesByPath: scenarioSourcesByPath,
  );
  // Also collect direct test()/testWidgets() already handled; scenario labels
  // from non-*_scenarios.dart support modules use the same label pattern.
  final missing = <String>[];
  for (final description in baselineDescriptions) {
    if (!presentDescriptions.contains(description)) {
      missing.add(description);
    }
  }

  if (missing.isEmpty) {
    logI('Orders test preserved-description check passed.');
    return 0;
  }

  logE(
    'ERROR: ${missing.length} baseline test description(s) missing from '
    'packages/colonizethis_orders/test after consolidation:',
  );
  for (final description in missing) {
    logE("  '$description'");
  }
  return 1;
}

/// Collects single-line `test`/`testWidgets` descriptions under orders tests
/// (exported for unit tests of this gate).
Set<String> collectOrdersTestDescriptions({
  required Map<String, String> sourcesByPath,
  Map<String, String> scenarioSourcesByPath = const {},
}) =>
    collectEconomyTestDescriptions(
      sourcesByPath: sourcesByPath,
      scenarioSourcesByPath: scenarioSourcesByPath,
    );

/// Pattern reused from economy for scenario `label:` pins.
RegExp get ordersScenarioLabelPattern => economyScenarioLabelPattern;

/// Comment-line predicate shared with economy duplicate-description lint.
bool ordersTestDescriptionIsCommentLine(String line) =>
    economyTestDescriptionIsCommentLine(line);
