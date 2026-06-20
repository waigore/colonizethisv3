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

    test('forest split: hardwood:scrub weight ratio is 1:4 (#3573 R6)', () {
      for (final region in const ['oldWorld', 'newWorld']) {
        final d = terrainDistributionForRegion(region);
        final hardwood = d.fractionFor(TerrainType.hardwoodForest);
        final scrub = d.fractionFor(TerrainType.scrubForest);
        expect(hardwood, greaterThan(0.0), reason: '$region hardwood present');
        expect(scrub, greaterThan(0.0), reason: '$region scrub present');
        // 0.3 : 1.2 == 1 : 4.
        expect(scrub, closeTo(hardwood * 4.0, 1e-9), reason: '$region ratio');
      }
    });

    test(
      'forest split: total forest weight halved; freed weight to plains '
      '(#3573 R6)',
      () {
        // Old World non-mountain weights sum to 10.0 with the rebalance, so the
        // normalized fractions equal weight * (1 - 0.15) / 10.0.
        final d = terrainDistributionForRegion('oldWorld');
        const scale = (1.0 - 0.15) / 10.0;
        expect(d.fractionFor(TerrainType.plains), closeTo(5.5 * scale, 1e-9));
        expect(
          d.fractionFor(TerrainType.hardwoodForest),
          closeTo(0.3 * scale, 1e-9),
        );
        expect(
          d.fractionFor(TerrainType.scrubForest),
          closeTo(1.2 * scale, 1e-9),
        );
        // Combined forest fraction (1.5 weight) is half of the legacy 3.0.
        final forestFraction =
            d.fractionFor(TerrainType.hardwoodForest) +
            d.fractionFor(TerrainType.scrubForest);
        expect(forestFraction, closeTo(1.5 * scale, 1e-9));
        // Scrub is far more common than hardwood (negative: hardwood is rare).
        expect(
          d.fractionFor(TerrainType.scrubForest),
          greaterThan(d.fractionFor(TerrainType.hardwoodForest)),
        );
      },
    );

    test('legacy generic forest is no longer a terrain type (#3573 R1)', () {
      expect(
        TerrainType.values.map((t) => t.name),
        isNot(contains('forest')),
      );
      expect(
        TerrainType.values,
        containsAll(const [
          TerrainType.hardwoodForest,
          TerrainType.scrubForest,
        ]),
      );
    });
  });
}
