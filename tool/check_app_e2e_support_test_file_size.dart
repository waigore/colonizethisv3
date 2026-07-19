// Physical line limit for colonizethis_app_e2e_support tests
// (`repo.app_e2e_support_test_file_size`).
//
// SPEC: SPEC/program/repo-lint.md (§ app e2e support test file size).
// Refs #4075.
//
// Cap is 800 physical lines. Files currently over the cap are listed in
// [appE2eSupportTestFileSizeAllowlistForTests] (shrink-only). A stale
// allowlist entry (missing file, or file now ≤ cap) fails so the backlog
// cannot retain slack. `test/support/**` harness modules should prefer ≤600
// physical lines (same hygiene as `repo.app_test_support_file_size`).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 800;

const String _testsRelativePath = 'packages/colonizethis_app_e2e_support/test';

/// Oversized e2e-support `test/**` files accepted as a shrink-only baseline
/// (Refs #4075). Remove an entry only after the file is at or under
/// [_maxPhysicalLines].
const List<String> appE2eSupportTestFileSizeAllowlistForTests = <String>[];

int runCheckAppE2eSupportTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? allowlistPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final testsDir = Directory(p.join(repoRoot, _testsRelativePath));
  if (!testsDir.existsSync()) {
    logE(
      'check_app_e2e_support_test_file_size: $_testsRelativePath not found.',
    );
    return 1;
  }

  final allowlist =
      (allowlistPaths ?? appE2eSupportTestFileSizeAllowlistForTests)
          .map((path) => path.replaceAll('\\', '/'))
          .toSet();

  final stale = <String>[];
  for (final relativePath in allowlist) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      stale.add('$relativePath (missing)');
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= _maxPhysicalLines) {
      stale.add(
        '$relativePath (now $physicalLines ≤ $_maxPhysicalLines; remove)',
      );
    }
  }
  if (stale.isNotEmpty) {
    final sorted = stale.toList()..sort();
    logE(
      'check_app_e2e_support_test_file_size: stale allowlist entries '
      '(must shrink):',
    );
    for (final entry in sorted) {
      logE(' - $entry');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    testsDir,
    targetFiles,
  )) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (allowlist.contains(relativePath)) {
      continue;
    }
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
    logI('check_app_e2e_support_test_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_app_e2e_support_test_file_size: found ${violations.length} '
    'violation(s) under $_testsRelativePath:',
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

  const prefix = '$_testsRelativePath/';
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

int maxAppE2eSupportTestPhysicalLinesForTests() => _maxPhysicalLines;

void main(List<String> args) {
  exit(
    runCheckAppE2eSupportTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
