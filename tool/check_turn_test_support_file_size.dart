// Physical line ratchet for colonizethis_turn test/support
// (repo rule: `repo.turn_test_support_file_size`).
//
// Wave 9 (#4740) splits remaining kitchen-sink support hosts so every support
// file stays at or below 250 physical lines. Distinct from the tree-total
// `repo.turn_test_support_loc` gate and from non-support `repo.turn_test_file_size`.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_turn_test_support_loc.dart';

/// Wave-9 support per-file ceiling (Refs #4740).
const int turnTestSupportFileSizeCeiling = 250;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckTurnTestSupportFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = turnTestSupportFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final supportDir = Directory(p.join(repoRoot, turnTestSupportRelativeDir));
  if (!supportDir.existsSync()) {
    logE(
      'check_turn_test_support_file_size: '
      '$turnTestSupportRelativeDir not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    supportDir,
    targetFiles,
  )) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
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
      'check_turn_test_support_file_size: no violations found '
      '(ceiling $ceiling; Refs #4740).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_turn_test_support_file_size: found ${violations.length} '
    'violation(s) under $turnTestSupportRelativeDir '
    '(ceiling $ceiling; Refs #4740):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory supportDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return supportDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith('$turnTestSupportRelativeDir/') ||
        !normalized.endsWith('.dart') ||
        _generatedSuffix.hasMatch(normalized)) {
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
    runCheckTurnTestSupportFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
