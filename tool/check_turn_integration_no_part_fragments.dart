import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_turn_no_part_directives.dart';
import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for turn integration tests that must not use Dart
/// `part` / `part of` file splitting (Refs #3876).
const String _turnIntegrationPathPrefix =
    'packages/colonizethis_turn/test/integration/';

/// Legacy segment fragment filenames retired by #3876 integration collapse.
final RegExp _legacySegmentPartFilename = RegExp(
  r'_part\d+_segment\d+_part\.dart$',
);

/// True when [slashPath] is under the turn integration test directory.
bool turnIntegrationNoPartFragmentsPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_turnIntegrationPathPrefix);
}

int runCheckTurnIntegrationNoPartFragments(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnIntegrationNoPartFragmentsPathInScope(rel)) {
      continue;
    }
    final fileName = p.basename(rel);
    final content = file.readAsStringSync();
    if (_legacySegmentPartFilename.hasMatch(fileName)) {
      violations.add('$rel: legacy integration fragment filename (Refs #3876)');
      continue;
    }
    for (final lineNumber in turnNoPartDirectiveLineNumbers(content)) {
      violations.add(
        '$rel:$lineNumber: `part` / `part of` directive is disallowed in '
        '$_turnIntegrationPathPrefix — use nested `group()` in domain '
        'entrypoints (Refs #3876)',
      );
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_turn_integration_no_part_fragments: no integration part-fragment '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_turn_integration_no_part_fragments: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnIntegrationNoPartFragments(Directory.current.path));
}
