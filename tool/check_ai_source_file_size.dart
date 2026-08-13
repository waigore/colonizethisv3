// Physical line ratchet for colonizethis_ai lib/src
// (`repo.ai_source_file_size`). Refs #4079 Slice C; headroom ratchet Refs #4104
// Slice B / #4239 Slice A / #4310 Slice B / #4365 Slice A (optional 300).
//
// Complements the repository-wide 1000 NCL gate and the AI no-part gate so
// Phase-9/10 planning concern splits cannot silently re-merge into kitchen-sink
// modules. Ceiling is **300** physical lines (stricter than
// `repo.domain_package_source_file_size` 500). Shrink-only grandfather allowlist
// fails when entries are missing or the named file is now under-cap (same
// pattern as save/data).
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const int aiSourceFileSizeCeiling = 300;

const String _aiSrcRelDir = 'packages/colonizethis_ai/lib/src';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// Empty allowlist after #4079 / #4104 / #4239 / #4310 / #4365 splits: every AI
/// `lib/src` file must stay ≤300 physical lines. Override in tests via
/// [grandfatheredPaths].
const List<String> aiSourceFileSizeGrandfatheredForTests = <String>[];

int runCheckAiSourceFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = aiSourceFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final srcDir = Directory(p.join(repoRoot, _aiSrcRelDir));
  if (!srcDir.existsSync()) {
    logE('check_ai_source_file_size: $_aiSrcRelDir not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? aiSourceFileSizeGrandfatheredForTests)
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
      'check_ai_source_file_size: stale grandfather entries (file no longer '
      'exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }
  if (underCapGrandfathered.isNotEmpty) {
    logE(
      'check_ai_source_file_size: stale grandfather entries (file now under '
      'cap; remove from allowlist):',
    );
    for (final entry in underCapGrandfathered) {
      logE(' - $entry');
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
      'check_ai_source_file_size: no violations found '
      '(ceiling $ceiling; Refs #4365).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_ai_source_file_size: found ${violations.length} violation(s) '
    'under $_aiSrcRelDir (ceiling $ceiling; Refs #4365):',
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

  const prefix = '$_aiSrcRelDir/';
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

int maxAiSourceFilePhysicalLinesForTests() => aiSourceFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckAiSourceFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
