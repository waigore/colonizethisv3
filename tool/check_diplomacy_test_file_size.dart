// Physical line limit for colonizethis_diplomacy tests (repo rule:
// `repo.diplomacy_test_file_size`).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 400;

const _diplomacyTestsRelativePath = 'packages/colonizethis_diplomacy/test';

/// PR-blocking structural check: files under
/// `packages/colonizethis_diplomacy/test/**` must stay at or below 400 physical
/// lines (Refs #3837).
int runCheckDiplomacyTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final diplomacyTestsDir =
      Directory(p.join(repoRoot, _diplomacyTestsRelativePath));
  if (!diplomacyTestsDir.existsSync()) {
    logE(
      'check_diplomacy_test_file_size: packages/colonizethis_diplomacy/test '
      'not found.',
    );
    return 1;
  }

  final violations = <String>[];
  final filesToCheck = _collectFilesToCheck(
    repoRoot,
    diplomacyTestsDir,
    targetFiles,
  );
  for (final filePath in filesToCheck) {
    final file = File(filePath);
    final relativePath = p.relative(file.path, from: repoRoot);
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= _maxPhysicalLines) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $_maxPhysicalLines)',
    );
  }

  if (violations.isEmpty) {
    logI('check_diplomacy_test_file_size: no violations found.');
    return 0;
  }

  logE(
    'check_diplomacy_test_file_size: found ${violations.length} violation(s) '
    'under packages/colonizethis_diplomacy/test:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory diplomacyTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return diplomacyTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith('packages/colonizethis_diplomacy/test/') ||
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
    runCheckDiplomacyTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
