import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Expected tactical row per SPEC/game/military-units.md § Regiment Table (order = table order).
typedef _SpecRegimentRow = ({
  int fpn,
  int fpm,
  int rng,
  int def,
  int mvr,
  RegimentCategory category,
  int era,
});

/// Keys: regiment id. Values: FPN, FPM, RNG, DEF, MVR, category, era.
const _militaryUnitsSpecById = <String, _SpecRegimentRow>{
  'peasant_levies': (
    fpn: 0,
    fpm: 3,
    rng: 1,
    def: 3,
    mvr: 3,
    category: RegimentCategory.lightInfantry,
    era: 1,
  ),
  'pikemen': (
    fpn: 0,
    fpm: 5,
    rng: 1,
    def: 5,
    mvr: 3,
    category: RegimentCategory.regularInfantry,
    era: 1,
  ),
  'arquebusiers': (
    fpn: 5,
    fpm: 1,
    rng: 3,
    def: 3,
    mvr: 2,
    category: RegimentCategory.heavyInfantry,
    era: 1,
  ),
  'bowmen': (
    fpn: 3,
    fpm: 1,
    rng: 4,
    def: 2,
    mvr: 3,
    category: RegimentCategory.bowmen,
    era: 1,
  ),
  'squires': (
    fpn: 0,
    fpm: 4,
    rng: 1,
    def: 4,
    mvr: 6,
    category: RegimentCategory.lightCavalry,
    era: 1,
  ),
  'knights': (
    fpn: 0,
    fpm: 6,
    rng: 1,
    def: 6,
    mvr: 4,
    category: RegimentCategory.spearCavalry,
    era: 1,
  ),
  'culverin': (
    fpn: 8,
    fpm: 1,
    rng: 5,
    def: 2,
    mvr: 2,
    category: RegimentCategory.heavyArtillery,
    era: 1,
  ),
  'calivermen': (
    fpn: 3,
    fpm: 2,
    rng: 5,
    def: 5,
    mvr: 4,
    category: RegimentCategory.lightInfantry,
    era: 2,
  ),
  'halberdiers': (
    fpn: 0,
    fpm: 7,
    rng: 1,
    def: 6,
    mvr: 4,
    category: RegimentCategory.regularInfantry,
    era: 2,
  ),
  'musketeers': (
    fpn: 7,
    fpm: 2,
    rng: 4,
    def: 4,
    mvr: 3,
    category: RegimentCategory.heavyInfantry,
    era: 2,
  ),
  'cossacks': (
    fpn: 0,
    fpm: 5,
    rng: 1,
    def: 5,
    mvr: 8,
    category: RegimentCategory.lightCavalry,
    era: 2,
  ),
  'lancers': (
    fpn: 0,
    fpm: 8,
    rng: 1,
    def: 5,
    mvr: 6,
    category: RegimentCategory.spearCavalry,
    era: 2,
  ),
  'harquebusiers': (
    fpn: 2,
    fpm: 6,
    rng: 3,
    def: 5,
    mvr: 6,
    category: RegimentCategory.heavyCavalry,
    era: 2,
  ),
  'horse_artillery': (
    fpn: 5,
    fpm: 2,
    rng: 7,
    def: 2,
    mvr: 3,
    category: RegimentCategory.lightArtillery,
    era: 2,
  ),
  'royal_artillery': (
    fpn: 9,
    fpm: 2,
    rng: 8,
    def: 2,
    mvr: 2,
    category: RegimentCategory.heavyArtillery,
    era: 2,
  ),
  'skirmishers': (
    fpn: 4,
    fpm: 3,
    rng: 5,
    def: 6,
    mvr: 6,
    category: RegimentCategory.lightInfantry,
    era: 3,
  ),
  'regulars': (
    fpn: 7,
    fpm: 7,
    rng: 5,
    def: 5,
    mvr: 4,
    category: RegimentCategory.regularInfantry,
    era: 3,
  ),
  'grenadiers': (
    fpn: 10,
    fpm: 8,
    rng: 5,
    def: 5,
    mvr: 4,
    category: RegimentCategory.heavyInfantry,
    era: 3,
  ),
  'hussars': (
    fpn: 2,
    fpm: 8,
    rng: 3,
    def: 6,
    mvr: 11,
    category: RegimentCategory.lightCavalry,
    era: 3,
  ),
  'cuirassiers': (
    fpn: 5,
    fpm: 13,
    rng: 3,
    def: 5,
    mvr: 9,
    category: RegimentCategory.heavyCavalry,
    era: 3,
  ),
  'light_artillery': (
    fpn: 8,
    fpm: 3,
    rng: 9,
    def: 3,
    mvr: 4,
    category: RegimentCategory.lightArtillery,
    era: 3,
  ),
  'heavy_artillery': (
    fpn: 13,
    fpm: 2,
    rng: 10,
    def: 2,
    mvr: 3,
    category: RegimentCategory.heavyArtillery,
    era: 3,
  ),
  'sharpshooters': (
    fpn: 5,
    fpm: 4,
    rng: 7,
    def: 7,
    mvr: 7,
    category: RegimentCategory.lightInfantry,
    era: 4,
  ),
  'rifle_infantry': (
    fpn: 9,
    fpm: 9,
    rng: 6,
    def: 6,
    mvr: 4,
    category: RegimentCategory.regularInfantry,
    era: 4,
  ),
  'guards': (
    fpn: 12,
    fpm: 10,
    rng: 6,
    def: 6,
    mvr: 4,
    category: RegimentCategory.heavyInfantry,
    era: 4,
  ),
  'scouts': (
    fpn: 5,
    fpm: 11,
    rng: 5,
    def: 6,
    mvr: 11,
    category: RegimentCategory.lightCavalry,
    era: 4,
  ),
  'carbine_cavalry': (
    fpn: 7,
    fpm: 17,
    rng: 5,
    def: 5,
    mvr: 9,
    category: RegimentCategory.heavyCavalry,
    era: 4,
  ),
  'field_artillery': (
    fpn: 10,
    fpm: 3,
    rng: 11,
    def: 4,
    mvr: 5,
    category: RegimentCategory.lightArtillery,
    era: 4,
  ),
  'siege_guns': (
    fpn: 17,
    fpm: 2,
    rng: 12,
    def: 3,
    mvr: 3,
    category: RegimentCategory.heavyArtillery,
    era: 4,
  ),
};

