// Physical line limit for colonizethis_turn non-support tests (repo rule:
// `repo.turn_test_file_size`).
//
// Wave 4 (#4113): peer-aligned 400 physical-line ceiling for root test suites;
// `test/support/` is governed separately by `repo.turn_test_support_loc`.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_turn_test_support_loc.dart';

/// Ratchet ceiling for wave-8 densify of non-support test files (≤300).
/// Wave 4 landed 400 (Refs #4113); wave 8 tightens to 300 (Refs #4583).
const int turnTestFileSizeCeiling = 300;

const String _turnTestsRelativePath = 'packages/colonizethis_turn/test';

int runCheckTurnTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = turnTestFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final turnTestsDir = Directory(p.join(repoRoot, _turnTestsRelativePath));
  if (!turnTestsDir.existsSync()) {
    logE(
      'check_turn_test_file_size: packages/colonizethis_turn/test not found.',
    );
    return 1;
  }

  final supportPrefix = '${turnTestSupportRelativeDir.replaceAll(r'\', '/')}/';

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    turnTestsDir,
    targetFiles,
  )) {
    final relativePath = p
        .relative(filePath, from: repoRoot)
        .replaceAll('\\', '/');
    if (relativePath.startsWith(supportPrefix)) {
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(File(filePath).readAsStringSync())
        .length;
    if (physicalLines <= ceiling) {
      continue;
    }
    violations.add('$relativePath ($physicalLines physical lines > $ceiling)');
  }

  if (violations.isEmpty) {
    logI(
      'check_turn_test_file_size: no violations found '
      '(ceiling $ceiling; Refs #4113, #4583).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_turn_test_file_size: found ${violations.length} violation(s) '
    'under $_turnTestsRelativePath (wave-8 ceiling $ceiling; Refs #4113, #4583):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory turnTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return turnTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith('$_turnTestsRelativePath/') ||
        !normalized.endsWith('.dart')) {
      continue;
    }
    final file = File(p.join(repoRoot, normalized));
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckTurnTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
