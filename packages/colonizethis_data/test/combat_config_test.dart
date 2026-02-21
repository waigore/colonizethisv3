import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('CombatConfig', () {
    test('regiment catalog has 28 land military types per SPEC', () {
      expect(regimentCatalog.length, greaterThanOrEqualTo(28));
    });

    test('regimentStatsById returns stats for known type', () {
      final stats = regimentStatsById('grenadiers');
      expect(stats, isNotNull);
      expect(stats!.fpn, 10);
      expect(stats.fpm, 8);
      expect(stats.category, RegimentCategory.heavyInfantry);
      expect(stats.era, 3);
    });

    test('regimentStatsById returns null for unknown type', () {
      expect(regimentStatsById('unknown_type'), isNull);
    });

    test('medalMultiplierFor returns correct values', () {
      expect(medalMultiplierFor(0), 1.0);
      expect(medalMultiplierFor(1), 1.1);
      expect(medalMultiplierFor(4), 1.4);
      expect(medalMultiplierFor(-1), 1.0);
      expect(medalMultiplierFor(5), 1.0);
    });

    test('terrainModifiers contains plains, forest, mountain, desert', () {
      expect(terrainModifiers['plains'], (1.0, 1.0));
      expect(terrainModifiers['forest']?.$1, 0.9);
      expect(terrainModifiers['mountain']?.$2, 1.2);
      expect(terrainModifiers['desert'], (1.0, 1.0));
    });

    test('fort arrays have 4 elements for levels 0-3', () {
      expect(fortDamageReduction.length, 4);
      expect(fortEmplacedStrength.length, 4);
      expect(fortGunCount.length, 4);
      expect(wallHpByFortLevel.length, 4);
    });

    test('fort damage reduction matches SPEC/game/siege-mechanics.md', () {
      expect(fortDamageReduction[0], 0.0);
      expect(fortDamageReduction[1], 0.25); // Wood
      expect(fortDamageReduction[2], 0.45); // Stone
      expect(fortDamageReduction[3], 0.60); // Modern
    });
  });
}
