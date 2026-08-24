// Physical line limit for colonizethis_setup non-support tests (repo rule:
// `repo.colonizethis_setup_test_file_size`).
//
// Wave 8 (#4624): peer-aligned 250 physical-line ceiling. `test/setup/support/`
// is governed separately by `repo.colonizethis_setup_test_support_loc`.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for wave-8 post-densify non-support test files.
const int setupTestFileSizeCeiling = 250;

const String _setupTestsRelativePath = 'packages/colonizethis_setup/test';

const String _setupTestSupportPrefix =
    'packages/colonizethis_setup/test/setup/support/';

/// Near-cap suites grandfathered during densify. Shrink-only; empty after #4624.
const List<String> setupTestFileSizeGrandfathered = <String>[];

int runCheckColonizethisSetupTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = setupTestFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final setupTestsDir = Directory(p.join(repoRoot, _setupTestsRelativePath));
  if (!setupTestsDir.existsSync()) {
    logE(
      'check_colonizethis_setup_test_file_size: '
      'packages/colonizethis_setup/test not found.',
    );
    return 1;
  }

  final grandfathered = (grandfatheredPaths ?? setupTestFileSizeGrandfathered)
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
      'check_colonizethis_setup_test_file_size: stale grandfather entries '
      '(file no longer exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    setupTestsDir,
    targetFiles,
  )) {
    final relativePath = p
        .relative(filePath, from: repoRoot)
        .replaceAll('\\', '/');
    if (relativePath.startsWith(_setupTestSupportPrefix)) {
      continue;
    }
    if (grandfathered.contains(relativePath)) {
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
      'check_colonizethis_setup_test_file_size: no violations found '
      '(ceiling $ceiling; Refs #4624).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_colonizethis_setup_test_file_size: found ${violations.length} '
    'violation(s) under $_setupTestsRelativePath (wave-8 ceiling $ceiling; '
    'Refs #4624):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory setupTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return setupTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith('$_setupTestsRelativePath/') ||
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
    runCheckColonizethisSetupTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
