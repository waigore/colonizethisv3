// Physical line ratchet for colonizethis_data lib source (`repo.data_lib_file_size`).
//
// Wave 7 (#4626) ratchets the wave-6 300 physical-line ceiling to 250 after
// leftover topic splits. Generated suffixes are excluded.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Ratchet ceiling for wave-7 post-split target (≤250 physical lines).
const int dataLibFileSizeCeiling = 250;

const String _dataSrcRelDir = 'packages/colonizethis_data/lib/src';

/// Empty allowlist: every hand-written data `lib/src` file must stay ≤250 physical
/// lines. Override in tests via [grandfatheredPaths].
const List<String> dataFileSizeGrandfatheredForTests = <String>[];

final RegExp _generatedSuffix = RegExp(r'\.(g|freezed|mocks|gen)\.dart$');

int runCheckDataLibFileSize(
  String repoRoot, {
  Iterable<String>? targetFiles,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = dataLibFileSizeCeiling,
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
      'check_data_lib_file_size: no violations found '
      '(ceiling $ceiling; Refs #4412).',
    );
    return 0;
  }

  violations.sort();
  logE(
    'check_data_lib_file_size: found ${violations.length} violation(s) under '
    '$_dataSrcRelDir (wave-7 ceiling $ceiling; Refs #4626):',
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

int maxDataLibFilePhysicalLinesForTests() => dataLibFileSizeCeiling;

void main(List<String> args) {
  final files = repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(
    runCheckDataLibFileSize(
      Directory.current.path,
      targetFiles: files.isEmpty ? null : files,
    ),
  );
}
