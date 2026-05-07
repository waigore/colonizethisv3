import 'package:colonizethis_logic/src/world/fog_spy_reveal_decay.dart';
import 'package:colonizethis_logic/src/world/player_view.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('downgradeFullyVisibleTilesToFoggedAfterSpyTimerExpiry', () {
    test('Given fullyVisible tiles When timer expiry Then only those become fogged',
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
    });
  });

  group('nextSpyRevealTimersByProvinceAfterDecayStep', () {
    test('Given own-province timer entry When decay step Then entry is ignored', () {
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
    });

    test(
        'Given other-faction province with turns > 1 When decay step '
        'Then timer decrements and visibility unchanged',
        () {
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

    test(
        'Given other-faction province with turns 1 When decay step '
        'Then timer removed and fullyVisible tiles fogged',
        () {
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
