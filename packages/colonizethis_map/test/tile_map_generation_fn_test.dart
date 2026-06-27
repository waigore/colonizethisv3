import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('defaultTileMapRegionGenerator', () {
    test('delegates to TileMapGenerator and emits callbacks', () {
      var logs = 0;
      var landSeedCallbackCalled = false;
      var continentSeedCallbackCalled = false;

      final (result, topology) = defaultTileMapRegionGenerator(
        params: genParams(
          width: 20,
          height: 14,
          seed: 3,
        ),
        numProvinces: 4,
        numContinents: 2,
        regionId: 'oldWorld',
        onLog: (_) => logs++,
        onLandSeedsPlaced: (landSeeds, continents) {
          landSeedCallbackCalled = true;
          expect(landSeeds, isNotEmpty);
          expect(continents.length, landSeeds.length);
        },
        onContinentSeedsPlaced: (continentSeeds) {
          continentSeedCallbackCalled = true;
          expect(continentSeeds.length, 2);
        },
      );

      expect(result.width, 20);
      expect(result.height, 14);
      expect(topology.nodes, isNotEmpty);
      expect(logs, greaterThan(0));
      expect(landSeedCallbackCalled, isTrue);
      expect(continentSeedCallbackCalled, isTrue);
    });
  });
}
