import 'package:colonizethis_app_fixtures/test_support/seed42_init_game_result.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  test('loadSeed42InitGameResult exposes game, map view, and topology slices', () {
    final result = loadSeed42InitGameResult();

    expect(result.game.id, isNotEmpty);
    expect(result.game.players, isNotEmpty);
    expect(result.mapViewData.oldWorld.cells, isNotEmpty);
    expect(result.combinedTopology.nodes, isNotEmpty);
    expect(result.tileMapByRegion.keys, contains('oldWorld'));
    expect(result.topologyByRegion.keys, contains('oldWorld'));
    expect(
      result.topologyByRegion['oldWorld']!.nodes.every(
        (node) => !node.id.contains('|'),
      ),
      isTrue,
    );
  });
}
