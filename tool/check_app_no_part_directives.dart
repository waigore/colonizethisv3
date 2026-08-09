import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_no_part_directives_grandfather.dart';
import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose `lib/` Dart sources must not reintroduce
/// Dart `part` / `part of` file-splitting (Refs #4117). The app package still
/// has legacy `part` clusters mid-migration; this gate blocks new part
/// directives outside the shrink-only grandfather allowlist.
const String appNoPartDirectivesLibPathPrefix = 'app/lib/';

/// Production grandfather allowlist (shrink-only as de-part slices land).
const List<String> appNoPartDirectivesGrandfathered =
    appNoPartDirectivesGrandfatheredForTests;

/// True when the repo-relative [slashPath] is under the app package `lib/`.
bool appNoPartDirectivesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(appNoPartDirectivesLibPathPrefix);
}

/// True when [trimmedLine] (already trimmed of leading whitespace) is a Dart
/// `part` or `part of` directive that references another library file.
bool appNoPartDirectivesLineIsPartDirective(String trimmedLine) {
  if (!trimmedLine.startsWith('part')) {
    return false;
  }
  return RegExp(r'''^part\s+(of\s+)?['"]''').hasMatch(trimmedLine);
}

/// Returns the 1-based line numbers in [content] that carry a `part` /
/// `part of` directive (skipping blank and line-comment lines).
List<int> appNoPartDirectiveLineNumbers(String content) {
  final out = <int>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.isEmpty || line.startsWith('//')) {
      continue;
    }
    if (appNoPartDirectivesLineIsPartDirective(line)) {
      out.add(i + 1);
    }
  }
  return out;
}

bool appNoPartDirectivesFileHasPartDirective(String content) =>
    appNoPartDirectiveLineNumbers(content).isNotEmpty;

int runCheckAppNoPartDirectives(
  String repoRoot, {
  Iterable<String>? grandfatheredPaths,
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final grandfathered = (grandfatheredPaths ?? appNoPartDirectivesGrandfathered)
      .map((path) => path.replaceAll('\\', '/'))
      .toSet();

  final stale = <String>[];
  for (final relativePath in grandfathered) {
    final file = File(p.join(repoRoot, relativePath));
    if (!file.existsSync()) {
      stale.add('$relativePath (missing)');
      continue;
    }
    if (!appNoPartDirectivesFileHasPartDirective(file.readAsStringSync())) {
      stale.add(
        '$relativePath (no part directive; remove from allowlist)',
      );
    }
  }
  if (stale.isNotEmpty) {
    final sorted = stale.toList()..sort();
    logE(
      'check_app_no_part_directives: stale grandfather entries '
      '(must shrink):',
    );
    for (final entry in sorted) {
      logE(' - $entry');
    }
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!appNoPartDirectivesPathInScope(rel)) {
      continue;
    }
    if (grandfathered.contains(rel)) {
      continue;
    }
    final lineNumbers = appNoPartDirectiveLineNumbers(
      file.readAsStringSync(),
    );
    for (final lineNumber in lineNumbers) {
      violations.add(
        '$rel:$lineNumber: `part` / `part of` directive is disallowed in '
        '$appNoPartDirectivesLibPathPrefix outside the shrink-only '
        'grandfather allowlist — split sub-files into proper libraries with '
        'explicit imports (Refs #4117)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_app_no_part_directives: no part-directive violations.');
    return 0;
  }
  logE('check_app_no_part_directives: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAppNoPartDirectives(Directory.current.path));
}
