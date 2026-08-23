// Physical line ratchet for app/lib/features/game/screens
// (`repo.app_features_screens_lib_physical_file_size`).
//
// SPEC: SPEC/program/app-features-screens-file-size.md (wave-15 #4352 Slice A).
// Shrink-only grandfather allowlist; remove entries as splits land.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Ratchet ceiling for app feature screens (≤250 physical lines; Refs #4582).
const int appFeaturesScreensLibPhysicalFileSizeCeiling = 250;

const String _screensLibRelativePath = 'app/lib/features/game/screens';

/// Hot files still above the wave-15 ceiling during transition slices.
/// Shrink-only allowlist; remove entries as splits land. Refs #4352.
const List<String> appFeaturesScreensLibPhysicalFileSizeGrandfatheredForTests =
    <String>[];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckAppFeaturesScreensLibPhysicalFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = appFeaturesScreensLibPhysicalFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _screensLibRelativePath));
  if (!libDir.existsSync()) {
    logE(
      'check_app_features_screens_lib_physical_file_size: '
      '$_screensLibRelativePath not found.',
    );
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ??
              appFeaturesScreensLibPhysicalFileSizeGrandfatheredForTests)
          .map((path) => path.replaceAll('\\', '/'))
          .toSet();

  final missingGrandfathered = <String>[];
  final underCapGrandfathered = <String>[];
  for (final relativePath in grandfathered) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      missingGrandfathered.add(relativePath);
      continue;
    }
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= ceiling) {
      underCapGrandfathered.add(
        '$relativePath ($physicalLines ≤ $ceiling; remove from allowlist)',
      );
    }
  }
  if (missingGrandfathered.isNotEmpty) {
    logE(
      'check_app_features_screens_lib_physical_file_size: stale grandfather '
      'entries (file no longer exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }
  if (underCapGrandfathered.isNotEmpty) {
    logE(
      'check_app_features_screens_lib_physical_file_size: stale grandfather '
      'entries (file now under cap; remove from allowlist):',
    );
    for (final entry in underCapGrandfathered) {
      logE(' - $entry');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, libDir, targetFiles)) {
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
      'check_app_features_screens_lib_physical_file_size: no violations found '
      '(ceiling $ceiling; Refs #4352).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_app_features_screens_lib_physical_file_size: found '
    '${violations.length} violation(s) under $_screensLibRelativePath '
    '(ceiling $ceiling; Refs #4352):',
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

  const prefix = '$_screensLibRelativePath/';
  final results = <String>[];
  for (final relativePath in targetFiles) {
    final normalized = relativePath.replaceAll('\\', '/');
    if (!normalized.startsWith(prefix) || !normalized.endsWith('.dart')) {
      continue;
    }
    if (_generatedSuffix.hasMatch(normalized)) {
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

int maxAppFeaturesScreensLibPhysicalFileLinesForTests() =>
    appFeaturesScreensLibPhysicalFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckAppFeaturesScreensLibPhysicalFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
