// Physical line ratchet for colonizethis_test tests
// (`repo.colonizethis_test_test_file_size`). Refs #4547.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const int colonizethisTestTestFileSizeCeiling = 250;

const String _testsRelDir = 'packages/colonizethis_test/test';

const List<String> colonizethisTestTestFileSizeGrandfatheredForTests =
    <String>[];

int runCheckColonizethisTestTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = colonizethisTestTestFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final testsDir = Directory(p.join(repoRoot, _testsRelDir));
  if (!testsDir.existsSync()) {
    logE('check_colonizethis_test_test_file_size: $_testsRelDir not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? colonizethisTestTestFileSizeGrandfatheredForTests)
          .map((path) => path.replaceAll('\\', '/'))
          .toSet();

  final missingGrandfathered = <String>[];
  for (final relativePath in grandfathered) {
    if (!File(p.join(repoRoot, relativePath)).existsSync()) {
      missingGrandfathered.add(relativePath);
    }
  }
  if (missingGrandfathered.isNotEmpty) {
    logE(
      'check_colonizethis_test_test_file_size: stale grandfather entries (file '
      'no longer exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, testsDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (grandfathered.contains(relativePath)) {
      continue;
    }
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
      'check_colonizethis_test_test_file_size: no violations found '
      '(ceiling $ceiling; Refs #4547).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_colonizethis_test_test_file_size: found ${violations.length} '
    'violation(s) under $_testsRelDir (ceiling $ceiling; Refs #4547):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory testsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return testsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  const prefix = '$_testsRelDir/';
  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith(prefix) || !normalized.endsWith('.dart')) {
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

int maxColonizethisTestTestFilePhysicalLinesForTests() =>
    colonizethisTestTestFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckColonizethisTestTestFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
