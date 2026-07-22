// Wave-4 headroom gate: colonizethis_map gen/view/render modules ≤400 NCL.
// SPEC/program/repo-lint.md (`repo.map_lib_file_size_headroom`, Refs #4112).
//
// Complements `repo.map_lib_file_size` (500 NCL hard cap) with a peer-aligned
// 400 non-comment-line advisory ratchet so near-cap modules gain headroom after
// wave-4 splits without lowering the 500 ceiling.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;
import 'check_map_lib_file_size.dart' show mapLibFileSizeScanRoots;
import 'ct_repo_lint_scan_contract.dart';

const int mapLibFileSizeHeadroomCeiling = 400;

/// Shrink-only allowlist during transition; remove entries as splits land.
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

  final grandfathered = (grandfatheredPaths ?? mapLibFileSizeHeadroomGrandfathered)
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
      final nonCommentLines = countNonCommentLinesFromSource(
        entity.readAsStringSync(),
      );
      if (nonCommentLines > ceiling) {
        violations.add(
          '$relativePath ($nonCommentLines non-comment lines > $ceiling)',
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
    '(cap $ceiling non-comment lines; split by concern per '
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

int maxMapLibFileHeadroomNonCommentLinesForTests() =>
    mapLibFileSizeHeadroomCeiling;
