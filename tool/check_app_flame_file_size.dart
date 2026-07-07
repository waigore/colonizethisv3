// app/lib/features/game/flame non-comment line limit (`repo.app_flame_file_size`).
//
// SPEC: SPEC/program/dart-file-non-comment-line-size.md (§ app flame 600-line
// gate). Refs #3878 Phase 3.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;
import 'ct_repo_lint_scan_contract.dart';

const _maxNonCommentLines = 600;

const String _flameRelDir = 'app/lib/features/game/flame';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckAppFlameFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final flameDir = Directory(p.join(repoRoot, _flameRelDir));
  if (!flameDir.existsSync()) {
    logE('check_app_flame_file_size: $_flameRelDir not found.');
    return 1;
  }

  final violations = <String>[];
  for (final filePath in _collectFilesToCheck(repoRoot, flameDir, targetFiles)) {
    final file = File(filePath);
    final relativePath = p
        .relative(file.path, from: repoRoot)
        .replaceAll('\\', '/');
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
    logI('check_app_flame_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_app_flame_file_size: found ${violations.length} violation(s) under '
    '$_flameRelDir (cap $_maxNonCommentLines non-comment lines):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

List<String> _collectFilesToCheck(
  String repoRoot,
  Directory flameDir,
  Iterable<String>? targetFiles,
) {
  if (targetFiles == null) {
    return flameDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .map((file) => file.path)
        .where((path) => path.endsWith('.dart'))
        .where((path) => !_generatedSuffix.hasMatch(path))
        .toList(growable: false);
  }

  const prefix = '$_flameRelDir/';
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

int maxAppFlameFileNonCommentLinesForTests() => _maxNonCommentLines;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckAppFlameFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
