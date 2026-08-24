// Physical line limit for app widget/unit tests (`repo.app_test_file_size`).
//
// SPEC: SPEC/program/repo-lint.md (§ app test file size). Refs #4013, #4021, #4352.
//
// Cap is 350 physical lines (Refs #4352 Slice D; wave-21 #4606 Slice E; wave-22 #4642 Slice F). The shrink-only
// [appTestFileSizeAllowlistForTests] is empty after densify; a stale
// allowlist entry (missing file, or file now ≤ cap) fails so the backlog cannot
// retain slack.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxPhysicalLines = 350;

const String _appTestsRelativePath = 'app/test';

/// Oversized `app/test/**` files accepted as a shrink-only baseline (Refs #4352).
/// Remove an entry only after the file is at or under [_maxPhysicalLines].
const List<String> appTestFileSizeAllowlistForTests = <String>[];

int runCheckAppTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? allowlistPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final appTestsDir = Directory(p.join(repoRoot, _appTestsRelativePath));
  if (!appTestsDir.existsSync()) {
    logE('check_app_test_file_size: $_appTestsRelativePath not found.');
    return 1;
  }

  final allowlist = (allowlistPaths ?? appTestFileSizeAllowlistForTests)
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
    logE('check_app_test_file_size: stale allowlist entries (must shrink):');
    for (final entry in sorted) {
      logE(' - $entry');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    appTestsDir,
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
    logI('check_app_test_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_app_test_file_size: found ${violations.length} violation(s) under '
    '$_appTestsRelativePath:',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory appTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return appTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  const prefix = '$_appTestsRelativePath/';
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

int maxAppTestPhysicalLinesForTests() => _maxPhysicalLines;

void main(List<String> args) {
  exit(
    runCheckAppTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
