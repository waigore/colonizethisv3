// colonizethis_models non-comment line limit (`repo.models_file_size`).
//
// SPEC: SPEC/program/dart-file-non-comment-line-size.md (§ colonizethis_models
// 500-line gate). Refs #3393 Phase 5; grandfather cleared Refs #4068.
//
// The repository-wide `repo.dart_file_non_comment_line_size` gate caps every
// Dart file at 1000 non-comment lines. `colonizethis_models` holds the shared
// value-model surface consumed by every other package, so it carries a tighter
// 500 non-comment-line cap (mirroring `repo.domain_package_source_file_size`'s
// 500-physical-line cap for the split domain packages). Phase 5 split the three
// largest offenders (`app_events.dart`, `world_market.dart`, `orders.dart`) into
// `part` files below the cap; Slice A (Refs #4068) extracted `VictoryState` /
// shared collection equality so `game.dart` also stays under the cap with an
// empty grandfather list.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;
import 'ct_repo_lint_scan_contract.dart';

const _maxNonCommentLines = 500;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

const String _modelsSrcRelDir = 'packages/colonizethis_models/lib/src';

/// Formerly held over-cap models paths (Refs #3393). Cleared when `game.dart`
/// dropped under 500 NCL (Refs #4068). Kept as an empty allowlist so stale-entry
/// checks and override tests remain meaningful.
const List<String> modelsFileSizeGrandfatheredForTests = <String>[];

int runCheckModelsFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final srcDir = Directory(p.join(repoRoot, _modelsSrcRelDir));
  if (!srcDir.existsSync()) {
    logE('check_models_file_size: $_modelsSrcRelDir not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? modelsFileSizeGrandfatheredForTests)
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
      'check_models_file_size: stale grandfather entries (file no longer '
      'exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, srcDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
    if (grandfathered.contains(relativePath)) {
      continue;
    }
    final nonCommentLines = countNonCommentLinesFromSource(
      file.readAsStringSync(),
    );
    if (nonCommentLines <= _maxNonCommentLines) {
      continue;
    }
    violations.add(
      '$relativePath ($nonCommentLines non-comment lines > '
      '$_maxNonCommentLines)',
    );
  }

  if (violations.isEmpty) {
    logI('check_models_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_models_file_size: found ${violations.length} violation(s) under '
    '$_modelsSrcRelDir (cap $_maxNonCommentLines non-comment lines):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory srcDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return srcDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  const prefix = '$_modelsSrcRelDir/';
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

int maxModelsFileNonCommentLinesForTests() => _maxNonCommentLines;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckModelsFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
