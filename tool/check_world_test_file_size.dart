// Physical line limit for colonizethis_world non-support tests (repo rule:
// `repo.colonizethis_world_test_file_size`).
//
// Wave 7 (#4515): peer-aligned 300 physical-line ceiling after densify (down
// from wave-6's 320). `test/world_test_support/` is governed separately by
// `repo.world_test_support_file_size`.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling for wave-7 post-densify root test files.
const int worldTestFileSizeCeiling = 300;

const String _worldTestsRelativePath = 'packages/colonizethis_world/test';

const String _worldTestSupportPrefix =
    'packages/colonizethis_world/test/world_test_support/';

/// Near-cap suites grandfathered during densify. Shrink-only; empty after #4515.
const List<String> worldTestFileSizeGrandfathered = <String>[];

int runCheckWorldTestFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = worldTestFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final worldTestsDir = Directory(p.join(repoRoot, _worldTestsRelativePath));
  if (!worldTestsDir.existsSync()) {
    logE(
      'check_world_test_file_size: packages/colonizethis_world/test not found.',
    );
    return 1;
  }

  final grandfathered = (grandfatheredPaths ?? worldTestFileSizeGrandfathered)
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
      'check_world_test_file_size: stale grandfather entries (file no longer '
      'exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(
    repoRoot,
    worldTestsDir,
    targetFiles,
  )) {
    final relativePath = p
        .relative(filePath, from: repoRoot)
        .replaceAll('\\', '/');
    if (relativePath.startsWith(_worldTestSupportPrefix)) {
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
      'check_world_test_file_size: no violations found '
      '(ceiling $ceiling; Refs #4515).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_world_test_file_size: found ${violations.length} violation(s) '
    'under $_worldTestsRelativePath (wave-7 ceiling $ceiling; Refs #4515):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory worldTestsDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return worldTestsDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith('$_worldTestsRelativePath/') ||
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
    runCheckWorldTestFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
