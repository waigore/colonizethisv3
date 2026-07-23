import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'support/combat_config_spec_regiments.dart';

void main() {
  group('CombatConfig', () {
    test(
      'regimentCatalog matches SPEC/game/military-units.md (29 types, order, stats)',
      () {
        expect(combatConfigMilitaryUnitsSpecById.length, 29);
        expect(combatConfigMilitaryUnitsSpecTableOrderIds.length, 29);
        expect(regimentCatalog.length, 29);

        final idsInCatalog = regimentCatalog.map((r) => r.id).toList();
        expect(idsInCatalog.toSet().length, 29, reason: 'no duplicate ids');
        expect(
          idsInCatalog,
          combatConfigMilitaryUnitsSpecTableOrderIds,
          reason: 'catalog order must match GDD regiment table',
        );
        expect(
          idsInCatalog.toSet(),
          combatConfigMilitaryUnitsSpecById.keys.toSet(),
          reason: 'catalog ids must match SPEC table ids exactly',
        );

        for (final r in regimentCatalog) {
          final expected = combatConfigMilitaryUnitsSpecById[r.id];
          expect(expected, isNotNull, reason: 'missing SPEC row for ${r.id}');
          final e = expected!;
          expect(r.fpn, e.fpn, reason: r.id);
          expect(r.fpm, e.fpm, reason: r.id);
          expect(r.rng, e.rng, reason: r.id);
          expect(r.def, e.def, reason: r.id);
          expect(r.mvr, e.mvr, reason: r.id);
          expect(r.category, e.category, reason: r.id);
          expect(r.era, e.era, reason: r.id);
        }
      },
    );

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

    test('terrainModifiers contains plains, forests, mountain, desert', () {
      expect(terrainModifiers['plains'], (1.0, 1.0));
      expect(terrainModifiers['hardwoodForest']?.$1, 0.9);
      expect(terrainModifiers['hardwoodForest']?.$2, 1.5);
      expect(terrainModifiers['scrubForest']?.$1, 0.9);
      expect(terrainModifiers['scrubForest']?.$2, 1.1);
      expect(terrainModifiers['mountain']?.$2, 1.2);
      expect(terrainModifiers['desert'], (1.0, 1.0));
    });

    test('fort arrays have 4 elements for levels 0-3', () {
      expect(fortDamageReduction.length, 4);
      expect(fortEmplacedStrength.length, 4);
      expect(fortGunCount.length, 4);
      expect(wallHpByFortLevel.length, 4);
      expect(emplacedVirtualGunMaxHpByFortLevel.length, 4);
    });

    test(
      'heavyArtilleryBaselineRngForMilitaryLevel matches era heavy piece',
      () {
        expect(heavyArtilleryBaselineRngForMilitaryLevel(1), 5); // culverin
        expect(
          heavyArtilleryBaselineRngForMilitaryLevel(2),
          8,
        ); // royal_artillery
        expect(
          heavyArtilleryBaselineRngForMilitaryLevel(3),
          10,
        ); // heavy_artillery
        expect(heavyArtilleryBaselineRngForMilitaryLevel(4), 12); // siege_guns
      },
    );

    test('emplacedVirtualGunTierMultiplier', () {
      expect(emplacedVirtualGunTierMultiplier(null), 1.0);
      expect(emplacedVirtualGunTierMultiplier({}), 1.0);
      expect(
        emplacedVirtualGunTierMultiplier({kTechHeavyEmplacedArtillery: true}),
        1.15,
      );
      expect(
        emplacedVirtualGunTierMultiplier({
          kTechHeavyEmplacedArtillery: true,
          kTechEmplacedSiegeGuns: true,
        }),
        1.30,
      );
    });

    test('fort damage reduction matches SPEC/game/siege-mechanics.md', () {
      expect(fortDamageReduction[0], 0.0);
      expect(fortDamageReduction[1], 0.25); // Wood
      expect(fortDamageReduction[2], 0.45); // Stone
      expect(fortDamageReduction[3], 0.60); // Modern
    });

    group('garrisonRecoveryRegimentTypeForEra', () {
      test('era 4 picks guards (max FPN+FPM among infantry-eligible)', () {
        expect(garrisonRecoveryRegimentTypeForEra(4), 'guards');
      });

      test('era 3 picks grenadiers', () {
        expect(garrisonRecoveryRegimentTypeForEra(3), 'grenadiers');
      });

      test('era 2 picks musketeers', () {
        expect(garrisonRecoveryRegimentTypeForEra(2), 'musketeers');
      });

      test('era 1 picks arquebusiers', () {
        expect(garrisonRecoveryRegimentTypeForEra(1), 'arquebusiers');
      });

      test('clamps era into 1..4', () {
        expect(garrisonRecoveryRegimentTypeForEra(0), 'arquebusiers');
        expect(garrisonRecoveryRegimentTypeForEra(99), 'guards');
      });

      test(
        'selectGarrisonRecoveryRegimentType tie-break uses lexicographic id',
        () {
          const a = RegimentStats(
            id: 'zebra_inf',
            fpn: 5,
            fpm: 5,
            rng: 1,
            def: 3,
            mvr: 3,
            category: RegimentCategory.lightInfantry,
            era: 1,
          );
          const b = RegimentStats(
            id: 'alpha_inf',
            fpn: 5,
            fpm: 5,
            rng: 1,
            def: 3,
            mvr: 3,
            category: RegimentCategory.regularInfantry,
            era: 1,
          );
          expect(selectGarrisonRecoveryRegimentType([a, b]), 'alpha_inf');
          expect(selectGarrisonRecoveryRegimentType([b, a]), 'alpha_inf');
        },
      );

      test(
        'selectGarrisonRecoveryRegimentType empty yields peasant_levies',
        () {
          expect(selectGarrisonRecoveryRegimentType([]), 'peasant_levies');
        },
      );
    });
  });
}
