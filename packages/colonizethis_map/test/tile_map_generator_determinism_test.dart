import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('TileMapGenerator determinism (Refs #2489)', () {
    test('fixed seed yields identical grid and topology on repeat', () {
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

      List<(String, TopologyNodeType, String)> nodeKeys(
        Iterable<TopologyNode> nodes,
      ) =>
          nodes.map((n) => (n.id, n.type, n.regionId)).toList();
      expect(nodeKeys(secondTopology.nodes), nodeKeys(firstTopology.nodes));

      List<String> edgeKeys(Iterable<TopologyEdge> edges) => edges
          .map((e) => '${e.id1}|${e.id2}')
          .toList()
        ..sort();
      expect(edgeKeys(secondTopology.edges), edgeKeys(firstTopology.edges));
    });
  });
}
