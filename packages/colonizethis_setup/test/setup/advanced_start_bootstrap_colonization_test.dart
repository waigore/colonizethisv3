import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'advanced_start_test_support.dart';

void main() {
  group('applyAdvancedStartNwColonization', () {
    test('turns100 assigns six contiguous provinces to GP from warp entry', () {
      final game = applyAdvancedStartNwColonization(
        game: advancedStartColonizationFixture(
          nwProvinces: advancedStartNwColonizationProvinces(),
        ),
        startType: AdvancedStartType.turns100,
        topologyOldWorld: advancedStartOwCapitalTopology(),
        topologyNewWorld: advancedStartNwColonizationTopology(),
        warpLinks: advancedStartDefaultWarpLinks,
        tileMapByRegion: {
          kRegionNewWorld: advancedStartNwColonizationTileMap(),
        },
        topologyByRegion: {
          kRegionNewWorld: advancedStartNwColonizationTopology(),
        },
      );

      final gpOwned = game.worldState.newWorld.provinces
          .where((p) => p.ownerId == 'gp1')
          .length;
      expect(gpOwned, 6);
      expect(
        game.worldState.newWorld.provinces
            .where((p) => p.ownerId == 'tribe1')
            .length,
        greaterThanOrEqualTo(1),
      );
      expect(
        game.worldState.newWorld.provinces
            .where((p) => p.ownerId == 'tribe2')
            .length,
        greaterThanOrEqualTo(1),
      );
    });

    test('turns50 skips colonization', () {
      final nwProvinces = [
        Province(
          id: 'newWorld|p1',
          regionId: kRegionNewWorld,
          ownerId: 'tribe1',
        ),
      ];
      final game = applyAdvancedStartNwColonization(
        game: advancedStartColonizationFixture(nwProvinces: nwProvinces),
        startType: AdvancedStartType.turns50,
        topologyOldWorld: advancedStartOwCapitalTopology(),
        topologyNewWorld: advancedStartNwColonizationTopology(),
        warpLinks: advancedStartDefaultWarpLinks,
        tileMapByRegion: {
          kRegionNewWorld: advancedStartNwColonizationTileMap(),
        },
        topologyByRegion: {
          kRegionNewWorld: advancedStartNwColonizationTopology(),
        },
      );
      expect(game.worldState.newWorld.provinces.single.ownerId, 'tribe1');
    });
  });
}
