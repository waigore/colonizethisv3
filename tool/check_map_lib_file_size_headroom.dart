import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_map_lib_file_size.dart' show mapLibFileSizeScanRoots;
import 'ct_repo_lint_scan_contract.dart';

// Wave-8 headroom: gen/view/render ≤250 physical lines (Refs #4654).
// Complements `repo.map_lib_file_size` (500 NCL hard cap).
const int mapLibFileSizeHeadroomCeiling = 250;

const List<String> mapLibFileSizeHeadroomGrandfathered = <String>[];

int runCheckMapLibFileSizeHeadroom(
  String repoRoot, {
  Iterable<String>? scanRoots,
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
  int ceiling = mapLibFileSizeHeadroomCeiling,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final grandfathered =
      (grandfatheredPaths ?? mapLibFileSizeHeadroomGrandfathered)
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
      'check_map_lib_file_size_headroom: stale grandfather entries (file no '
      'longer exists; remove from allowlist):',
    );
    for (final relativePath in missingGrandfathered) {
      logE(' - $relativePath');
    }
    return 1;
  }

  final roots = (scanRoots ?? mapLibFileSizeScanRoots)
      .map((path) => path.replaceAll('\\', '/'))
      .toList(growable: false);

  final missing = <String>[];
  final violations = <String>[];
  for (final relativeRoot in roots) {
    final dir = Directory(p.join(repoRoot, relativeRoot));
    if (!dir.existsSync()) {
      missing.add(relativeRoot);
      continue;
    }
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final relativePath = p
          .relative(entity.path, from: repoRoot)
          .replaceAll('\\', '/');
      if (grandfathered.contains(relativePath)) continue;
      final physicalLines = const LineSplitter()
          .convert(entity.readAsStringSync())
          .length;
      if (physicalLines > ceiling) {
        violations.add(
          '$relativePath ($physicalLines physical lines > $ceiling)',
        );
      }
    }
  }

  if (missing.isNotEmpty) {
    logE(
      'check_map_lib_file_size_headroom: scanned root(s) not found (map lib '
      'layer moved or renamed? update mapLibFileSizeScanRoots):',
    );
    for (final relativeRoot in missing) {
      logE(' - $relativeRoot');
    }
    return 1;
  }

  if (violations.isEmpty) {
    logI('check_map_lib_file_size_headroom: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_map_lib_file_size_headroom: found ${violations.length} violation(s) '
    '(cap $ceiling physical lines; split by concern per '
    'colonizethis-code-review):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main(List<String> args) {
  repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(runCheckMapLibFileSizeHeadroom(Directory.current.path));
}

int maxMapLibFileHeadroomPhysicalLinesForTests() =>
    mapLibFileSizeHeadroomCeiling;
