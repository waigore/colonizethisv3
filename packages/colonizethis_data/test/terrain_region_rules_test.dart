import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('oldWorldTerrains / newWorldTerrains', () {
    test('oldWorldTerrains does not include desert', () {
      expect(oldWorldTerrains.contains(TerrainType.desert), isFalse);
      expect(oldWorldTerrains, contains(TerrainType.plains));
      expect(oldWorldTerrains, contains(TerrainType.forest));
      expect(oldWorldTerrains, contains(TerrainType.mountain));
    });

    test('newWorldTerrains includes desert (SPEC resource-terrain-region)', () {
      expect(newWorldTerrains, contains(TerrainType.desert));
      expect(newWorldTerrains.length, greaterThan(oldWorldTerrains.length));
    });
  });

  group('allowedTerrainsForRegion', () {
    test('oldWorld returns oldWorldTerrains', () {
      final list = allowedTerrainsForRegion('oldWorld');
      expect(list, equals(oldWorldTerrains));
    });

    test('newWorld returns newWorldTerrains', () {
      final list = allowedTerrainsForRegion('newWorld');
      expect(list, equals(newWorldTerrains));
    });

    test('unknown region falls back to oldWorldTerrains', () {
      final list = allowedTerrainsForRegion('unknown');
      expect(list, equals(oldWorldTerrains));
    });
  });

  group('terrainDistributionForRegion', () {
    test('oldWorld returns distribution with mountain fraction', () {
      final dist = terrainDistributionForRegion('oldWorld');
      expect(dist.mountainFraction, inInclusiveRange(0.0, 1.0));
      expect(dist.fractionFor(TerrainType.mountain), dist.mountainFraction);
    });

    test('newWorld returns distribution including desert', () {
      final dist = terrainDistributionForRegion('newWorld');
      expect(dist.nonMountainFractions, contains(TerrainType.desert));
      expect(dist.fractionFor(TerrainType.desert), greaterThan(0));
    });

    test('unknown region falls back to oldWorld distribution', () {
      final dist = terrainDistributionForRegion('other');
      expect(dist.mountainFraction, inInclusiveRange(0.0, 1.0));
      expect(dist.nonMountainFractions, isNotEmpty);
    });
  });

  group('TerrainDistribution.fractionFor', () {
    test('mountain returns mountainFraction', () {
      const dist = TerrainDistribution(
        mountainFraction: 0.2,
        nonMountainFractions: {
          TerrainType.plains: 0.5,
          TerrainType.forest: 0.3,
        },
      );
      expect(dist.fractionFor(TerrainType.mountain), 0.2);
    });

    test('non-mountain returns value from map or 0', () {
      const dist = TerrainDistribution(
        mountainFraction: 0.1,
        nonMountainFractions: {
          TerrainType.plains: 0.6,
          TerrainType.forest: 0.3,
        },
      );
      expect(dist.fractionFor(TerrainType.plains), 0.6);
      expect(dist.fractionFor(TerrainType.forest), 0.3);
      expect(dist.fractionFor(TerrainType.desert), 0.0);
    });
  });
}
