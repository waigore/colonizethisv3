import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose `lib/` Dart sources must not reintroduce
/// Dart `part` / `part of` file-splitting (Refs #3543). The orders package was
/// converted from `part of` fragments (suggestion libraries, validation
/// pipeline, incremental validator, and the generated order-engine slots) to
/// explicit-import libraries; this gate keeps new sub-files as proper
/// libraries.
const String _ordersLibPathPrefix = 'packages/colonizethis_orders/lib/';

/// True when the repo-relative [slashPath] is under the orders package `lib/`.
bool ordersNoPartDirectivesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersLibPathPrefix);
}

/// True when [trimmedLine] (already trimmed of leading whitespace) is a Dart
/// `part` or `part of` directive that references another library file, e.g.
/// `part 'foo.dart';` or `part of 'foo.dart';`. Line comments are excluded by
/// the caller.
bool ordersNoPartDirectivesLineIsPartDirective(String trimmedLine) {
  if (!trimmedLine.startsWith('part')) {
    return false;
  }
  // Require a directive form: `part '...` or `part of '...` (single or double
  // quote). This excludes identifiers such as `participants` or `partition`.
  return RegExp(r'''^part\s+(of\s+)?['"]''').hasMatch(trimmedLine);
}

/// Returns the 1-based line numbers in [content] that carry a `part` /
/// `part of` directive (skipping blank and line-comment lines).
List<int> ordersNoPartDirectiveLineNumbers(String content) {
  final out = <int>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.isEmpty || line.startsWith('//')) {
      continue;
    }
    if (ordersNoPartDirectivesLineIsPartDirective(line)) {
      out.add(i + 1);
    }
  }
  return out;
}

int runCheckOrdersNoPartDirectives(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!ordersNoPartDirectivesPathInScope(rel)) {
      continue;
    }
    final lineNumbers = ordersNoPartDirectiveLineNumbers(
      file.readAsStringSync(),
    );
    for (final lineNumber in lineNumbers) {
      violations.add(
        '$rel:$lineNumber: `part` / `part of` directive is disallowed in '
        '$_ordersLibPathPrefix — split sub-files into proper libraries with '
        'explicit imports (Refs #3543)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_orders_no_part_directives: no part-directive violations.');
    return 0;
  }
  logE('check_orders_no_part_directives: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersNoPartDirectives(Directory.current.path));
}
