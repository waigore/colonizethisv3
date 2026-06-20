// Forbids circular imports inside the colonizethis_world package lib/ tree
// (Refs #3544). Before this gate, `province_lookup.dart` and
// `province_owner_cache.dart` imported each other (a two-node cycle) and no
// repo-lint rule detected intra-package import cycles — `repo.world_no_logic_deps`
// only blocks logic deps, and `repo.domain_package_import_dag` only checks the
// cross-package dependency direction. This checker builds the file-level
// import/export graph among `packages/colonizethis_world/lib/**` Dart files
// (resolving relative imports and `package:colonizethis_world/...` self-imports)
// and fails when any directed cycle exists.
import 'dart:io';

import 'package:path/path.dart' as p;

const _worldLibRelative = 'packages/colonizethis_world/lib';
const _worldPackagePrefix = 'package:colonizethis_world/';

final _importOrExport = RegExp(
  '''^\\s*(?:import|export)\\s+['"]([^'"]+)['"]''',
);

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.mocks.dart');

/// Resolves an `import`/`export` URI [uri] found in [fromFile] to an absolute,
/// normalized path inside [libDir], or `null` when the URI points outside the
/// colonizethis_world package (dart:, other packages) or cannot be a local node.
String? _resolveWorldTarget({
  required String uri,
  required String fromFile,
  required String libDir,
}) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith(_worldPackagePrefix)) {
    final remainder = uri.substring(_worldPackagePrefix.length);
    return p.normalize(p.join(libDir, remainder));
  }
  if (uri.startsWith('package:')) return null;
  // Relative import resolved against the importing file's directory.
  return p.normalize(p.join(p.dirname(fromFile), uri));
}

/// Returns one directed cycle (as an ordered list of nodes, first == last) if
/// the graph [edges] contains a cycle, otherwise `null`. Deterministic: nodes
/// and successors are visited in sorted order.
List<String>? _findCycle(Map<String, List<String>> edges) {
  const white = 0, grey = 1, black = 2;
  final color = <String, int>{};
  final stack = <String>[];

  List<String>? dfs(String node) {
    color[node] = grey;
    stack.add(node);
    for (final next in edges[node] ?? const <String>[]) {
      final state = color[next] ?? white;
      if (state == grey) {
        final start = stack.indexOf(next);
        return [...stack.sublist(start), next];
      }
      if (state == white) {
        final found = dfs(next);
        if (found != null) return found;
      }
    }
    stack.removeLast();
    color[node] = black;
    return null;
  }

  for (final node in edges.keys.toList()..sort()) {
    if ((color[node] ?? white) == white) {
      final cycle = dfs(node);
      if (cycle != null) return cycle;
    }
  }
  return null;
}

void main() {
  exit(runCheckWorldNoCircularImports(Directory.current.path));
}

int runCheckWorldNoCircularImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final libDir = Directory(p.join(repoRoot, _worldLibRelative));
  if (!libDir.existsSync()) {
    logE('check_world_no_circular_imports: missing $_worldLibRelative');
    return 1;
  }
  final libDirPath = p.normalize(libDir.path);

  final nodes = <String>{};
  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (_isGenerated(entity.path)) continue;
    nodes.add(p.normalize(entity.path));
  }

  final edges = <String, List<String>>{for (final node in nodes) node: []};
  for (final node in nodes) {
    for (final line in File(node).readAsLinesSync()) {
      final match = _importOrExport.firstMatch(line);
      if (match == null) continue;
      final target = _resolveWorldTarget(
        uri: match.group(1)!,
        fromFile: node,
        libDir: libDirPath,
      );
      if (target == null) continue;
      if (target == node) continue;
      if (!nodes.contains(target)) continue;
      edges[node]!.add(target);
    }
    edges[node]!.sort();
  }

  final cycle = _findCycle(edges);
  if (cycle == null) {
    logI(
      'check_world_no_circular_imports: ${nodes.length} '
      '$_worldLibRelative Dart files form an acyclic import graph.',
    );
    return 0;
  }

  logE(
    'check_world_no_circular_imports: circular import detected in '
    '$_worldLibRelative (each file must be understandable/testable in '
    'isolation — break the cycle by extracting the shared symbol into a '
    'third file):',
  );
  final chain = cycle.map((n) => p.relative(n, from: repoRoot)).join('\n   -> ');
  logE('   $chain');
  return 1;
}
