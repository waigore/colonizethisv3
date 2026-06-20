import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

/// Stable fingerprint of province, terrain, and resource grids for regression
/// guards after map-package refactors (Refs #2489).
String tileMapGenerationDigest(TileMapResult result) {
  final buffer = StringBuffer();
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      buffer
        ..write(result.cell(x, y))
        ..write('|')
        ..write(result.terrainAt(x, y)?.name ?? '')
        ..write('|')
        ..write(result.resourceAt(x, y)?.name ?? '')
        ..write(';');
    }
  }
  return buffer.toString().hashCode.toRadixString(16);
}

void main() {
  group('tile map generation determinism', () {
    test(
      'seed 42 oldWorld 24x20 digest unchanged (Refs #2489)',
      () {
        const params = TileMapParams(
          width: 24,
          height: 20,
          seed: 42,
          seaFraction: 0.6,
        );
        final (result, _) = TileMapGenerator(params: params).generate(
          numProvinces: 8,
          numContinents: 2,
          regionId: 'oldWorld',
          resourceRules: ResourceRules.defaultRules,
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
      const params = TileMapParams(
        width: 24,
        height: 20,
        seed: 42,
        seaFraction: 0.6,
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
  });
}
