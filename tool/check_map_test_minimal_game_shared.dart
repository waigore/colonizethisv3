import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4022).
///
/// Forbid inline `Game(` in scoped colour/capital/region-input/format/port
/// suites. Those tests must build dual-region empty games via
/// `minimalGame` / shared support under
/// `test/support/init_game_map_view_fixtures.dart`.
const Set<String> mapTestMinimalGameSharedScopedFiles = {
  'packages/colonizethis_map/test/faction_ownership_color_test.dart',
  'packages/colonizethis_map/test/tile_map_capital_markers_test.dart',
  'packages/colonizethis_map/test/region_map_view_inputs_test.dart',
  'packages/colonizethis_map/test/map_format_util_test.dart',
  'packages/colonizethis_map/test/port_icon_placement_test.dart',
  'packages/colonizethis_map/test/town_icon_style_test.dart',
  'packages/colonizethis_map/test/game_world_state_map_visualizer_test.dart',
};

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');

bool mapTestMinimalGameSharedPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return mapTestMinimalGameSharedScopedFiles.contains(normalized);
}

String? mapTestMinimalGameSharedViolationReason(String content) {
  // Strip full-line comments so prose mentioning Game( is not flagged.
  final withoutFullLineComments = content
      .split('\n')
      .where((line) {
        final trimmed = line.trimLeft();
        return !trimmed.startsWith('//') && !trimmed.startsWith('*');
      })
      .join('\n');
  if (_inlineGameConstructor.hasMatch(withoutFullLineComments)) {
    return 'use minimalGame from test/support/init_game_map_view_fixtures.dart '
        'instead of inline Game(...) (Refs #4022)';
  }
  return null;
}

int runCheckMapTestMinimalGameShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!mapTestMinimalGameSharedPathInScope(rel)) {
      continue;
    }
    final reason = mapTestMinimalGameSharedViolationReason(
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_map_test_minimal_game_shared: no inline Game(...) violations.');
    return 0;
  }

  logE(
    'check_map_test_minimal_game_shared: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckMapTestMinimalGameShared(Directory.current.path));
}
