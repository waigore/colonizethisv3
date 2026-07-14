import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/fog_spy_reveal_decay.dart';

import '../world_test_support/world_test_support.dart';

void main() {
  _fog_resolution_spy_decay_testTests();
}

void _fog_resolution_spy_decay_testTests() {
  group('applySpyRevealTimerDecay', () {
    test(
      'decrements timers for other-faction provinces when timer expires',
      () {
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = spyRevealFogGame(
          spyPlayerId: 'p1',
          targetOwnerId: 'p2',
          provinceLocalId: 'P2',
          tileKey: tileKeyP2,
          visibilityLevel: 'fullyVisible',
          spyRevealTurns: 1,
        );

        final (visibility, timers) = applySpyRevealTimerDecay(game);

        // Timer should be removed after reaching zero.
        expect(timers['p1'], isNull);
        expect(visibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
      },
    );

    test('never applies timers to own provinces', () {
      const tileKeyP1 = 'oldWorld|P1|0|0';

      final game = spyRevealFogGame(
        spyPlayerId: 'p1',
        targetOwnerId: 'p1',
        provinceLocalId: 'P1',
        tileKey: tileKeyP1,
        visibilityLevel: 'fullyVisible',
        spyRevealTurns: 1,
      );

      final (visibility, timers) = applySpyRevealTimerDecay(game);

      // Own-province timer should be dropped without affecting visibility.
      expect(timers['p1'], isNull);
      expect(visibility['p1']?[tileKeyP1], VisibilityLevel.fullyVisible.name);
    });

    test('leaves unknown tiles unchanged when timer expires', () {
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = spyRevealFogGame(
        spyPlayerId: 'p1',
        targetOwnerId: 'p2',
        provinceLocalId: 'P2',
        tileKey: tileKeyP2,
        visibilityLevel: 'unknown',
        spyRevealTurns: 1,
      );

      final (visibility, timers) = applySpyRevealTimerDecay(game);

      expect(timers['p1'], isNull);
      expect(visibility['p1']?[tileKeyP2], VisibilityLevel.unknown.name);
    });
  });

  group('applyFogDecay', () {
    const fogDecayPlayers = [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ];

    test(
      'fogs tiles in other-faction provinces when no Explorer or Spy timer',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = fogDecayVisibilityGame(
          oldWorldProvinces: const [
            Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
          ],
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'fullyVisible'},
          },
          players: fogDecayPlayers,
        );

        final nextVisibility = applyFogDecay(game);

        expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
      },
    );

    test(
      'preserves visibility when Explorer is present in other-faction province',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|P2|0|0';

        final game = fogDecayVisibilityGame(
          oldWorldProvinces: const [
            Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
          ],
          oldWorldUnits: [
            Unit(
              id: 'explorer1',
              type: kUnitTypeExplorer,
              ownerId: 'p1',
              locationProvinceId: '$ow|P2',
            ),
          ],
          playerVisibilityByTile: const {
            'p1': {tileKeyP2: 'fullyVisible'},
          },
          players: fogDecayPlayers,
        );

        final nextVisibility = applyFogDecay(game);

        expect(
          nextVisibility['p1']?[tileKeyP2],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test('fogs other-faction province when no Explorer/Spy remains', () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = fogDecayVisibilityGame(
        oldWorldProvinces: const [
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
        ],
        playerVisibilityByTile: const {
          'p1': {tileKeyP2: 'fullyVisible'},
        },
        players: fogDecayPlayers,
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
    });

    test('does not promote unknown tiles in other-faction province', () {
      const nw = 'newWorld';
      const tileKeyNw = 'newWorld|P2|0|0';

      final game = fogDecayVisibilityGame(
        newWorldProvinces: const [
          Province(id: '$nw|P2', regionId: nw, ownerId: 'p2'),
        ],
        playerVisibilityByTile: const {
          'p1': {tileKeyNw: 'unknown'},
        },
        players: fogDecayPlayers,
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyNw], VisibilityLevel.unknown.name);
    });

    test('does not change fogged tiles in other-faction province', () {
      const ow = 'oldWorld';
      const tileKeyP2 = 'oldWorld|P2|0|0';

      final game = fogDecayVisibilityGame(
        oldWorldProvinces: const [
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
        ],
        playerVisibilityByTile: const {
          'p1': {tileKeyP2: 'fogged'},
        },
        players: fogDecayPlayers,
      );

      final nextVisibility = applyFogDecay(game);

      expect(nextVisibility['p1']?[tileKeyP2], VisibilityLevel.fogged.name);
    });
  });

  group('downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry', () {
    test(
      'Given fullyVisible tiles When timer expiry Then only those become fogged',
      () {
        final vis = <String, String>{
          'ow|p1|0|0': VisibilityLevel.fullyVisible.name,
          'ow|p1|0|1': VisibilityLevel.fogged.name,
          'ow|p1|0|2': VisibilityLevel.unknown.name,
        };
        downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry(vis, [
          'ow|p1|0|0',
          'ow|p1|0|1',
          'ow|p1|0|2',
        ]);
        expect(vis['ow|p1|0|0'], VisibilityLevel.fogged.name);
        expect(vis['ow|p1|0|1'], VisibilityLevel.fogged.name);
        expect(vis['ow|p1|0|2'], VisibilityLevel.unknown.name);
      },
    );
  });

  group('nextSpyRevealTimersByProvinceAfterDecayStep', () {
    test(
      'Given own-province timer entry When decay step Then entry is ignored',
      () {
        const playerId = 'england';
        final vis = <String, String>{
          'ow|p1|0|0': VisibilityLevel.fullyVisible.name,
        };
        final out = nextSpyRevealTimersByProvinceAfterDecayStep(
          playerId: playerId,
          byProvince: {'ow|p1': 1},
          ownerByProvinceId: {'ow|p1': playerId},
          playerVisibility: vis,
          landTileKeysForProvince: (_) => ['ow|p1|0|0'],
        );
        expect(out, isEmpty);
        expect(vis['ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
      },
    );

    test('Given other-faction province with turns > 1 When decay step '
        'Then timer decrements and visibility unchanged', () {
      const playerId = 'england';
      final vis = <String, String>{
        'ow|p1|0|0': VisibilityLevel.fullyVisible.name,
      };
      final out = nextSpyRevealTimersByProvinceAfterDecayStep(
        playerId: playerId,
        byProvince: {'ow|p1': 3},
        ownerByProvinceId: {'ow|p1': 'france'},
        playerVisibility: vis,
        landTileKeysForProvince: (_) => ['ow|p1|0|0'],
      );
      expect(out, {'ow|p1': 2});
      expect(vis['ow|p1|0|0'], VisibilityLevel.fullyVisible.name);
    });

    test('Given other-faction province with turns 1 When decay step '
        'Then timer removed and fullyVisible tiles fogged', () {
      const playerId = 'england';
      final vis = <String, String>{
        'ow|p1|0|0': VisibilityLevel.fullyVisible.name,
        'ow|p1|0|1': VisibilityLevel.unknown.name,
      };
      final out = nextSpyRevealTimersByProvinceAfterDecayStep(
        playerId: playerId,
        byProvince: {'ow|p1': 1},
        ownerByProvinceId: {'ow|p1': 'france'},
        playerVisibility: vis,
        landTileKeysForProvince: (_) => ['ow|p1|0|0', 'ow|p1|0|1'],
      );
      expect(out, isEmpty);
      expect(vis['ow|p1|0|0'], VisibilityLevel.fogged.name);
      expect(vis['ow|p1|0|1'], VisibilityLevel.unknown.name);
    });
  });
}
