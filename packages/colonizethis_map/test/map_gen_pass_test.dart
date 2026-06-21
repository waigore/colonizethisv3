import 'dart:math';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/gen/map_gen_pass_payloads.dart';
import 'package:colonizethis_map/src/gen/map_gen_stage.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('MapGenPassContext', () {
    final params = TileMapParams(width: 4, height: 3, seed: 1);

    test('log forwards the message when onLog is provided', () {
      final lines = <String>[];
      final ctx = MapGenPassContext<int>(
        params: params,
        payload: 0,
        onLog: lines.add,
      );
      ctx.log('Pass 2: seeds placed');
      expect(lines, <String>['Pass 2: seeds placed']);
    });

    test('log is a no-op when onLog is null', () {
      final ctx = MapGenPassContext<int>(params: params, payload: 0);
      expect(() => ctx.log('ignored'), returnsNormally);
    });

    test('exposes the typed payload and shared params', () {
      final ctx = MapGenPassContext<String>(params: params, payload: 'hello');
      expect(ctx.payload, 'hello');
      expect(ctx.params.width, 4);
      expect(ctx.params.height, 3);
    });
  });

  group('TileMapGenLandSeeds.run (uniform pass entry)', () {
    final provinceToContinent = <String, int>{
      'p1': 0,
      'p2': 0,
      'p3': 1,
      'p4': 1,
    };

    test('seed-before-assignment path matches direct method calls', () {
      final params = TileMapParams(
        width: 20,
        height: 20,
        seed: 11,
        seaFraction: 0.6,
        seedBeforeAssignment: true,
      );
      final pass = TileMapGenLandSeeds(params);

      // Direct (legacy) call sequence with a fresh, identically-seeded RNG.
      final (directContinentSeeds, directLandSeeds, directContinentBySeed) = pass
          .placeLandSeeds(provinceToContinent, Random(params.seed));
      final directGrid = pass.assignLandByLandSeeds(
        List.generate(params.height, (_) => List.filled(params.width, 's1')),
        directLandSeeds,
        directContinentBySeed,
        provinceToContinent,
        's1',
      );

      final result = pass.run(
        MapGenPassContext<LandSeedPassPayload>(
          params: params,
          payload: LandSeedPassPayload(
            grid: List.generate(
              params.height,
              (_) => List.filled(params.width, 's1'),
            ),
            provinceToContinent: provinceToContinent,
            seaZoneId: 's1',
            rnd: Random(params.seed),
            seedBeforeAssignment: true,
          ),
        ),
      );

      expect(result.continentSeeds, directContinentSeeds);
      expect(result.landSeeds, directLandSeeds);
      expect(result.continentBySeedIndex, directContinentBySeed);
      expect(result.grid, directGrid);
    });

    test('organic path matches direct method call', () {
      final params = TileMapParams(
        width: 20,
        height: 14,
        seed: 5,
        seaFraction: 0.6,
      );
      final pass = TileMapGenLandSeeds(params);

      final direct = pass.placeLandSeedsOrganic(
        List.generate(params.height, (_) => List.filled(params.width, 's1')),
        provinceToContinent,
        's1',
        Random(params.seed),
      );

      final result = pass.run(
        MapGenPassContext<LandSeedPassPayload>(
          params: params,
          payload: LandSeedPassPayload(
            grid: List.generate(
              params.height,
              (_) => List.filled(params.width, 's1'),
            ),
            provinceToContinent: provinceToContinent,
            seaZoneId: 's1',
            rnd: Random(params.seed),
            seedBeforeAssignment: false,
          ),
        ),
      );

      expect(result.continentSeeds, direct.$1);
      expect(result.landSeeds, direct.$2);
      expect(result.continentBySeedIndex, direct.$3);
      expect(result.grid, direct.$4);
    });

    test('emits the seed-before-assignment pass log line', () {
      final params = TileMapParams(
        width: 16,
        height: 16,
        seed: 3,
        seaFraction: 0.6,
        seedBeforeAssignment: true,
      );
      final pass = TileMapGenLandSeeds(params);
      final lines = <String>[];

      pass.run(
        MapGenPassContext<LandSeedPassPayload>(
          params: params,
          payload: LandSeedPassPayload(
            grid: List.generate(
              params.height,
              (_) => List.filled(params.width, 's1'),
            ),
            provinceToContinent: provinceToContinent,
            seaZoneId: 's1',
            rnd: Random(params.seed),
            seedBeforeAssignment: true,
          ),
          onLog: lines.add,
        ),
      );

      expect(lines, hasLength(1));
      expect(lines.single, startsWith('Pass 2: Continent seeds '));
    });
  });
}
