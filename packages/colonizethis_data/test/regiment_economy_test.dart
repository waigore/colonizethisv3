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

    test('catalog digest matches pre-wave-5 baseline (AC3)', () {
      final digest = RegimentEconomyCatalog.all.map((e) {
        final inputs = e.buildInputs.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .toList()
          ..sort();
        return '${e.id}:${e.buildTreasuryCost}:${e.foodUpkeep}:${inputs.join(',')}';
      }).join('|');
      expect(digest, _regimentEconomyCatalogBaselineDigest);
      expect(RegimentEconomyCatalog.all.length, 29);
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

/// Frozen catalog fingerprint from dev pre–wave-5 split (Refs #4292 AC3).
const _regimentEconomyCatalogBaselineDigest =
    'peasant_levies:2000:1:fabric:1|pikemen:4000:2:castIron:1,fabric:1|'
    'arquebusiers:5000:2:castIron:1,fabric:1|bowmen:3000:1:fabric:1|'
    'squires:6000:3:castIron:1,fabric:1,horses:2|knights:8000:3:castIron:2,'
    'fabric:1,horses:2|culverin:8000:2:castIron:2,fabric:1,lumber:1|'
    'calivermen:7000:2:castIron:1,fabric:1|halberdiers:7000:2:castIron:2,'
    'fabric:1|musketeers:8000:2:castIron:2,fabric:1|cossacks:9000:3:'
    'castIron:2,fabric:1,horses:2|lancers:10000:3:castIron:2,fabric:1,'
    'horses:2|harquebusiers:11000:3:castIron:2,fabric:1,horses:2|'
    'horse_artillery:11000:3:castIron:2,fabric:1,horses:2,lumber:1|'
    'royal_artillery:12000:3:castIron:3,fabric:1,lumber:1|skirmishers:9000:2:'
    'castIron:2,fabric:1|regulars:11000:2:castIron:2,fabric:1|grenadiers:13000:2:'
    'castIron:3,fabric:1|hussars:13000:3:castIron:2,fabric:1,horses:2|'
    'cuirassiers:15000:3:castIron:3,fabric:1,horses:2|light_artillery:14000:3:'
    'castIron:2,fabric:1,lumber:1|heavy_artillery:16000:3:castIron:3,fabric:1,'
    'lumber:1|sharpshooters:12000:2:castIron:2,fabric:1|rifle_infantry:14000:2:'
    'castIron:3,fabric:1|guards:18000:3:castIron:3,fabric:1,steel:1|scouts:'
    '15000:3:castIron:2,fabric:1,horses:2|carbine_cavalry:18000:3:castIron:3,'
    'fabric:1,horses:2|field_artillery:18000:3:castIron:3,fabric:1,lumber:1,'
    'steel:1|siege_guns:22000:3:bronze:1,castIron:3,fabric:1,lumber:2,steel:1';

