import 'dart:io';

import 'package:path/path.dart' as p;

import 'check_orders_dedup_map_clones.dart';

const _ordersLibDir = 'packages/colonizethis_orders/lib/src/orders';

const _canonicalOwnedTileGraphRelative =
    'packages/colonizethis_orders/lib/src/orders/owned_tile_graph.dart';

const _connectivityDevSnapshotRelative =
    'packages/colonizethis_orders/lib/src/orders/connectivity_dev_snapshot.dart';

/// Private owned-land tile enumeration duplicated from [owned_tile_graph.dart].
final RegExp _privateOwnedLandTileKeysPattern = RegExp(
  r'Set<String>\s+_ownedLandTileKeys\s*\(',
);

/// Private BFS extension-distance body duplicated from [owned_tile_graph.dart].
final RegExp _privateExtensionDistancesPattern = RegExp(
  r'Map<String,\s*int>\s+_extensionDistancesOverOwnedLand\s*\(',
);

/// Private cardinal-neighbor expansion duplicated from [owned_tile_graph.dart].
final RegExp _privateCardinalNeighborPattern = RegExp(
  r'List<String>\s+_cardinalNeighborTileKeys\s*\(',
);

/// Duplicate [isTileAdjacentToConnectedSet] outside the canonical module.
final RegExp _duplicateAdjacentToConnectedPattern = RegExp(
  r'bool\s+isTileAdjacentToConnectedSet\s*\(',
);

bool _isCommentLine(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('//') || trimmed.startsWith('*');
}

List<OrdersDedupMapCloneViolation> findOwnedTileGraphDuplicateViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath == _canonicalOwnedTileGraphRelative) return const [];
  if (!relativePath.startsWith('packages/colonizethis_orders/lib/')) {
    return const [];
  }

  final violations = <OrdersDedupMapCloneViolation>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_isCommentLine(line)) continue;
    if (_privateOwnedLandTileKeysPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Duplicate _ownedLandTileKeys; use ownedLandTileKeysForPlayer '
              'from owned_tile_graph.dart.',
        ),
      );
    }
    if (_privateExtensionDistancesPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Duplicate _extensionDistancesOverOwnedLand; use '
              'extensionDistancesOverOwnedLand from owned_tile_graph.dart.',
        ),
      );
    }
    if (_privateCardinalNeighborPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Duplicate _cardinalNeighborTileKeys; use '
              'cardinalLandNeighborTileKeys from owned_tile_graph.dart.',
        ),
      );
    }
    if (_duplicateAdjacentToConnectedPattern.hasMatch(line)) {
      violations.add(
        OrdersDedupMapCloneViolation(
          path: relativePath,
          line: i + 1,
          message:
              'Duplicate isTileAdjacentToConnectedSet; import from '
              'owned_tile_graph.dart instead of redefining.',
        ),
      );
    }
  }
  return violations;
}

List<OrdersDedupMapCloneViolation> findConnectivityDevSnapshotImportViolations({
  required String relativePath,
  required String source,
}) {
  if (relativePath != _connectivityDevSnapshotRelative) return const [];
  if (source.contains("import 'owned_tile_graph.dart';") ||
      source.contains('import "owned_tile_graph.dart";')) {
    return const [];
  }
  return [
    OrdersDedupMapCloneViolation(
      path: relativePath,
      line: 1,
      message:
          'connectivity_dev_snapshot.dart must import owned_tile_graph.dart '
          'and delegate owned-land graph helpers to that module.',
    ),
  ];
}

int runCheckOrdersDedupOwnedTileGraph(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final root = p.normalize(repoRoot);
  final dir = Directory(p.join(root, _ordersLibDir));
  if (!dir.existsSync()) {
    logI('Orders dedup owned-tile-graph check skipped (orders lib dir absent).');
    return 0;
  }

  final violations = <OrdersDedupMapCloneViolation>[];
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final relativePath = p.relative(entity.path, from: root);
    final source = entity.readAsStringSync();
    violations.addAll(
      findOwnedTileGraphDuplicateViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
    violations.addAll(
      findConnectivityDevSnapshotImportViolations(
        relativePath: relativePath,
        source: source,
      ),
    );
  }

  if (violations.isEmpty) {
    logI('Orders dedup owned-tile-graph check passed.');
    return 0;
  }

  logE('ERROR: Found owned-tile-graph deduplication regressions.');
  for (final v in violations) {
    logE('${v.path}:${v.line} ${v.message}');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersDedupOwnedTileGraph(Directory.current.path));
}
