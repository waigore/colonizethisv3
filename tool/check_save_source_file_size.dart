// Physical line ratchet for colonizethis_save lib/src
// (`repo.save_source_file_size`). Refs #4077.
//
// Complements the repository-wide 1000 NCL gate so the GameSaveAdapter concern
// splits cannot silently re-merge into a kitchen-sink module.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

const int saveSourceFileSizeCeiling = 400;

const String _saveSrcRelDir = 'packages/colonizethis_save/lib/src';

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

/// Empty allowlist: every save `lib/src` file must stay ≤400 physical lines.
/// Override in tests via [grandfatheredPaths].
const List<String> saveSourceFileSizeGrandfatheredForTests = <String>[];

int runCheckSaveSourceFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = saveSourceFileSizeCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final srcDir = Directory(p.join(repoRoot, _saveSrcRelDir));
  if (!srcDir.existsSync()) {
    logE('check_save_source_file_size: $_saveSrcRelDir not found.');
    return 1;
  }

  final grandfathered =
      (grandfatheredPaths ?? saveSourceFileSizeGrandfatheredForTests)
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
      'check_save_source_file_size: stale grandfather entries (file no longer '
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
      'check_save_source_file_size: no violations found '
      '(ceiling $ceiling; Refs #4077).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_save_source_file_size: found ${violations.length} violation(s) '
    'under $_saveSrcRelDir (ceiling $ceiling; Refs #4077):',
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

  const prefix = '$_saveSrcRelDir/';
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

int maxSaveSourceFilePhysicalLinesForTests() => saveSourceFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckSaveSourceFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
