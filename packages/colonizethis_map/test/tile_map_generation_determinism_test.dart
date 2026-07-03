import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('tile map generation determinism', () {
    test(
      'seed 42 oldWorld 24x20 digest unchanged (Refs #2489)',
      () {
        final (result, _) = runTileMapGeneration(
          width: 24,
          height: 20,
          seed: 42,
        );
        // Digest updated for the forest terrain split (#3573): R6 weights, the
        // guaranteed forest resource spawn (R3), and the hardwood clustering
        // post-pass (R7) all change the seeded terrain/resource layout.
        // Regenerate this constant whenever terrain distribution weights,
        // resource placement, or generation order change intentionally.
        expect(tileMapGenerationDigest(result), '314034fe');
      },
    );

    test('same seed and params yield identical digest', () {
      final params = genParams(
        width: 24,
        height: 20,
        seed: 42,
      );
      final gen = TileMapGenerator(params: params);
      final (a, _) = gen.generate(
        numProvinces: 8,
        numContinents: 2,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      final (b, _) = gen.generate(
        numProvinces: 8,
        numContinents: 2,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
      );
      expect(tileMapGenerationDigest(a), tileMapGenerationDigest(b));
    });

    test('fixed seed yields identical grid and topology on repeat (Refs #2489)', () {
      const seed = 248_901;
      final params = genParams(
        width: 48,
        height: 36,
        seed: seed,
        seaFraction: 0.55,
      );
      const numProvinces = 24;
      const numContinents = 3;
      const regionId = 'oldWorld';

      final gen = TileMapGenerator(params: params);
      final (firstResult, firstTopology) = gen.generate(
        numProvinces: numProvinces,
        numContinents: numContinents,
        regionId: regionId,
      );
      final (secondResult, secondTopology) = gen.generate(
        numProvinces: numProvinces,
        numContinents: numContinents,
        regionId: regionId,
      );

      expect(secondResult.width, firstResult.width);
      expect(secondResult.height, firstResult.height);
      expect(secondResult.grid, firstResult.grid);

      expect(
        topologyNodeKeys(secondTopology.nodes),
        topologyNodeKeys(firstTopology.nodes),
      );
      expect(
        topologyEdgeKeys(secondTopology.edges),
        topologyEdgeKeys(firstTopology.edges),
      );
    });
  });
}
