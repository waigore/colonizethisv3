import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose `lib/` Dart sources must not reintroduce
/// Dart `part` / `part of` file-splitting (Refs #4079). The AI package Phase-9
/// planning/perception clusters were converted to explicit-import libraries;
/// this gate keeps new sub-files as proper libraries.
const String aiNoPartDirectivesLibPathPrefix = 'packages/colonizethis_ai/lib/';

/// Repo-relative path prefix for `colonizethis_ai_contracts` (Refs #4084).
const String aiContractsNoPartDirectivesLibPathPrefix =
    'packages/colonizethis_ai_contracts/lib/';

/// True when the repo-relative [slashPath] starts with [libPathPrefix].
bool noPartDirectivesPathInScope(String slashPath, String libPathPrefix) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(libPathPrefix);
}

/// True when the repo-relative [slashPath] is under the AI package `lib/`.
bool aiNoPartDirectivesPathInScope(String slashPath) =>
    noPartDirectivesPathInScope(slashPath, aiNoPartDirectivesLibPathPrefix);

/// True when the repo-relative [slashPath] is under the AI contracts `lib/`.
bool aiContractsNoPartDirectivesPathInScope(String slashPath) =>
    noPartDirectivesPathInScope(
      slashPath,
      aiContractsNoPartDirectivesLibPathPrefix,
    );

/// True when [trimmedLine] (already trimmed of leading whitespace) is a Dart
/// `part` or `part of` directive that references another library file.
bool aiNoPartDirectivesLineIsPartDirective(String trimmedLine) {
  if (!trimmedLine.startsWith('part')) {
    return false;
  }
  return RegExp(r'''^part\s+(of\s+)?['"]''').hasMatch(trimmedLine);
}

/// Returns the 1-based line numbers in [content] that carry a `part` /
/// `part of` directive (skipping blank and line-comment lines).
List<int> aiNoPartDirectiveLineNumbers(String content) {
  final out = <int>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.isEmpty || line.startsWith('//')) {
      continue;
    }
    if (aiNoPartDirectivesLineIsPartDirective(line)) {
      out.add(i + 1);
    }
  }
  return out;
}

/// Shared scanner: fail when any Dart file under [libPathPrefix] contains a
/// `part` / `part of` directive.
int runCheckNoPartDirectivesForLibPrefix(
  String repoRoot, {
  required String libPathPrefix,
  required String checkerLabel,
  required String refsIssue,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!noPartDirectivesPathInScope(rel, libPathPrefix)) {
      continue;
    }
    final lineNumbers = aiNoPartDirectiveLineNumbers(
      file.readAsStringSync(),
    );
    for (final lineNumber in lineNumbers) {
      violations.add(
        '$rel:$lineNumber: `part` / `part of` directive is disallowed in '
        '$libPathPrefix — split sub-files into proper libraries with '
        'explicit imports (Refs $refsIssue)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('$checkerLabel: no part-directive violations.');
    return 0;
  }
  logE('$checkerLabel: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

int runCheckAiNoPartDirectives(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  return runCheckNoPartDirectivesForLibPrefix(
    repoRoot,
    libPathPrefix: aiNoPartDirectivesLibPathPrefix,
    checkerLabel: 'check_ai_no_part_directives',
    refsIssue: '#4079',
    info: info,
    err: err,
  );
}

int runCheckAiContractsNoPartDirectives(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  return runCheckNoPartDirectivesForLibPrefix(
    repoRoot,
    libPathPrefix: aiContractsNoPartDirectivesLibPathPrefix,
    checkerLabel: 'check_ai_contracts_no_part_directives',
    refsIssue: '#4084',
    info: info,
    err: err,
  );
}

void main() {
  exit(runCheckAiNoPartDirectives(Directory.current.path));
}
