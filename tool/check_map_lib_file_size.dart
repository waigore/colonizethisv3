// Map lib non-comment line gate (`repo.map_lib_file_size`).
//
// SPEC: SPEC/program/repo-lint.md (Refs #3588, #3846). The repository-wide
// `repo.dart_file_non_comment_line_size` gate caps every Dart file at 1000
// non-comment lines. This focused gate additionally caps the colonizethis_map
// generation-layer (`lib/src/gen/**`), view-layer (`lib/src/view/**`), and
// render-layer (`lib/src/render/**`) source families at 500 non-comment lines
// so part-file decomposition keeps each pass/concern small and individually
// testable; any regression is flagged with a map-specific message that points
// at the right remediation (split by concern per `colonizethis-code-review`).
//
// The gate asserts all scanned roots exist, so it cannot silently rot if the
// layers move or are renamed (update [mapLibFileSizeScanRoots] in that case).
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;
import 'ct_repo_lint_scan_contract.dart';

const _maxNonCommentLines = 500;

const _mapLibSrc = 'packages/colonizethis_map/lib/src';

/// The gen/view/render source roots gated at or below [_maxNonCommentLines]
/// non-comment lines (Refs #3588, #3846).
const List<String> mapLibFileSizeScanRoots = <String>[
  '$_mapLibSrc/gen',
  '$_mapLibSrc/view',
  '$_mapLibSrc/render',
];

/// Used by `ct_repo_lint`/tests; [info] / [err] default to stdout/stderr.
///
/// [scanRoots] overrides the canonical [mapLibFileSizeScanRoots] set (tests
/// point it at a temp tree). Returns `0` when every scanned root exists and
/// every Dart file under it stays at or below the cap, `1` otherwise.
int runCheckMapLibFileSize(
  String repoRoot, {
  Iterable<String>? scanRoots,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

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
      final nonCommentLines = countNonCommentLinesFromSource(
        entity.readAsStringSync(),
      );
      if (nonCommentLines > _maxNonCommentLines) {
        violations.add(
          '$relativePath ($nonCommentLines non-comment lines > '
          '$_maxNonCommentLines)',
        );
      }
    }
  }

  if (missing.isNotEmpty) {
    logE(
      'check_map_lib_file_size: scanned root(s) not found (map lib layer '
      'moved or renamed? update mapLibFileSizeScanRoots):',
    );
    for (final relativeRoot in missing) {
      logE(' - $relativeRoot');
    }
    return 1;
  }

  if (violations.isEmpty) {
    logI('check_map_lib_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_map_lib_file_size: found ${violations.length} violation(s) '
    '(cap $_maxNonCommentLines non-comment lines; split by concern per '
    'colonizethis-code-review):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

int maxMapLibFileNonCommentLinesForTests() => _maxNonCommentLines;

void main(List<String> args) {
  // Accept (and ignore) the strict `--files` incremental contract for CI
  // uniformity; this is a fixed-root family gate over the gen/view/render layers.
  repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(runCheckMapLibFileSize(Directory.current.path));
}
