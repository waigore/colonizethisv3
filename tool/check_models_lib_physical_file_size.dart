// Physical line ratchet for colonizethis_models lib source
// (`repo.models_lib_physical_file_size`). Refs #4136 Slice A.
//
// Stricter than `repo.domain_package_source_file_size` (500 physical) and
// complementary to `repo.models_file_size` (500 NCL). Shrink-only grandfather
// allowlist fails when entries are missing or the named file is now under-cap.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Ratchet ceiling for models wave-2 post-split target (≤400 physical lines).
const int modelsLibPhysicalFileSizeCeiling = 400;

const String _modelsLibRelativePath = 'packages/colonizethis_models/lib';

/// Hot files still above the wave-2 ceiling during transition slices. Shrink-only
/// allowlist; remove entries as splits land.
const List<String> modelsLibPhysicalFileSizeGrandfatheredForTests = <String>[
  'packages/colonizethis_models/lib/src/app_events/session_command_events.dart',
];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckModelsLibPhysicalFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = modelsLibPhysicalFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _modelsLibRelativePath));
  if (!libDir.existsSync()) {
    logE(
      'check_models_lib_physical_file_size: $_modelsLibRelativePath not found.',
    );
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? modelsLibPhysicalFileSizeGrandfatheredForTests)
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
      'check_models_lib_physical_file_size: stale grandfather entries (file no '
      'longer exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }
  if (underCapGrandfathered.isNotEmpty) {
    logE(
      'check_models_lib_physical_file_size: stale grandfather entries (file now '
      'under cap; remove from allowlist):',
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
      'check_models_lib_physical_file_size: no violations found '
      '(ceiling $ceiling; Refs #4136).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_models_lib_physical_file_size: found ${violations.length} '
    'violation(s) under $_modelsLibRelativePath (ceiling $ceiling; '
    'Refs #4136):',
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

  const prefix = '$_modelsLibRelativePath/';
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

int maxModelsLibPhysicalFileLinesForTests() => modelsLibPhysicalFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckModelsLibPhysicalFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
