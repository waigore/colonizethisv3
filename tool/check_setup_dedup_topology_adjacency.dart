import 'dart:io';

import 'package:path/path.dart' as p;

/// Setup package whose topology/tile adjacency helpers must stay deduplicated
/// (Refs #3740). The capital-choice port-road geometry and the province
/// town-assignment site previously each carried private clones of the
/// province-node-id set, the topology-node lookup, the sea-zone adjacency scan,
/// the cardinal-neighbor iteration skeleton, and the tile-adjacent-to-sea-zone
/// test. The pure topology concerns now consume the canonical cached helpers in
/// `colonizethis_world` (`provinceNodeIds`, `seaZonesAdjacentToProvince`); the
/// tile-grid concerns live once in the shared
/// `setup_topology_adjacency.dart` module (`anyCardinalNeighborCell`,
/// `tileAdjacentToSeaZone`). This gate keeps the private clones from returning.
const _setupLibDir = 'packages/colonizethis_setup/lib/src/setup';

/// The shared module that owns the canonical (public, package-internal)
/// tile-grid adjacency helpers. Exempt because it is the single home for them.
const _sharedModuleRelativePath =
    'packages/colonizethis_setup/lib/src/setup/setup_topology_adjacency.dart';

/// Private helper identifiers that were duplicated across
/// `capital_choice_port_road_geometry.dart` and `game_setup_helpers_towns.dart`
/// before #3740. Their reappearance as an underscore-prefixed declaration signals
/// a re-inlined adjacency clone; callers must instead use the `colonizethis_world`
/// helpers (`provinceNodeIds` / `seaZonesAdjacentToProvince`) or the shared
/// `setup_topology_adjacency.dart` helpers (`anyCardinalNeighborCell` /
/// `tileAdjacentToSeaZone`).
final List<RegExp> _bannedPrivateHelperPatterns = <RegExp>[
  RegExp(r'\b_provinceNodeIds\b'),
  RegExp(r'\b_topologyNodeById\b'),
  RegExp(r'\b_seaZonesAdjacentToProvince\b'),
  RegExp(r'\b_provinceSeaZones\b'),
  RegExp(r'\b_anyCardinalNeighborCell\b'),
  RegExp(r'\b_isTileAdjacentToSeaZone\b'),
];

/// True when [line] is a pure comment line (`//`, `///`, or a `*` doc/block
/// continuation), so a pattern mentioned in prose is not flagged.
bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckSetupDedupTopologyAdjacency(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _setupLibDir));
  if (!dir.existsSync()) {
    logI(
      'Setup dedup topology-adjacency check skipped (setup lib dir absent).',
    );
    return 0;
  }

  final sourcesByPath = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    sourcesByPath[relativePath] = entity.readAsStringSync();
  }

  final violations = findSetupDedupTopologyAdjacencyViolations(
    sourcesByPath: sourcesByPath,
  );

  if (violations.isEmpty) {
    logI('Setup dedup topology-adjacency check passed.');
    return 0;
  }

  logE(
    'ERROR: Found re-inlined topology/tile adjacency helpers in the setup '
    'package. Use colonizethis_world provinceNodeIds / seaZonesAdjacentToProvince '
    'and the shared setup_topology_adjacency.dart anyCardinalNeighborCell / '
    'tileAdjacentToSeaZone helpers instead of private clones.',
  );
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckSetupDedupTopologyAdjacency(Directory.current.path));
}

/// Scans [sourcesByPath] (relative path -> source) for re-inlined topology/tile
/// adjacency helpers. The shared module ([_sharedModuleRelativePath]) is exempt
/// because it owns the canonical public tile-grid helpers.
List<SetupDedupTopologyAdjacencyViolation>
findSetupDedupTopologyAdjacencyViolations({
  required Map<String, String> sourcesByPath,
}) {
  final violations = <SetupDedupTopologyAdjacencyViolation>[];
  final paths = sourcesByPath.keys.toList()..sort();
  for (final path in paths) {
    final normalized = p.normalize(path);
    if (normalized == p.normalize(_sharedModuleRelativePath)) continue;
    final lines = sourcesByPath[path]!.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isCommentLine(line)) continue;
      for (final pattern in _bannedPrivateHelperPatterns) {
        if (pattern.hasMatch(line)) {
          violations.add(
            SetupDedupTopologyAdjacencyViolation(
              path: path,
              line: i + 1,
              message:
                  'Re-inlined adjacency helper (${pattern.pattern}); use the '
                  'colonizethis_world / setup_topology_adjacency.dart helpers.',
            ),
          );
        }
      }
    }
  }
  return violations;
}

class SetupDedupTopologyAdjacencyViolation {
  const SetupDedupTopologyAdjacencyViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  final String path;
  final int line;
  final String message;
}
