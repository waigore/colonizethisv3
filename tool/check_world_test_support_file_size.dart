// Physical line ratchet for colonizethis_world test/world_test_support
// (repo rule: `repo.world_test_support_file_size`).
//
// Wave 7 (#4515) split `connectivity_builders.dart` so every support file stays
// at or below 280 physical lines. This tighter support-only ceiling keeps the
// splits from silently re-growing toward pre-refactor kitchen-sink sizes.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Wave-8 support ceiling after leftover densify (Refs #4611).
const int worldTestSupportFileSizeCeiling = 250;

const String _worldTestSupportRelativePath =
    'packages/colonizethis_world/test/world_test_support';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckWorldTestSupportFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = worldTestSupportFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final supportDir = Directory(p.join(repoRoot, _worldTestSupportRelativePath));
  if (!supportDir.existsSync()) {
    logE(
      'check_world_test_support_file_size: '
      '$_worldTestSupportRelativePath not found.',
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
      'check_world_test_support_file_size: no violations found '
      '(ceiling $ceiling; Refs #4515).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_world_test_support_file_size: found ${violations.length} '
    'violation(s) under $_worldTestSupportRelativePath '
    '(ceiling $ceiling; Refs #4515):',
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
    if (!normalized.startsWith('$_worldTestSupportRelativePath/') ||
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
    runCheckWorldTestSupportFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
