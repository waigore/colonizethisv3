import 'package:test/test.dart';

import '../tool/check_map_region_data_access_central.dart';

void main() {
  group('findMapRegionDataAccessViolations', () {
    test('flags an inline old-world provinces branch', () {
      const src = r'''
final provinces = isOldWorld
    ? game.worldState.oldWorld.provinces
    : game.worldState.newWorld.provinces;
''';
      final violations = findMapRegionDataAccessViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/init_game_map_view_builder_orchestration_part.dart',
        source: src,
      );
      expect(violations, hasLength(2));
      expect(violations.first.message, contains('regionDataForMapRegionId'));
    });

    test('flags an inline new-world units branch', () {
      const src = r'''
final regionUnits = game.worldState.newWorld.units;
''';
      final violations = findMapRegionDataAccessViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/init_game_map_view_builder_cells_markers_part.dart',
        source: src,
      );
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('regionDataForMapRegionId'));
    });

    test('accepts the canonical regionDataForMapRegionId delegation', () {
      const src = r'''
final provinces = regionDataForMapRegionId(game.worldState, regionId).provinces;
final units = regionDataForMapRegionId(game.worldState, regionId).units;
''';
      final violations = findMapRegionDataAccessViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/game_world_state_map_visualizer.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a comment mentioning the old branch', () {
      const src = r'''
/// Replaces inline worldState.oldWorld.provinces branches with the helper.
final provinces = regionDataForMapRegionId(world, regionId).provinces;
''';
      final violations = findMapRegionDataAccessViolations(
        relativePath: 'packages/colonizethis_map/lib/src/foo.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });

    test('does not flag a view-data region read without provinces/units', () {
      const src = r'''
final ow = viewData.oldWorld;
final nw = viewData.newWorld;
''';
      final violations = findMapRegionDataAccessViolations(
        relativePath:
            'packages/colonizethis_map/lib/src/game_world_state_map_visualizer.dart',
        source: src,
      );
      expect(violations, isEmpty);
    });
  });
}
