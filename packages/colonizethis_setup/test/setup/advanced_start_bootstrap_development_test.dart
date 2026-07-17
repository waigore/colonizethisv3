import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_test_support.dart';

void main() {
  group('applyAdvancedStartDevelopment', () {
    test('turns50 develops 25% of GP and minor tiles with roads', () {
      final game = applyAdvancedStartDevelopment(
        game: advancedStartDevelopmentFixture(),
        startType: AdvancedStartType.turns50,
        tileMapByRegion: {kRegionOldWorld: advancedStartOwDevelopmentTileMap()},
        topologyByRegion: const {
          kRegionOldWorld: MapTopology(nodes: [], edges: []),
        },
      );

      expect(game.worldState.tileState.improvementLevel('oldWorld|p1|0|0'), 1);
      expect(game.worldState.purchasedTilesByTileKey['oldWorld|m1|1|0'], 'gp1');
      expect(
        game.worldState.tileState.roadLevel('oldWorld|p1|0|0'),
        greaterThanOrEqualTo(1),
      );
    });

    test(
      'turns50 develops prospected minerals when no higher-priority tiles',
      () {
        final mineralFixture = advancedStartDevelopmentFixture(
          owTiles: {
            'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|1'],
            'oldWorld|m1': ['oldWorld|m1|0|0', 'oldWorld|m1|1|0'],
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'iron',
            'oldWorld|m1|1|0': 'copper',
          },
          playerProspectedTiles: const {
            'gp1': {'oldWorld|p1|0|0', 'oldWorld|m1|1|0'},
          },
        );

        final game = applyAdvancedStartDevelopment(
          game: mineralFixture,
          startType: AdvancedStartType.turns50,
          tileMapByRegion: {
            kRegionOldWorld: advancedStartOwDevelopmentTileMap(),
          },
          topologyByRegion: const {
            kRegionOldWorld: MapTopology(nodes: [], edges: []),
          },
        );

        expect(
          game.worldState.tileState.improvementLevel('oldWorld|p1|0|0'),
          1,
        );
        expect(
          game.worldState.tileState.improvementLevel('oldWorld|m1|1|0'),
          1,
        );
        expect(
          game.worldState.purchasedTilesByTileKey['oldWorld|m1|1|0'],
          'gp1',
        );
      },
    );
  });
}
