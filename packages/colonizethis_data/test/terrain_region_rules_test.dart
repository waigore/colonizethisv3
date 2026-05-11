import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('terrain region rules', () {
    test('allowedTerrainsForRegion returns expected sets', () {
      expect(
        allowedTerrainsForRegion('oldWorld'),
        orderedEquals(oldWorldTerrains),
      );
      expect(
        allowedTerrainsForRegion('newWorld'),
        orderedEquals(newWorldTerrains),
      );
      expect(
        allowedTerrainsForRegion('unknown_region'),
        orderedEquals(oldWorldTerrains),
      );
    });

    test(
      'terrainDistributionForRegion returns normalized old world fractions',
      () {
        final distribution = terrainDistributionForRegion('oldWorld');
        expect(distribution.mountainFraction, closeTo(0.15, 1e-9));
        expect(distribution.fractionFor(TerrainType.desert), 0.0);

        final total =
            distribution.mountainFraction +
            distribution.nonMountainFractions.values.fold<double>(
              0.0,
              (sum, value) => sum + value,
            );
        expect(total, closeTo(1.0, 1e-9));
      },
    );

    test('terrainDistributionForRegion includes desert in new world only', () {
      final oldWorld = terrainDistributionForRegion('oldWorld');
      final newWorld = terrainDistributionForRegion('newWorld');
      expect(oldWorld.fractionFor(TerrainType.desert), 0.0);
      expect(newWorld.fractionFor(TerrainType.desert), greaterThan(0.0));
      expect(newWorld.mountainFraction, closeTo(0.15, 1e-9));
    });
  });
}
