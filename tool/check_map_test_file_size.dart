// Physical line limit for colonizethis_map tests (repo rule:
// `repo.map_test_file_size`).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 400;

const _mapTestsRelativePath = 'packages/colonizethis_map/test';

/// Shrink-only allowlist during transition; remove entries as densify lands.
const List<String> mapTestFileSizeGrandfathered = <String>[];

int runCheckMapTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = _maxPhysicalLines,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final mapTestsDir = Directory(p.join(repoRoot, _mapTestsRelativePath));
  if (!mapTestsDir.existsSync()) {
    logE('check_map_test_file_size: $_mapTestsRelativePath not found.');
    return 1;
  }

  final grandfathered = (grandfatheredPaths ?? mapTestFileSizeGrandfathered)
      .map((path) => path.replaceAll('\\', '/'))
      .toSet();

  final violations = <String>[];
  final filesToCheck = _collectFilesToCheck(
    repoRoot,
    mapTestsDir,
    targetFiles,
  );
  for (final filePath in filesToCheck) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (grandfathered.contains(relativePath)) continue;
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= ceiling) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $ceiling)',
    );
  }

  if (violations.isEmpty) {
    logI('check_map_test_file_size: no violations found.');
    return 0;
  }

  logE(
    'check_map_test_file_size: found ${violations.length} violation(s) '
    'under $_mapTestsRelativePath:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory mapTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return mapTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith('$_mapTestsRelativePath/') ||
        !relativePath.endsWith('.dart')) {
      continue;
    }
    final absolutePath = p.join(repoRoot, relativePath);
    final file = File(absolutePath);
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckMapTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}

int maxMapTestFilePhysicalLinesForTests() => _maxPhysicalLines;
