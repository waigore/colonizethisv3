// Physical line ratchet for colonizethis_world lib source (repo rule:
// `repo.colonizethis_world_lib_file_size`).
//
// Wave 5 (#4125) splits near-cap world modules so lib files stay below a
// peer-aligned 400 physical-line ceiling. Generated suffixes are excluded.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Ratchet ceiling for wave-5 post-split target (≤400 physical lines).
const int worldLibFileSizeCeiling = 400;

const String _worldLibRelativePath = 'packages/colonizethis_world/lib';

/// Hot files still above the wave-5 ceiling during transition slices. Shrink-only
/// allowlist; remove entries as splits land.
const List<String> worldLibFileSizeGrandfathered = <String>[];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckWorldLibFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = worldLibFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _worldLibRelativePath));
  if (!libDir.existsSync()) {
    logE('check_world_lib_file_size: $_worldLibRelativePath not found.');
    return 1;
  }

  final grandfathered = (grandfatheredPaths ?? worldLibFileSizeGrandfathered)
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
      'check_world_lib_file_size: stale grandfather entries (file no longer '
      'exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
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
      'check_world_lib_file_size: no violations found '
      '(ceiling $ceiling; Refs #4125).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_world_lib_file_size: found ${violations.length} violation(s) '
    'under $_worldLibRelativePath (wave-5 ceiling $ceiling; Refs #4125):',
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

  const prefix = '$_worldLibRelativePath/';
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

int maxWorldLibFilePhysicalLinesForTests() => worldLibFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckWorldLibFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
