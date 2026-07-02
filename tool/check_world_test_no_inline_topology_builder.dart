import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must not add new inline topology
/// scaffolding outside the shared builders (Refs #3843).
const String _worldTestPathPrefix = 'packages/colonizethis_world/test/';

/// Shared topology/tile builders live here; inline `MapTopology(` /
/// `TileMapResult(` constructors are allowed only in this tree.
const String _worldTestSupportPathInfix = '/world_test_support/';

/// Canonical shared support import path for world connectivity/fog tests.
const String worldTestSupportImport = 'world_test_support/';

/// Files that still inline topology constructors before the migration
/// completes. New test files must use `world_test_support/` builders instead.
const Set<String> _grandfatheredInlineTopologyTestPaths = {
  'packages/colonizethis_world/test/naval_coastal_visibility_test.dart',
  'packages/colonizethis_world/test/topology_for_region_test.dart',
  'packages/colonizethis_world/test/topology_helpers_test.dart',
  'packages/colonizethis_world/test/utils/bfs_topology_graph_test.dart',
  'packages/colonizethis_world/test/world/army_movement_test.dart',
  'packages/colonizethis_world/test/world/capital_reassignment_part.dart',
  'packages/colonizethis_world/test/world/capital_test.dart',
  'packages/colonizethis_world/test/world/connectivity_metrics_threading_test.dart',
  'packages/colonizethis_world/test/world/connectivity_resolver_blockade_cross_region_part.dart',
  'packages/colonizethis_world/test/world/connectivity_resolver_blockade_missions_part.dart',
  'packages/colonizethis_world/test/world/connectivity_resolver_blockade_part.dart',
  'packages/colonizethis_world/test/world/connectivity_resolver_non_gp_capital_part.dart',
  'packages/colonizethis_world/test/world/connectivity_resolver_non_gp_part.dart',
  'packages/colonizethis_world/test/world/fog_resolution_distant_sea_integration_part.dart',
  'packages/colonizethis_world/test/world/fog_resolution_distant_sea_part.dart',
  'packages/colonizethis_world/test/world/fog_resolution_initial_visibility_part.dart',
  'packages/colonizethis_world/test/world/fog_resolution_spy_clear_part.dart',
  'packages/colonizethis_world/test/world/movement_helpers_test.dart',
  'packages/colonizethis_world/test/world/naval_home_fleet_split_movement_resolve_integration_test.dart',
  'packages/colonizethis_world/test/world/naval_topology_test.dart',
  'packages/colonizethis_world/test/world/player_view_build_test.dart',
  'packages/colonizethis_world/test/world/sea_reachable_provinces_test.dart',
};

final RegExp _inlineMapTopologyConstructor = RegExp(r'\bMapTopology\(');
final RegExp _inlineTileMapResultConstructor = RegExp(r'\bTileMapResult\(');

/// True when [slashPath] is a world-package test file subject to the inline
/// topology gate (excludes `world_test_support/`).
bool worldTestNoInlineTopologyBuilderPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_worldTestPathPrefix)) {
    return false;
  }
  if (normalized.contains(_worldTestSupportPathInfix)) {
    return false;
  }
  return true;
}

/// Returns a violation reason when [content] re-inlines topology scaffolding
/// outside the grandfathered allowlist, or `null` when compliant.
String? worldTestInlineTopologyBuilderViolationReason(
  String slashPath,
  String content,
) {
  if (!worldTestNoInlineTopologyBuilderPathInScope(slashPath)) {
    return null;
  }
  if (_grandfatheredInlineTopologyTestPaths.contains(slashPath)) {
    return null;
  }
  final code = _stripLineComments(content);
  final inlineTopology = _inlineMapTopologyConstructor.hasMatch(code);
  final inlineTileMap = _inlineTileMapResultConstructor.hasMatch(code);
  if (!inlineTopology && !inlineTileMap) {
    return null;
  }
  final parts = <String>[
    if (inlineTopology) 'MapTopology(...)',
    if (inlineTileMap) 'TileMapResult(...)',
  ];
  return "re-inlines topology scaffolding (${parts.join(' + ')}); use shared "
      "builders from '$worldTestSupportImport' instead (Refs #3843)";
}

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

int runCheckWorldTestNoInlineTopologyBuilder(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = worldTestInlineTopologyBuilderViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_world_test_no_inline_topology_builder: no new inline-topology '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_world_test_no_inline_topology_builder: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckWorldTestNoInlineTopologyBuilder(Directory.current.path));
}
