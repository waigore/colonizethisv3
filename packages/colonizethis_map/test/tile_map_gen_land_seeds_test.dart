import 'dart:math';

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TileMapGenLandSeeds', () {
    test('placeLandSeeds returns continent and land seed metadata', () {
      final params = TileMapParams(width: 20, height: 12, seed: 7);
      final pass = TileMapGenLandSeeds(params);
      final provinceToContinent = <String, int>{
        'p1': 0,
        'p2': 0,
        'p3': 1,
        'p4': 1,
      };

      final (continentSeeds, landSeeds, continentBySeedIndex) = pass
          .placeLandSeeds(provinceToContinent, Random(7));

      expect(continentSeeds.length, 2);
      expect(landSeeds, isNotEmpty);
      expect(continentBySeedIndex.length, landSeeds.length);
      expect(continentBySeedIndex.toSet(), containsAll(<int>[0, 1]));
    });

    test('assignLandByLandSeeds respects the expected land budget', () {
      final params = TileMapParams(
        width: 20,
        height: 20,
        seed: 11,
        seaFraction: 0.6,
      );
      final pass = TileMapGenLandSeeds(params);
      final provinceToContinent = <String, int>{
        'p1': 0,
        'p2': 0,
        'p3': 1,
        'p4': 1,
      };
      final grid = List.generate(
        params.height,
        (_) => List.filled(params.width, 's1'),
      );
      final (_, landSeeds, continentBySeedIndex) = pass.placeLandSeeds(
        provinceToContinent,
        Random(11),
      );

      final assigned = pass.assignLandByLandSeeds(
        grid,
        landSeeds,
        continentBySeedIndex,
        provinceToContinent,
        's1',
      );

      final landCells = assigned
          .expand((row) => row)
          .where((cell) => cell == '_land')
          .length;
      final expectedLandBudget =
          ((1 - params.seaFraction) * params.width * params.height).round();
      expect(landCells, expectedLandBudget);
    });
  });
}
