import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4631).
///
/// `previewForceFeeding` and `allocateConsumption` must call the shared
/// military→navy prefix `allocateMilitaryNavyFood`. Direct
/// `consumeMilitaryFood` / `consumeNavyFood` in `force_feeding_readiness.dart`
/// or inline `RegimentEconomyCatalog` `foodUpkeep` loops fail.
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/'
    'economy_military_navy_food_allocation.dart';

const _helperSymbol = 'allocateMilitaryNavyFood';

const _consumerRelativePaths = <String>[
  'packages/colonizethis_economy/lib/src/economy/force_feeding_readiness.dart',
  'packages/colonizethis_economy/lib/src/economy/economy_consumption_allocation.dart',
];

const _forceFeedingRelative =
    'packages/colonizethis_economy/lib/src/economy/force_feeding_readiness.dart';

void main() {
  exit(runCheckEconomyForceFeedingSharedHelper(Directory.current.path));
}

int runCheckEconomyForceFeedingSharedHelper(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final helperFile = File(p.join(root, _helperRelativePath));
  if (!helperFile.existsSync()) {
    logE('ERROR: Missing shared prefix file: $_helperRelativePath');
    return 1;
  }
  final helperSource = helperFile.readAsStringSync();
  if (!helperSource.contains('$_helperSymbol(')) {
    logE(
      'ERROR: $_helperRelativePath no longer defines `$_helperSymbol` '
      '(Refs #4631).',
    );
    return 1;
  }

  final violations = <String>[];
  for (final relative in _consumerRelativePaths) {
    final file = File(p.join(root, relative));
    if (!file.existsSync()) {
      logE('ERROR: Missing force-feeding consumer: $relative');
      return 1;
    }
    final source = file.readAsStringSync();
    if (!source.contains('$_helperSymbol(')) {
      violations.add(
        '$relative no longer calls `$_helperSymbol`; preview and allocation '
        'must share the military→navy prefix (Refs #4631).',
      );
    }
  }

  final forceFeeding = File(p.join(root, _forceFeedingRelative));
  if (forceFeeding.existsSync()) {
    final source = forceFeeding.readAsStringSync();
    if (source.contains('consumeMilitaryFood(') ||
        source.contains('consumeNavyFood(') ||
        source.contains('RegimentEconomyCatalog')) {
      violations.add(
        '$_forceFeedingRelative calls consumeMilitaryFood / consumeNavyFood '
        'or inlines RegimentEconomyCatalog foodUpkeep instead of '
        '`$_helperSymbol` (Refs #4631).',
      );
    }
  }

  if (violations.isEmpty) {
    logI('Economy force-feeding shared-helper check passed.');
    return 0;
  }

  logE(
    'ERROR: Force-feeding / allocateConsumption must share '
    '`$_helperSymbol` (Refs #4631).',
  );
  for (final v in violations) {
    logE(v);
  }
  return 1;
}
