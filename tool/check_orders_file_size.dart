// Orders hot-file non-comment line gate (`repo.orders_file_size`).
//
// SPEC: SPEC/program/repo-lint.md (Refs #3404). The repository-wide
// `repo.dart_file_non_comment_line_size` gate caps every Dart file at 1000
// non-comment lines. This focused gate additionally *names* the two orders
// hot files — `orders_application.dart` and `orders_application_completed_work
// .dart` — so the #3404 dedup/abstraction refactors keep them bounded and any
// regression on either is flagged with an orders-specific message that points
// at the right remediation (split by concern per `colonizethis-code-review`).
//
// The gate asserts both named files exist, so it cannot silently rot if the
// orders module moves or the files are renamed (update [ordersFileSizeGatedFiles]
// in that case).
import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_dart_file_non_comment_line_size.dart'
    show countNonCommentLinesFromSource;
import 'ct_repo_lint_scan_contract.dart';

const _maxNonCommentLines = 1000;

const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

/// The orders hot files gated at or below [_maxNonCommentLines] non-comment
/// lines (Refs #3404 AC: orders_application/orders_application_completed_work
/// stay ≤1000 non-comment lines after the dedup/abstraction refactors).
const List<String> ordersFileSizeGatedFiles = <String>[
  '$_ordersLibDir/orders_application.dart',
  '$_ordersLibDir/orders_application_completed_work.dart',
];

/// Used by `ct_repo_lint`/tests; [info] / [err] default to stdout/stderr.
///
/// [gatedFiles] overrides the canonical [ordersFileSizeGatedFiles] set (tests
/// point it at a temp tree). Returns `0` when every gated file exists and stays
/// at or below the cap, `1` otherwise.
int runCheckOrdersFileSize(
  String repoRoot, {
  Iterable<String>? gatedFiles,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final gated = (gatedFiles ?? ordersFileSizeGatedFiles)
      .map((path) => path.replaceAll('\\', '/'))
      .toList(growable: false);

  final missing = <String>[];
  final violations = <String>[];
  for (final relativePath in gated) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      missing.add(relativePath);
      continue;
    }
    final nonCommentLines = countNonCommentLinesFromSource(
      file.readAsStringSync(),
    );
    if (nonCommentLines > _maxNonCommentLines) {
      violations.add(
        '$relativePath ($nonCommentLines non-comment lines > '
        '$_maxNonCommentLines)',
      );
    }
  }

  if (missing.isNotEmpty) {
    logE(
      'check_orders_file_size: gated file(s) not found (orders module moved or '
      'renamed? update ordersFileSizeGatedFiles):',
    );
    for (final relativePath in missing) {
      logE(' - $relativePath');
    }
    return 1;
  }

  if (violations.isEmpty) {
    logI('check_orders_file_size: no violations found.');
    return 0;
  }

  violations.sort();
  logE(
    'check_orders_file_size: found ${violations.length} violation(s) '
    '(cap $_maxNonCommentLines non-comment lines; split by concern per '
    'colonizethis-code-review):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

int maxOrdersFileNonCommentLinesForTests() => _maxNonCommentLines;

void main(List<String> args) {
  // Accept (and ignore) the strict `--files` incremental contract for CI
  // uniformity; this is a fixed-set gate over the two named orders hot files.
  repoLintStrictIncrementalFilesArgListOrExit(args);
  exit(runCheckOrdersFileSize(Directory.current.path));
}
