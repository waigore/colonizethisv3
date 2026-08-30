// Physical line limit for colonizethis_models tests (repo rule:
// `repo.models_test_file_size`).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Wave-4 models test physical-line ceiling (Refs #4571).
const int modelsTestPhysicalFileSizeCeiling = 250;

const _modelsTestsRelativePath = 'packages/colonizethis_models/test';

/// PR-blocking structural check: files under
/// `packages/colonizethis_models/test/**` must stay at or below 250 physical
/// lines (Refs #4068 Slice D, #4571).
int runCheckModelsTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = modelsTestPhysicalFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final modelsTestsDir = Directory(p.join(repoRoot, _modelsTestsRelativePath));
  if (!modelsTestsDir.existsSync()) {
    logE(
      'check_models_test_file_size: packages/colonizethis_models/test '
      'not found.',
    );
    return 1;
  }

  final violations = <String>[];
  final filesToCheck = _collectFilesToCheck(
    repoRoot,
    modelsTestsDir,
    targetFiles,
  );
  for (final filePath in filesToCheck) {
    final file = File(filePath);
    final relativePath = p.relative(file.path, from: repoRoot);
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
    logI('check_models_test_file_size: no violations found.');
    return 0;
  }

  logE(
    'check_models_test_file_size: found ${violations.length} violation(s) '
    'under packages/colonizethis_models/test:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory modelsTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return modelsTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith('packages/colonizethis_models/test/') ||
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
    runCheckModelsTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
