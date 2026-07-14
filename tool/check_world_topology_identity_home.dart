import 'dart:io';

import 'package:path/path.dart' as p;

/// Topology identity helpers must live in [topologyIdentityHomePath], not as
/// top-level declarations in `naval.dart` (Refs #3968).
const String topologyIdentityHomePath =
    'packages/colonizethis_world/lib/src/world/topology_identity.dart';

const String _navalPath =
    'packages/colonizethis_world/lib/src/world/naval.dart';

const List<String> topologyIdentityForbiddenNavalDecls = [
  'indexTopologyNodesByRegion',
  'provinceTopologyNodeId',
  'provinceIdsAdjacentToSeaZone',
  'regionIdForSeaZone',
];

/// Returns violation messages when [content] declares a forbidden topology
/// identity symbol as a top-level function in `naval.dart`.
List<String> worldTopologyIdentityHomeViolationsInNaval(String content) {
  final out = <String>[];
  final lines = content.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trimLeft();
    if (trimmed.isEmpty || trimmed.startsWith('//')) {
      continue;
    }
    for (final name in topologyIdentityForbiddenNavalDecls) {
      // Match top-level function decls only (not call sites / exports).
      if (RegExp(
        r'^(?:[\w.?]+(?:<[^;{]+>)?\s+)+' +
            RegExp.escape(name) +
            r'\s*\(',
      ).hasMatch(trimmed)) {
        out.add(
          '$_navalPath:${i + 1}: top-level `$name` must live in '
          '$topologyIdentityHomePath (Refs #3968)',
        );
      }
    }
  }
  return out;
}

int runCheckWorldTopologyIdentityHome(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final navalFile = File(p.join(repoRoot, _navalPath));
  if (!navalFile.existsSync()) {
    logE('check_world_topology_identity_home: missing $_navalPath');
    return 1;
  }
  final homeFile = File(p.join(repoRoot, topologyIdentityHomePath));
  if (!homeFile.existsSync()) {
    logE(
      'check_world_topology_identity_home: missing $topologyIdentityHomePath',
    );
    return 1;
  }

  final violations = worldTopologyIdentityHomeViolationsInNaval(
    navalFile.readAsStringSync(),
  );
  // Ensure home still defines the four symbols (positive presence check).
  final homeContent = homeFile.readAsStringSync();
  for (final name in topologyIdentityForbiddenNavalDecls) {
    if (!RegExp(r'\b' + RegExp.escape(name) + r'\s*\(').hasMatch(homeContent)) {
      violations.add(
        '$topologyIdentityHomePath: missing required identity helper `$name` '
        '(Refs #3968)',
      );
    }
  }

  if (violations.isEmpty) {
    logI('check_world_topology_identity_home: topology identity home ok.');
    return 0;
  }
  logE(
    'check_world_topology_identity_home: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckWorldTopologyIdentityHome(Directory.current.path));
}
