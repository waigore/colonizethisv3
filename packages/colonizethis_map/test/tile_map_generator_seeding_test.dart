import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'support/tile_map_gen_fixtures.dart';

void main() {
  group('TileMapGenerator land seeding', () {
    test(
      'Pass 2 places continent seeds and clustered land seeds (log reports counts)',
      () {
        final logLines = <String>[];
        TileMapGenerator(
          params: genParams(
            width: 24,
            height: 24,
            seed: 5,
          ),
        ).generate(
          numProvinces: 2,
          numContinents: 1,
          regionId: 'r1',
          onLog: (msg) => logLines.add(msg),
        );
        final pass2 = logLines.where((s) => s.contains('Pass 2')).single;
        expect(pass2, contains('Continent seeds'));
        expect(pass2, contains('land seeds'));
        expect(pass2, contains('1')); // 1 continent
      },
    );

    test(
      'onLandSeedsPlaced is invoked with land seed positions and continent indices',
      () {
        List<(int x, int y)>? capturedPositions;
        List<int>? capturedIndices;
        TileMapGenerator(
          params: genParams(
            width: 20,
            height: 15,
            seed: 1,
          ),
        ).generate(
          numProvinces: 1,
          numContinents: 1,
          regionId: 'r1',
          onLandSeedsPlaced: (positions, indices) {
            capturedPositions = positions;
            capturedIndices = indices;
          },
        );
        expect(capturedPositions, isNotNull);
        expect(capturedIndices, isNotNull);
        expect(capturedPositions!.length, greaterThan(0));
        expect(capturedIndices!.length, capturedPositions!.length);
        for (final c in capturedIndices!) {
          expect(
            c,
            inInclusiveRange(0, 0),
            reason: 'Single continent: all indices 0',
          );
        }
      },
    );

    test('onContinentSeedsPlaced is invoked with one seed per continent', () {
      List<(int x, int y)>? continentSeeds;
      TileMapGenerator(
        params: genParams(width: 24, height: 24, seed: 7),
      ).generate(
        numProvinces: 2,
        numContinents: 1,
        regionId: 'r1',
        onContinentSeedsPlaced: (s) => continentSeeds = s,
      );
      expect(continentSeeds, isNotNull);
      expect(continentSeeds!.length, 1); // one continent
    });

    test(
      'seedBeforeAssignment: true produces valid tile map with land count matching budget',
      () {
        const w = 20;
        const h = 20;
        const seaFraction = 0.6;
        final params = genParams(
          width: w,
          height: h,
          seed: 1,
          seaFraction: seaFraction,
          seedBeforeAssignment: true,
        );
        final (result, _) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 1, numContinents: 1, regionId: 'r1');
        var landCount = 0;
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
          }
        }
        final expectedLand = ((1 - seaFraction) * w * h).round();
        expect(landCount, expectedLand);
      },
    );

    test(
      'seedBeforeAssignment: false (organic default) produces valid tile map with land',
      () {
        final params = genParams(
          width: 30,
          height: 30,
          seed: 42,
          seedBeforeAssignment: false,
        );
        final (result, _) = TileMapGenerator(
          params: params,
        ).generate(numProvinces: 2, numContinents: 1, regionId: 'r1');
        var landCount = 0;
        for (var y = 0; y < result.height; y++) {
          for (var x = 0; x < result.width; x++) {
            if (!RegExp(r'^s\d+$').hasMatch(result.cell(x, y))) landCount++;
          }
        }
        expect(landCount, greaterThan(0));
        expect(result.adjacentRegionPairs(), contains('p1|p2'));
      },
    );

    test('organic mode logs Pass 2–3 (organic)', () {
      final logLines = <String>[];
      TileMapGenerator(
        params: genParams(
          width: 10,
          height: 10,
          seed: 1,
          seedBeforeAssignment: false,
        ),
      ).generate(
        numProvinces: 1,
        numContinents: 1,
        regionId: 'r1',
        onLog: (msg) => logLines.add(msg),
      );
      expect(logLines.any((s) => s.contains('organic')), isTrue);
    });
  });
}
