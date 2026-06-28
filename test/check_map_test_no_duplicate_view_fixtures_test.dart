import 'package:test/test.dart';

import '../tool/check_map_test_no_duplicate_view_fixtures.dart';

void main() {
  group('mapTestNoDuplicateViewFixturesPathInScope', () {
    test('positive: init_game_map_view_builder_* test files are in scope', () {
      expect(
        mapTestNoDuplicateViewFixturesPathInScope(
          'packages/colonizethis_map/test/init_game_map_view_builder_markers_test.dart',
        ),
        isTrue,
      );
      expect(
        mapTestNoDuplicateViewFixturesPathInScope(
          'packages\\colonizethis_map\\test\\init_game_map_view_builder_slice_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: support file and other map tests are out of scope', () {
      expect(
        mapTestNoDuplicateViewFixturesPathInScope(
          'packages/colonizethis_map/test/support/init_game_map_view_fixtures.dart',
        ),
        isFalse,
      );
      expect(
        mapTestNoDuplicateViewFixturesPathInScope(
          'packages/colonizethis_map/test/tile_map_visualization_test_fixtures.dart',
        ),
        isFalse,
      );
      expect(
        mapTestNoDuplicateViewFixturesPathInScope(
          'packages/colonizethis_map/lib/src/init_game_map_view_builder.dart',
        ),
        isFalse,
      );
    });
  });

  group('mapTestDuplicateViewFixturesViolationReason', () {
    test('positive: inline Game(...) scaffolding is flagged', () {
      const content = '''
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  final game = Game(id: 'x', worldState: WorldState());
  buildInitGameMapViewData(game: game);
}
''';
      final reason = mapTestDuplicateViewFixturesViolationReason(
        'packages/colonizethis_map/test/init_game_map_view_builder_markers_test.dart',
        content,
      );
      expect(reason, isNotNull);
      expect(reason, contains(mapTestViewFixturesImport));
      expect(reason, contains('Game(...)'));
    });

    test('positive: inline MapTopology(...) scaffolding is flagged', () {
      const content = '''
void main() {
  final topology = MapTopology(nodes: [], edges: []);
  buildInitGameMapViewData(topologyByRegion: {'oldWorld': topology});
}
''';
      final reason = mapTestDuplicateViewFixturesViolationReason(
        'packages/colonizethis_map/test/init_game_map_view_builder_slice_test.dart',
        content,
      );
      expect(reason, isNotNull);
      expect(reason, contains('MapTopology(...)'));
    });

    test('negative: shared builder calls (minimalGame / regionTopology) pass',
        () {
      const content = '''
import 'support/init_game_map_view_fixtures.dart';

void main() {
  final game = minimalGame(id: 'x');
  final topology = regionTopology(regionId: 'oldWorld', provinceIds: ['p1']);
  buildInitGameMapViewData(game: game, topologyByRegion: {'oldWorld': topology});
}
''';
      final reason = mapTestDuplicateViewFixturesViolationReason(
        'packages/colonizethis_map/test/init_game_map_view_builder_markers_test.dart',
        content,
      );
      expect(reason, isNull);
    });

    test('negative: prose mentioning Game( in a comment is not flagged', () {
      const content = '''
// This test used to build a Game( ... ) and a MapTopology( ... ) inline.
import 'support/init_game_map_view_fixtures.dart';

void main() {
  final game = minimalGame();
  buildInitGameMapViewData(game: game);
}
''';
      final reason = mapTestDuplicateViewFixturesViolationReason(
        'packages/colonizethis_map/test/init_game_map_view_builder_warp_markers_test.dart',
        content,
      );
      expect(reason, isNull);
    });

    test('negative: a non-view-builder file with inline Game( is out of scope',
        () {
      const content = '''
void main() {
  final game = Game(id: 'x');
  buildInitGameMapViewData(game: game);
}
''';
      final reason = mapTestDuplicateViewFixturesViolationReason(
        'packages/colonizethis_map/test/tile_map_visualization_test_fixtures.dart',
        content,
      );
      expect(reason, isNull);
    });
  });

  group('runCheckMapTestNoDuplicateViewFixtures', () {
    test('passes on the current repo tree', () {
      expect(runCheckMapTestNoDuplicateViewFixtures('.'), 0);
    });
  });
}
