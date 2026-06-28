import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup-package test sources must reuse the production province-adjacency and
/// connected-components helpers instead of byte-identical reimplementations
/// (Refs #3740). `init_game_orchestrator_test_support.dart` previously carried
/// `_provincePpNeighboursForInitGameTest` (a clone of production
/// `provinceNeighboursFromTopology`) and `_landComponentsFromPpNeighbours` (a
/// clone of `connectedComponentsInSubset`). This gate keeps such reimplementations
/// from returning — the `colonizethis_*` packages model the equivalent
/// production-helper-reuse gates (e.g. `check_ai_test_no_duplicate_scaffolding`),
/// and setup had none.
const String _setupTestPathPrefix = 'packages/colonizethis_setup/test/';

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupTestNoDuplicateScaffolding(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, 'packages/colonizethis_setup/test'));
  if (!dir.existsSync()) {
    logI(
      'Setup test no-duplicate-scaffolding check skipped (test dir absent).',
    );
    return 0;
  }

  final violations = <SetupTestScaffoldingViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final slashPath = p.relative(entity.path, from: root).replaceAll('\\', '/');
    final reason = setupTestDuplicateScaffoldingViolationReason(
      slashPath,
      entity.readAsStringSync(),
    );
    if (reason != null) {
      violations.add(
        SetupTestScaffoldingViolation(path: slashPath, message: reason),
      );
    }
  }

  if (violations.isEmpty) {
    logI('Setup test no-duplicate-scaffolding check passed.');
    return 0;
  }

  logE(
    'ERROR: Setup test sources must reuse production helpers '
    '(provinceNeighboursFromTopology, connectedComponentsInSubset) instead of '
    'reimplementing province adjacency / connected components.',
  );
  for (final v in violations) {
    logE('${v.path} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupTestNoDuplicateScaffolding(Directory.current.path));
}

/// True when repo-relative [slashPath] is under the setup package `test/` tree.
bool setupTestNoDuplicateScaffoldingPathInScope(String slashPath) =>
    slashPath.replaceAll('\\', '/').startsWith(_setupTestPathPrefix);

/// Returns a violation reason when [content] of an in-scope setup test file
/// reimplements a production scaffolding helper, or `null` when compliant.
///
/// Two regressions are blocked:
/// 1. A province–province neighbours builder cloned from
///    `provinceNeighboursFromTopology` — recognised by scanning `topology` edges
///    (`.edges`) while filtering province nodes (`TopologyNodeType.province`) to
///    build a `Map<String, Set<String>>` adjacency.
/// 2. A connected-components routine cloned from `connectedComponentsInSubset` —
///    recognised by a `<Set<String>>[]` component accumulator paired with a
///    `visited` set.
///
/// Full-line `//` comments are stripped first so prose mentioning the helpers is
/// not flagged.
String? setupTestDuplicateScaffoldingViolationReason(
  String slashPath,
  String content,
) {
  if (!setupTestNoDuplicateScaffoldingPathInScope(slashPath)) return null;
  final code = _stripLineComments(content);

  final reimplementsNeighbours =
      code.contains('.edges') &&
      code.contains('TopologyNodeType.province') &&
      RegExp(r'Set<String>>').hasMatch(code);
  if (reimplementsNeighbours) {
    return 'reimplements province–province adjacency; reuse '
        'provinceNeighboursFromTopology (Refs #3740)';
  }

  final reimplementsComponents =
      RegExp(r'<Set<String>>\s*\[\s*\]').hasMatch(code) &&
      RegExp(r'\bvisited\b').hasMatch(code);
  if (reimplementsComponents) {
    return 'reimplements connected components; reuse '
        'connectedComponentsInSubset (Refs #3740)';
  }
  return null;
}

/// Removes full-line `//` (and `///`) comment lines and `*` doc/block
/// continuations so helper names mentioned in prose do not trip the scan.
String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
    out.writeln(line);
  }
  return out.toString();
}

class SetupTestScaffoldingViolation {
  const SetupTestScaffoldingViolation({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;
}
