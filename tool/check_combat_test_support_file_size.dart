// Physical line ratchet for colonizethis_combat_test_support lib source (repo
// rule: `repo.combat_test_support_file_size`).
//
// Slice D of #4196 split oversized support modules so every file stays at or
// below ~220 physical lines. This tighter support-only ceiling keeps the
// splits from silently re-growing toward pre-refactor kitchen-sink sizes.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling chosen just above post-#4633 splits (largest leftover
/// modules keep ≥15 lines of 200 headroom).
const int combatTestSupportFileSizeCeiling = 200;

const String _combatTestSupportLibRelativePath =
    'packages/colonizethis_combat_test_support/lib';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckCombatTestSupportFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = combatTestSupportFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(
    p.join(repoRoot, _combatTestSupportLibRelativePath),
  );
  if (!libDir.existsSync()) {
    logE(
      'check_combat_test_support_file_size: '
      '$_combatTestSupportLibRelativePath not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, libDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p.relative(file.path, from: repoRoot);
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= ceiling) {
      continue;
    }
    violations.add('$relativePath ($physicalLines physical lines > $ceiling)');
  }

  if (violations.isEmpty) {
    logI(
      'check_combat_test_support_file_size: no violations found '
      '(ceiling $ceiling; Refs #4633).',
    );
    return 0;
  }

  logE(
    'check_combat_test_support_file_size: found ${violations.length} '
    'violation(s) under $_combatTestSupportLibRelativePath '
    '(ceiling $ceiling; Refs #4633):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory libDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return libDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith('$_combatTestSupportLibRelativePath/') ||
        !relativePath.endsWith('.dart') ||
        _generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckCombatTestSupportFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
