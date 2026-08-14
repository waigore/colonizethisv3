import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_dedup_raise_road_at_least.dart';
import '../tool/check_setup_dedup_road_tile_key_maps.dart';
import '../tool/check_setup_dedup_seaboard_nearest_tile.dart';

void main() {
  group('findSetupDedupRaiseRoadAtLeastViolations', () {
    const townsPath =
        'packages/colonizethis_setup/lib/src/setup/init_town_roads.dart';
    const helperPath =
        'packages/colonizethis_setup/lib/src/setup/setup_road_wiring_tile_helpers.dart';

    test('flags private raise-road clone outside helper module', () {
      const src = r'''
TileMapState _raiseRoadAtLeast(TileMapState tileState, String tileKey, int level) {
  final current = tileState.roadLevel(tileKey);
  if (current >= level) return tileState;
  return tileState.setRoadLevel(tileKey, level);
}
''';
      final violations = findSetupDedupRaiseRoadAtLeastViolations(
        sourcesByPath: {townsPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts call sites without a raise body', () {
      const src = r'''
tileState = raiseRoadAtLeast(tileState, key, 1);
''';
      final violations = findSetupDedupRaiseRoadAtLeastViolations(
        sourcesByPath: {townsPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts setup_road_wiring_tile_helpers.dart', () {
      const src = r'''
TileMapState raiseRoadAtLeast(TileMapState tileState, String tileKey, int level) {
  final current = tileState.roadLevel(tileKey);
  if (current >= level) return tileState;
  return tileState.setRoadLevel(tileKey, level);
}
''';
      final violations = findSetupDedupRaiseRoadAtLeastViolations(
        sourcesByPath: {helperPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup lib tree', () {
      final code = runCheckSetupDedupRaiseRoadAtLeast(
        _repoRoot(),
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });

  group('findSetupDedupRoadTileKeyMapsViolations', () {
    const townsPath =
        'packages/colonizethis_setup/lib/src/setup/init_town_roads.dart';
    const helperPath =
        'packages/colonizethis_setup/lib/src/setup/setup_road_wiring_tile_helpers.dart';

    test('flags private _coordToTileKey clone', () {
      const src = r'''
Map<String, String> _coordToTileKey(WorldState ws, String regionId) {
  return {};
}
''';
      final violations = findSetupDedupRoadTileKeyMapsViolations(
        sourcesByPath: {townsPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts shared helper call sites', () {
      const src = r'''
final coordToKey = coordToTileKeyForRegion(ws, regionId);
final allowed = ownedTileKeysForFaction(ws, regionId, factionId);
''';
      final violations = findSetupDedupRoadTileKeyMapsViolations(
        sourcesByPath: {townsPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts setup_road_wiring_tile_helpers.dart', () {
      const src = r'''
Map<String, String> _coordToTileKey(WorldState ws, String regionId) {
  return {};
}
''';
      final violations = findSetupDedupRoadTileKeyMapsViolations(
        sourcesByPath: {helperPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup lib tree', () {
      final code = runCheckSetupDedupRoadTileKeyMaps(
        _repoRoot(),
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });

  group('findSetupDedupSeaboardNearestTileViolations', () {
    const capitalPath =
        'packages/colonizethis_setup/lib/src/setup/capital_choice.dart';
    const helperPath =
        'packages/colonizethis_setup/lib/src/setup/setup_road_wiring.dart';

    test('flags private nearest-coastal clone', () {
      const src = r'''
(int, int)? _nearestCoastalTileInProvinceForSeaZone(
  TileMapResult map,
) {
  return null;
}
''';
      final violations = findSetupDedupSeaboardNearestTileViolations(
        sourcesByPath: {capitalPath: src},
      );
      expect(violations, hasLength(1));
    });

    test('accepts shared helper call sites', () {
      const src = r'''
final coastal = nearestSeaboardTileInProvinceForSeaZone(
  map: map,
  topology: topology,
  localProvinceId: localProvinceId,
  seaZoneId: seaZoneId,
  provinceIds: provinceIds,
  inlandX: x,
  inlandY: y,
);
''';
      final violations = findSetupDedupSeaboardNearestTileViolations(
        sourcesByPath: {capitalPath: src},
      );
      expect(violations, isEmpty);
    });

    test('exempts setup_road_wiring.dart', () {
      const src = r'''
(int x, int y)? nearestSeaboardTileInProvinceForSeaZone({
  required TileMapResult map,
}) {
  int? bestDist;
  int? bestX;
  for (var y = 0; y < map.height; y++) {
    tileAdjacentToSeaZone(0, 0, map, topology, 's1');
    final dist = (x - inlandX).abs() + (y - inlandY).abs();
  }
  return null;
}
''';
      final violations = findSetupDedupSeaboardNearestTileViolations(
        sourcesByPath: {helperPath: src},
      );
      expect(violations, isEmpty);
    });

    test('passes on the live setup lib tree', () {
      final code = runCheckSetupDedupSeaboardNearestTile(
        _repoRoot(),
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
