import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_gp_ow_tile_scans.dart';

void main() {
  group('findSetupDedupGpOwTileScansViolations', () {
    const sharedModulePath =
        'packages/colonizethis_setup/lib/src/setup/gp_old_world_tile_scan.dart';
    const terrainPath =
        'packages/colonizethis_setup/lib/src/setup/gp_old_world_terrain_redistribution.dart';
    const tileScansPath =
        'packages/colonizethis_setup/lib/src/setup/gp_old_world_resource_redistribution_tile_scans.dart';

    test('flags a re-inlined private owner-map helper', () {
      const src = r'''
Map<String, String> _ownerByLocalProvinceId(Game game) {
  final m = <String, String>{};
  return m;
}
''';
      final violations = findSetupDedupGpOwTileScansViolations(
        sourcesByPath: const {terrainPath: src},
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('_ownerByLocalProvinceId'));
    });

    test('flags re-inlined tile-key, gp-id, and eligible-collector clones', () {
      const src = r'''
String _owTileKey(String localProvinceId, int x, int y) => '';
bool _isGpId(String id, Set<String> gpIds) => gpIds.contains(id);
List<GpOwLandTile> _collectEligibleTilesSorted() => const [];
''';
      final violations = findSetupDedupGpOwTileScansViolations(
        sourcesByPath: const {tileScansPath: src},
      );
      expect(violations, hasLength(3));
    });

    test('accepts delegation to the shared public helpers', () {
      const src = r'''
final ownerByLocal = gpOwnerByLocalProvinceId(game);
visitGpOwLandTiles(
  map: map,
  ownerByLocal: ownerByLocal,
  gpIds: gpIds,
  visit: (x, y, local, owner, key) {
    if (map.resourceAt(x, y) == resource) n++;
  },
);
final tiles = collectGpOwEligibleTilesSorted(map: map);
''';
      final violations = findSetupDedupGpOwTileScansViolations(
        sourcesByPath: const {tileScansPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts the shared module that owns the canonical helpers', () {
      const src = r'''
String gpOwTileKey(String localProvinceId, int x, int y) => '';
Map<String, String> gpOwnerByLocalProvinceId(Game game) => const {};
bool isGpOwner(String id, Set<String> gpIds) => gpIds.contains(id);
List<GpOwLandTile> collectGpOwEligibleTilesSorted() => const [];
''';
      final violations = findSetupDedupGpOwTileScansViolations(
        sourcesByPath: const {sharedModulePath: src},
      );
      expect(violations, isEmpty);
    });

    test('ignores patterns appearing only in comment lines', () {
      const src = r'''
// historical: Map<String, String> _ownerByLocalProvinceId(Game game) { ... }
/// _owTileKey and _isGpId were duplicated before #3449.
''';
      final violations = findSetupDedupGpOwTileScansViolations(
        sourcesByPath: const {terrainPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup source tree', () {
      final repoRoot = _repoRoot();
      final code = runCheckSetupDedupGpOwTileScans(
        repoRoot,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final manifest = File(
      p.join(dir.path, 'tool', 'ct_repo_lint_manifest.yaml'),
    );
    if (manifest.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
