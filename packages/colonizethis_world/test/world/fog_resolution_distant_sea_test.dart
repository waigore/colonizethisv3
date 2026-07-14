import 'package:colonizethis_world/src/world/fog_resolution.dart';
import 'package:colonizethis_world/src/world/player_view.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/src/constants.dart';

import '../world_test_support/world_test_support.dart';

void main() {
  _fog_resolution_distant_sea_testTests();
}

void _fog_resolution_distant_sea_testTests() {
  group('applyDistantSeaZoneFogRevert', () {
    test(
      'fogs open-ocean sea tiles when no owned coast and no fleet at sea',
      () {
        const ow = 'oldWorld';
        const tileSea2 = 'oldWorld|s2|0|0';
        final topology = provinceSeaChainTopology(regionId: ow);
        final game = distantSeaVisibilityGame(
          oldWorldProvinces: const [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
          ],
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|s1': ['oldWorld|s1|0|0'],
              '$ow|s2': [tileSea2],
            },
          },
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
        };

        final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

        expect(out['gp1']![tileSea2], VisibilityLevel.fogged.name);
      },
    );

    test('does not fog sea zone while player fleet is at sea there', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = provinceSeaChainTopology(regionId: ow);
      final game = distantSeaVisibilityGame(
        oldWorldProvinces: const [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            '$ow|s2': [tileSea2],
          },
        },
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'gp1',
            seaZoneId: 's2',
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.fullyVisible.name);
    });

    test('other player fleet at sea does not block distant fog revert', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = provinceSeaChainTopology(regionId: ow);
      final game = distantSeaVisibilityGame(
        oldWorldProvinces: const [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            '$ow|s2': [tileSea2],
          },
        },
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'gp2',
            seaZoneId: 's2',
            regionId: ow,
            shipTypeIds: const ['carrack'],
          ),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.fogged.name);
    });

    test(
      'GitHub #2023: distant fog revert for New World does not throw when same '
      'player has Old World fleet at sea (cross-region scan)',
      () {
        const ow = kRegionOldWorld;
        const nw = kRegionNewWorld;
        const tileNwSea = 'newWorld|nwSea|0|0';
        final topologies = owSeaChainWithIsolatedNwSea();
        final game = distantSeaVisibilityGame(
          id: 'g_fog_2023',
          oldWorldProvinces: const [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
          ],
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|s2': const ['oldWorld|s2|0|0'],
            },
            nw: {
              '$nw|nwSea': [tileNwSea],
            },
          },
          fleets: [
            Fleet(
              id: 'f_ow',
              ownerId: 'gp1',
              seaZoneId: 's2',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final inputVis = <String, Map<String, String>>{
          'gp1': {tileNwSea: VisibilityLevel.fullyVisible.name},
        };

        final out = applyDistantSeaZoneFogRevert(
          game,
          inputVis,
          topologies.combined,
          topologyByRegion: {ow: topologies.ow, nw: topologies.nw},
        );

        expect(out['gp1']![tileNwSea], VisibilityLevel.fogged.name);
      },
    );

    test('fogs distant sea when player fleet is in port only (not at sea)', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = provinceSeaChainTopology(regionId: ow);
      final game = distantSeaVisibilityGame(
        oldWorldProvinces: const [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
        tileKeysByRegionAndProvince: const {
          ow: {
            '$ow|s2': [tileSea2],
          },
        },
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'gp1',
            regionId: ow,
            inPortAtProvinceId: '$ow|p1',
            shipTypeIds: const ['carrack'],
          ),
        ],
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.fullyVisible.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.fogged.name);
    });

    test('does not change unknown water tiles', () {
      const ow = 'oldWorld';
      const tileSea2 = 'oldWorld|s2|0|0';
      final topology = isolatedSeaZoneTopology(regionId: ow, seaZoneId: 's2');
      final game = distantSeaVisibilityGame(
        tileKeysByRegionAndProvince: const {
          ow: {
            '$ow|s2': [tileSea2],
          },
        },
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final inputVis = <String, Map<String, String>>{
        'gp1': {tileSea2: VisibilityLevel.unknown.name},
      };

      final out = applyDistantSeaZoneFogRevert(game, inputVis, topology);

      expect(out['gp1']![tileSea2], VisibilityLevel.unknown.name);
    });
  });
}
