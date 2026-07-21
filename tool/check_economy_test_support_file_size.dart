// Physical line ratchet for colonizethis_economy_test_support lib source (repo
// rule: `repo.economy_test_support_file_size`).
//
// Slice B of #4108 split oversized support modules so every file stays at or
// below ~215 physical lines. This tighter support-only ceiling keeps the
// splits from silently re-growing toward pre-refactor kitchen-sink sizes.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Ratchet ceiling chosen just above the post-split largest file
/// (`deal_matcher_priority_scenarios.dart`, 215 physical lines at #4108).
const int economyTestSupportFileSizeCeiling = 220;

const String _economyTestSupportLibRelativePath =
    'packages/colonizethis_economy_test_support/lib';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckEconomyTestSupportFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = economyTestSupportFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(
    p.join(repoRoot, _economyTestSupportLibRelativePath),
  );
  if (!libDir.existsSync()) {
    logE(
      'check_economy_test_support_file_size: '
      '$_economyTestSupportLibRelativePath not found.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, libDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p.relative(file.path, from: repoRoot);
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
      'check_economy_test_support_file_size: no violations found '
      '(ceiling $ceiling; Refs #4108).',
    );
    return 0;
  }

  logE(
    'check_economy_test_support_file_size: found ${violations.length} '
    'violation(s) under $_economyTestSupportLibRelativePath '
    '(ceiling $ceiling; Refs #4108):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory libDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return libDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  final results = <String>[];
  for (final relativePath in targetFiles) {
    if (!relativePath.startsWith('$_economyTestSupportLibRelativePath/') ||
        !relativePath.endsWith('.dart') ||
        _generatedSuffix.hasMatch(relativePath)) {
      continue;
    }
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      continue;
    }
    results.add(file.path);
  }
  return results;
}

void main(List<String> args) {
  exit(
    runCheckEconomyTestSupportFileSize(
      Directory.current.path,
      targetFiles: args.isEmpty ? null : args,
    ),
  );
}
