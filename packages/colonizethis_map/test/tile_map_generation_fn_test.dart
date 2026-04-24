import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('defaultTileMapRegionGenerator', () {
    test('delegates to TileMapGenerator and emits callbacks', () {
      var logs = 0;
      var landSeedCallbackCalled = false;
      var continentSeedCallbackCalled = false;

      final (result, topology) = defaultTileMapRegionGenerator(
        params: const TileMapParams(
          width: 20,
          height: 14,
          seed: 3,
          seaFraction: 0.6,
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
