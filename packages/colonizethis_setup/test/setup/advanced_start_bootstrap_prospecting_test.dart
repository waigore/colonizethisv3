import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_test_support.dart';

void main() {
  group('applyAdvancedStartProspecting', () {
    test('turns50 prospects GP-owned OW minerals only', () {
      final game = advancedStartProspectingFixture(
        owProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: kRegionOldWorld,
            ownerId: 'gp1',
          ),
        ],
        nwProvinces: const [
          Province(
            id: 'newWorld|p1',
            regionId: kRegionNewWorld,
            ownerId: 'tribe1',
          ),
        ],
        owTiles: {
          'oldWorld|p1': [
            'oldWorld|p1|0|0',
            'oldWorld|p1|1|0',
            'oldWorld|p1|2|0',
          ],
        },
        nwTiles: {
          'newWorld|p1': ['newWorld|p1|0|0', 'newWorld|p1|1|0'],
        },
        resourceByTileKey: {
          'oldWorld|p1|0|0': 'iron',
          'oldWorld|p1|1|0': 'copper',
          'oldWorld|p1|2|0': 'grain',
          'newWorld|p1|0|0': 'gold',
          'newWorld|p1|1|0': 'grain',
        },
      );

      final updated = applyAdvancedStartProspecting(
        game: game,
        startType: AdvancedStartType.turns50,
      );

      final prospected =
          updated.worldState.playerProspectedTiles['gp1'] ?? const {};
      expect(prospected, contains('oldWorld|p1|0|0'));
      expect(prospected, isNot(contains('newWorld|p1|0|0')));
      expect(prospected.length, 1);
    });

    test(
      'turns100 includes GP-owned NW minerals after colonization ownership',
      () {
        final game = advancedStartProspectingFixture(
          owProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
          ],
          nwProvinces: const [
            Province(
              id: 'newWorld|p1',
              regionId: kRegionNewWorld,
              ownerId: 'gp1',
            ),
            Province(
              id: 'newWorld|p2',
              regionId: kRegionNewWorld,
              ownerId: 'tribe1',
            ),
          ],
          owTiles: {
            'oldWorld|p1': ['oldWorld|p1|0|0'],
          },
          nwTiles: {
            'newWorld|p1': ['newWorld|p1|0|0', 'newWorld|p1|1|0'],
            'newWorld|p2': ['newWorld|p2|0|0'],
          },
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'iron',
            'newWorld|p1|0|0': 'gold',
            'newWorld|p1|1|0': 'copper',
            'newWorld|p2|0|0': 'silver',
          },
        );

        final updated = applyAdvancedStartProspecting(
          game: game,
          startType: AdvancedStartType.turns100,
        );

        final prospected =
            updated.worldState.playerProspectedTiles['gp1'] ?? const {};
        expect(
          prospected,
          containsAll([
            'oldWorld|p1|0|0',
            'newWorld|p1|0|0',
            'newWorld|p1|1|0',
          ]),
        );
        expect(prospected, isNot(contains('newWorld|p2|0|0')));
      },
    );

    test(
      'turns50 prospects minor OW minerals into round-robin buyer GP set',
      () {
        final game = advancedStartProspectingFixture(
          owProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
            Province(
              id: 'oldWorld|m1',
              regionId: kRegionOldWorld,
              ownerId: 'minor1',
            ),
          ],
          nwProvinces: const [],
          owTiles: {
            'oldWorld|p1': ['oldWorld|p1|0|0'],
            'oldWorld|m1': ['oldWorld|m1|0|0', 'oldWorld|m1|1|0'],
          },
          nwTiles: const {},
          resourceByTileKey: {
            'oldWorld|p1|0|0': 'grain',
            'oldWorld|m1|0|0': 'iron',
            'oldWorld|m1|1|0': 'copper',
          },
        );

        final updated = applyAdvancedStartProspecting(
          game: game,
          startType: AdvancedStartType.turns50,
        );

        final prospected =
            updated.worldState.playerProspectedTiles['gp1'] ?? const {};
        expect(prospected, contains('oldWorld|m1|0|0'));
        expect(prospected.length, 1);
      },
    );
  });
}
