import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('RegimentEconomyCatalog', () {
    test('has entry for every regiment in combat catalog', () {
      // Every RegimentStats.id should have a corresponding RegimentEconomy.
      final economyIds = RegimentEconomyCatalog.byId.keys.toSet();
      for (final stats in regimentCatalog) {
        expect(
          economyIds.contains(stats.id),
          isTrue,
          reason: 'Missing RegimentEconomy for ${stats.id}',
        );
      }
    });

    test('basic invariants hold for all regiment economy entries', () {
      for (final econ in RegimentEconomyCatalog.all) {
        // Non-negative food upkeep.
        expect(econ.foodUpkeep, greaterThanOrEqualTo(0));

        // Training costs should be non-negative; most regiments require some
        // treasury and/or materials, but peasant levies may be cheap.
        expect(econ.buildTreasuryCost, greaterThanOrEqualTo(0));

        for (final entry in econ.buildInputs.entries) {
          expect(entry.value, greaterThan(0),
              reason:
                  'buildInputs[${entry.key}] for ${econ.id} must be positive');
        }
      }
    });
  });
}

