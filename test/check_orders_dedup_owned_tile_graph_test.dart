import 'package:test/test.dart';

import '../tool/check_orders_dedup_owned_tile_graph.dart';

void main() {
  group('findOwnedTileGraphDuplicateViolations', () {
    test('flags private owned-land helpers outside canonical module', () {
      const src = r'''
Set<String> _ownedLandTileKeys({required Game game}) => {};
Map<String, int> _extensionDistancesOverOwnedLand({}) => {};
List<String> _cardinalNeighborTileKeys(String tileKey) => [];
bool isTileAdjacentToConnectedSet(String tileKey, Set<String> connected) => false;
''';
      final violations = findOwnedTileGraphDuplicateViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/connectivity_dev_snapshot.dart',
        source: src,
      );
      expect(violations, hasLength(4));
    });

    test('allows canonical owned_tile_graph definitions', () {
      const src = r'''
bool isTileAdjacentToConnectedSet(
  String tileKey,
  Set<String> connected, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> landProvinceIds,
}) => false;
''';
      final violations = findOwnedTileGraphDuplicateViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/owned_tile_graph.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });

  group('findConnectivityDevSnapshotImportViolations', () {
    test('requires owned_tile_graph import in connectivity snapshot', () {
      const src = "import 'order_suggestion_pass_context.dart';\n";
      final violations = findConnectivityDevSnapshotImportViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/connectivity_dev_snapshot.dart',
        source: src,
      );
      expect(violations, hasLength(1));
    });

    test('passes when owned_tile_graph is imported', () {
      const src = "import 'owned_tile_graph.dart';\n";
      final violations = findConnectivityDevSnapshotImportViolations(
        relativePath:
            'packages/colonizethis_orders/lib/src/orders/connectivity_dev_snapshot.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
