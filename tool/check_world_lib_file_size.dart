// Physical line ratchet for colonizethis_world lib source (repo rule:
// `repo.colonizethis_world_lib_file_size`).
//
// Wave 8 (#4611) lowers the general ceiling from wave-7's 300 to 250
// physical lines. Sealed `GameEvent` stays in one library
// (`lib/src/game_events.dart`) with a dedicated 400-line ceiling — splits need
// `part` (banned) or dropping `sealed` (see SPEC/program/game-events.md).
// Generated suffixes are excluded.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// General ratchet ceiling for world lib files except [worldGameEventsRelativePath].
const int worldLibFileSizeCeiling = 250;

/// Dedicated ceiling for sealed `GameEvent` (`lib/src/game_events.dart`).
const int worldGameEventsFileSizeCeiling = 400;

const String _worldLibRelativePath = 'packages/colonizethis_world/lib';

/// Repo-relative path of the sealed `GameEvent` library.
const String worldGameEventsRelativePath =
    'packages/colonizethis_world/lib/src/game_events.dart';

/// Hot files still above the general ceiling during transition slices. Shrink-only
/// allowlist; must stay empty when wave-7 lib ratchet completes.
const List<String> worldLibFileSizeGrandfathered = <String>[];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int ceilingForWorldLibRelativePath(
  String relativePath, {
  int generalCeiling = worldLibFileSizeCeiling,
  int gameEventsCeiling = worldGameEventsFileSizeCeiling,
}) {
  final normalized = relativePath.replaceAll('\\', '/');
  if (normalized == worldGameEventsRelativePath) {
    return gameEventsCeiling;
  }
  return generalCeiling;
}

int runCheckWorldLibFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = worldLibFileSizeCeiling,
  int gameEventsCeiling = worldGameEventsFileSizeCeiling,
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
    final fileCeiling = ceilingForWorldLibRelativePath(
      relativePath,
      generalCeiling: ceiling,
      gameEventsCeiling: gameEventsCeiling,
    );
    final physicalLines = const LineSplitter()
        .convert(file.readAsStringSync())
        .length;
    if (physicalLines <= fileCeiling) {
      continue;
    }
    violations.add(
      '$relativePath ($physicalLines physical lines > $fileCeiling)',
    );
  }

  if (violations.isEmpty) {
    logI(
      'check_world_lib_file_size: no violations found '
      '(ceiling $ceiling, game_events $gameEventsCeiling; Refs #4611).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_world_lib_file_size: found ${violations.length} violation(s) '
    'under $_worldLibRelativePath (wave-7 ceiling $ceiling / '
    'game_events $gameEventsCeiling; Refs #4611):',
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
