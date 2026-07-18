// colonizethis_data non-comment line limit (`repo.data_lib_file_size`).
//
// SPEC: SPEC/program/dart-file-non-comment-line-size.md (§ colonizethis_data
// 500-line gate). Refs #4072.
//
// Complements the repository-wide `repo.dart_file_non_comment_line_size` (1000
// NCL) so the #4072 topic splits (victory-config, tech catalog chunks, combat /
// naming catalogs) cannot silently re-merge into kitchen-sink files.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;
import 'ct_repo_lint_scan_contract.dart';

const _maxNonCommentLines = 500;

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

const String _dataSrcRelDir = 'packages/colonizethis_data/lib/src';

/// Generated embed skipped by the shared repo-wide collector; also out of scope
/// for this package soft gate (Refs #4072).
bool _isGeneratedEmbed(String relativePath) => relativePath
    .replaceAll('\\', '/')
    .endsWith('tech_effect_summary_embed.dart');

/// Empty allowlist: every hand-written data `lib/src` file must stay ≤500 NCL.
/// Override in tests via [grandfatheredPaths].
const List<String> dataFileSizeGrandfatheredForTests = <String>[];

int runCheckDataLibFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final srcDir = Directory(p.join(repoRoot, _dataSrcRelDir));
  if (!srcDir.existsSync()) {
    logE('check_data_lib_file_size: $_dataSrcRelDir not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? dataFileSizeGrandfatheredForTests)
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
      'check_data_lib_file_size: stale grandfather entries (file no longer '
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
    if (_isGeneratedEmbed(relativePath)) {
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
    logI('check_data_lib_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_data_lib_file_size: found ${violations.length} violation(s) under '
    '$_dataSrcRelDir (cap $_maxNonCommentLines non-comment lines):',
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

  const prefix = '$_dataSrcRelDir/';
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

int maxDataLibFileNonCommentLinesForTests() => _maxNonCommentLines;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckDataLibFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
