import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the `buildInitGameMapViewData` view-builder
/// test suite. Files matching `init_game_map_view_builder_*` under the map
/// package `test/` must build their dual-region scaffolding through the shared
/// `test/support/init_game_map_view_fixtures.dart` builders (`minimalGame`,
/// `regionTopology` / `singleProvinceAndSeaTopology`, `mapTileGrid`) rather than
/// re-inlining `Game(...)` + `MapTopology(...)` boilerplate. Refs #3746.
const String _mapViewBuilderTestPathPrefix =
    'packages/colonizethis_map/test/init_game_map_view_builder_';

/// Canonical shared support file the view-builder tests must use instead of
/// inline dual-region scaffolding.
const String mapTestViewFixturesImport =
    'support/init_game_map_view_fixtures.dart';

/// Matches an inline `Game(` constructor call (not `minimalGame(`, which has no
/// word boundary before `Game`).
final RegExp _inlineGameConstructor = RegExp(r'\bGame\(');

/// Matches an inline `MapTopology(` constructor call (not `regionTopology(` /
/// `singleProvinceAndSeaTopology(`, which have no word boundary before
/// `MapTopology`).
final RegExp _inlineMapTopologyConstructor = RegExp(r'\bMapTopology\(');

/// True when repo-relative [slashPath] is one of the map view-builder test
/// files (`init_game_map_view_builder_*` under the map package `test/`).
bool mapTestNoDuplicateViewFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_mapViewBuilderTestPathPrefix);
}

/// Returns a violation reason when the in-scope view-builder test [content]
/// re-inlines the dual-region scaffolding instead of importing the shared
/// support file, or `null` when compliant.
///
/// A file is flagged only when it both renders a view
/// (`buildInitGameMapViewData(`) and still constructs the dual-region
/// scaffolding inline (`Game(` or `MapTopology(`). Tests that route through the
/// shared `minimalGame` / `regionTopology` builders contain neither inline
/// constructor and pass. Full-line comments are stripped first so prose
/// mentioning the constructors is not flagged.
String? mapTestDuplicateViewFixturesViolationReason(
  String slashPath,
  String content,
) {
  if (!mapTestNoDuplicateViewFixturesPathInScope(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  if (!code.contains('buildInitGameMapViewData(')) {
    return null;
  }
  final inlineGame = _inlineGameConstructor.hasMatch(code);
  final inlineTopology = _inlineMapTopologyConstructor.hasMatch(code);
  if (!inlineGame && !inlineTopology) {
    return null;
  }
  final parts = <String>[
    if (inlineGame) 'Game(...)',
    if (inlineTopology) 'MapTopology(...)',
  ];
  return "re-inlines dual-region view scaffolding (${parts.join(' + ')}); use "
      "the shared builders from '$mapTestViewFixturesImport' "
      '(minimalGame / regionTopology) instead (Refs #3746)';
}

/// Removes full-line `//` / `///` comment lines and `*` doc/block continuations
/// so constructor names mentioned in prose do not trip the scan.
String _stripLineComments(String content) {
  final out = StringBuffer();
  for (final line in content.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//') || trimmed.startsWith('*')) {
      continue;
    }
    out.writeln(line);
  }
  return out.toString();
}

int runCheckMapTestNoDuplicateViewFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!mapTestNoDuplicateViewFixturesPathInScope(rel)) {
      continue;
    }
    final reason = mapTestDuplicateViewFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_map_test_no_duplicate_view_fixtures: no inline view-scaffolding '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_map_test_no_duplicate_view_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckMapTestNoDuplicateViewFixtures(Directory.current.path));
}