/// Table order in SPEC/game/military-units.md (must match [regimentCatalog] order).
const _militaryUnitsSpecTableOrderIds = <String>[
  'peasant_levies',
  'pikemen',
  'arquebusiers',
  'bowmen',
  'squires',
  'knights',
  'culverin',
  'calivermen',
  'halberdiers',
  'musketeers',
  'cossacks',
  'lancers',
  'harquebusiers',
  'horse_artillery',
  'royal_artillery',
  'skirmishers',
  'regulars',
  'grenadiers',
  'hussars',
  'cuirassiers',
  'light_artillery',
  'heavy_artillery',
  'sharpshooters',
  'rifle_infantry',
  'guards',
  'scouts',
  'carbine_cavalry',
  'field_artillery',
  'siege_guns',
];

void main() {
  group('CombatConfig', () {
    test(
      'regimentCatalog matches SPEC/game/military-units.md (29 types, order, stats)',
      () {
        expect(_militaryUnitsSpecById.length, 29);
        expect(_militaryUnitsSpecTableOrderIds.length, 29);
        expect(regimentCatalog.length, 29);

        final idsInCatalog = regimentCatalog.map((r) => r.id).toList();
        expect(idsInCatalog.toSet().length, 29, reason: 'no duplicate ids');
        expect(
          idsInCatalog,
          _militaryUnitsSpecTableOrderIds,
          reason: 'catalog order must match GDD regiment table',
        );
        expect(
          idsInCatalog.toSet(),
          _militaryUnitsSpecById.keys.toSet(),
          reason: 'catalog ids must match SPEC table ids exactly',
        );

        for (final r in regimentCatalog) {
          final expected = _militaryUnitsSpecById[r.id];
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
