import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative paths fully exempt from inline `TopologyNode(` checks.
const Set<String> mapTestSharedTopologyFixturesExemptFiles = {
  'packages/colonizethis_map/test/tile_map_topology_validation_test.dart',
};

/// Marker on the line immediately before an intentional inline `TopologyNode(`.
const String mapTopologyFixtureExemptMarkerPrefix =
    '// map-topology-fixture-exempt:';

final RegExp _inlineTopologyNode = RegExp(r'\bTopologyNode\(');

/// True when [slashPath] is scanned for inline topology fixtures (Refs #3846).
bool mapTestSharedTopologyFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (normalized.startsWith('packages/colonizethis_map/test/support/')) {
    return false;
  }
  if (normalized.contains('_fixtures.dart')) {
    return false;
  }
  if (mapTestSharedTopologyFixturesExemptFiles.contains(normalized)) {
    return false;
  }
  final base = p.basename(normalized);
  if (base.contains('_validation') && base.endsWith('_test.dart')) {
    return false;
  }
  if (normalized.startsWith('packages/colonizethis_map/test/tile_map_visualization_')) {
    return true;
  }
  if (normalized ==
      'packages/colonizethis_map/test/game_world_state_map_visualizer_test.dart') {
    return true;
  }
  if (normalized ==
      'packages/colonizethis_map/test/multi_region_map_rendering_test.dart') {
    return true;
  }
  return false;
}

/// Returns a violation reason when [content] contains unallowlisted inline
/// `TopologyNode(` in an in-scope file, or `null` when compliant.
String? mapTestSharedTopologyFixturesViolationReason(
  String slashPath,
  String content,
) {
  if (!mapTestSharedTopologyFixturesPathInScope(slashPath)) {
    return null;
  }
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!_inlineTopologyNode.hasMatch(line)) {
      continue;
    }
    if (i > 0 &&
        lines[i - 1].trim().startsWith(mapTopologyFixtureExemptMarkerPrefix)) {
      continue;
    }
    return 'inline TopologyNode( at line ${i + 1}; use shared builders from '
        "test/support/init_game_map_view_fixtures.dart or add "
        "'$mapTopologyFixtureExemptMarkerPrefix <reason>' on the preceding "
        'line for intentional malformed-graph topology (Refs #3846)';
  }
  return null;
}

int runCheckMapTestSharedTopologyFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = mapTestSharedTopologyFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_map_test_shared_topology_fixtures: no inline topology violations.',
    );
    return 0;
  }
  logE(
    'check_map_test_shared_topology_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckMapTestSharedTopologyFixtures(Directory.current.path));
}
