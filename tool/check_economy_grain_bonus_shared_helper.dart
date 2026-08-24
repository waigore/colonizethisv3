import 'dart:io';

import 'package:path/path.dart' as p;

/// SPEC: SPEC/program/repo-lint.md (Refs #4631).
///
/// Capital-tile grain bonus eligibility/amount lives in
/// `capitalTileGrainBonusForPlayer`. The three destination call sites must
/// call that helper; other economy lib files must not add
/// `capitalTileGrainBonusPerTurn` on non-comment lines.
const _helperRelativePath =
    'packages/colonizethis_economy/lib/src/economy/capital_tile_grain_bonus.dart';

const _helperSymbol = 'capitalTileGrainBonusForPlayer';

const _consumerRelativePaths = <String>[
  'packages/colonizethis_economy/lib/src/economy/resource_extractor.dart',
  'packages/colonizethis_economy/lib/src/economy/'
      'development_panel_read_model_scopes.dart',
  'packages/colonizethis_economy/lib/src/economy/'
      'province_extraction_snapshot_builder.dart',
];

const _fieldName = 'capitalTileGrainBonusPerTurn';

void main() {
  exit(runCheckEconomyGrainBonusSharedHelper(Directory.current.path));
}

int runCheckEconomyGrainBonusSharedHelper(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);

  final helperFile = File(p.join(root, _helperRelativePath));
  if (!helperFile.existsSync()) {
    logE('ERROR: Missing grain-bonus helper file: $_helperRelativePath');
    return 1;
  }
  if (!helperFile.readAsStringSync().contains('$_helperSymbol(')) {
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
      logE('ERROR: Missing grain-bonus consumer: $relative');
      return 1;
    }
    if (!file.readAsStringSync().contains('$_helperSymbol(')) {
      violations.add(
        '$relative no longer calls `$_helperSymbol` (Refs #4631).',
      );
    }
  }

  final libDir = Directory(p.join(root, 'packages/colonizethis_economy/lib'));
  if (libDir.existsSync()) {
    for (final file
        in libDir
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final relative = p.relative(file.path, from: root).replaceAll('\\', '/');
      if (relative == _helperRelativePath) continue;
      var lineNo = 0;
      for (final line in file.readAsStringSync().split('\n')) {
        lineNo++;
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue;
        if (line.contains(_fieldName)) {
          violations.add(
            '$relative:$lineNo inlines `$_fieldName` outside '
            '`$_helperSymbol` (Refs #4631).',
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    logI('Economy grain-bonus shared-helper check passed.');
    return 0;
  }

  logE(
    'ERROR: Capital-tile grain bonus must stay on `$_helperSymbol` '
    '(Refs #4631).',
  );
  for (final v in violations) {
    logE(v);
  }
  return 1;
}
