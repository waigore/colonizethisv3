import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose `lib/` Dart sources must not reintroduce
/// Dart `part` / `part of` file-splitting (Refs #4068). The models package
/// Phase-5 `orders` / `world_state` / `world_market` / `app_events` trees were
/// converted to explicit-import libraries; this gate keeps new sub-files as
/// proper libraries.
const String _modelsLibPathPrefix = 'packages/colonizethis_models/lib/';

/// True when the repo-relative [slashPath] is under the models package `lib/`.
bool modelsNoPartDirectivesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_modelsLibPathPrefix);
}

/// True when [trimmedLine] (already trimmed of leading whitespace) is a Dart
/// `part` or `part of` directive that references another library file.
bool modelsNoPartDirectivesLineIsPartDirective(String trimmedLine) {
  if (!trimmedLine.startsWith('part')) {
    return false;
  }
  return RegExp(r'''^part\s+(of\s+)?['"]''').hasMatch(trimmedLine);
}

/// Returns the 1-based line numbers in [content] that carry a `part` /
/// `part of` directive (skipping blank and line-comment lines).
List<int> modelsNoPartDirectiveLineNumbers(String content) {
  final out = <int>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trimLeft();
    if (line.isEmpty || line.startsWith('//')) {
      continue;
    }
    if (modelsNoPartDirectivesLineIsPartDirective(line)) {
      out.add(i + 1);
    }
  }
  return out;
}

int runCheckModelsNoPartDirectives(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!modelsNoPartDirectivesPathInScope(rel)) {
      continue;
    }
    final lineNumbers = modelsNoPartDirectiveLineNumbers(
      file.readAsStringSync(),
    );
    for (final lineNumber in lineNumbers) {
      violations.add(
        '$rel:$lineNumber: `part` / `part of` directive is disallowed in '
        '$_modelsLibPathPrefix — split sub-files into proper libraries with '
        'explicit imports (Refs #4068)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_models_no_part_directives: no part-directive violations.');
    return 0;
  }
  logE('check_models_no_part_directives: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckModelsNoPartDirectives(Directory.current.path));
}
