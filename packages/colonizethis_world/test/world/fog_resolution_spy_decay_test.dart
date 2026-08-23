import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/fog_spy_reveal_decay.dart';

import '../world_test_support/world_test_support.dart';

import 'fog_resolution_spy_decay_cases.dart';

void main() {
  _fog_resolution_spy_decay_testTests();
}

void _fog_resolution_spy_decay_testTests() {
  group('applySpyRevealTimerDecay', () {
    for (final case_ in spyRevealTimerDecayCases) {
      test(case_.description, () {
        final game = spyRevealFogGame(
          spyPlayerId: case_.spyPlayerId,
          targetOwnerId: case_.targetOwnerId,
          provinceLocalId: case_.provinceLocalId,
          tileKey: case_.tileKey,
          visibilityLevel: case_.visibilityBefore,
          spyRevealTurns: 1,
        );

        final (visibility, timers) = applySpyRevealTimerDecay(game);

        expect(timers['p1'], isNull);
        expect(visibility['p1']?[case_.tileKey], case_.visibilityAfter);
      });
    }
  });

  group('applyFogDecay', () {
    const fogDecayPlayers = [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: false),
    ];

    for (final case_ in fogDecayCases) {
      test(case_.description, () {
        final game = fogDecayVisibilityGame(
          oldWorldProvinces: case_.oldWorldProvinces,
          newWorldProvinces: case_.newWorldProvinces,
          oldWorldUnits: case_.oldWorldUnits,
          playerVisibilityByTile: case_.playerVisibilityByTile,
          players: fogDecayPlayers,
        );

        final nextVisibility = applyFogDecay(game);

        expect(nextVisibility['p1']?[case_.tileKey], case_.expectedVisibility);
      });
    }
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
