import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('extractionCapForResourceForUnlocked', () {
    test('null tech returns default cap 1 for grain', () {
      expect(
        extractionCapForResourceForUnlocked(null, 'grain'),
        equals(defaultExtractionCap),
      );
    });

    test('empty tech returns default cap 1 for grain', () {
      expect(
        extractionCapForResourceForUnlocked({}, 'grain'),
        equals(defaultExtractionCap),
      );
    });

    test('only non-gathering techs keep default cap for grain', () {
      expect(
        extractionCapForResourceForUnlocked({
          'organised_regiments': true,
        }, 'grain'),
        equals(defaultExtractionCap),
      );
      expect(
        extractionCapForResourceForUnlocked({
          'road_construction': true,
          'early_steam_engine': true,
          'improved_iron_weapons': true,
        }, 'grain'),
        equals(defaultExtractionCap),
      );
    });

    test('land_enclosure gives grain cap 2', () {
      expect(
        extractionCapForResourceForUnlocked({'land_enclosure': true}, 'grain'),
        equals(2),
      );
    });

    test('seed_drill gives grain cap 3', () {
      expect(
        extractionCapForResourceForUnlocked({
          'land_enclosure': true,
          'seed_drill': true,
        }, 'grain'),
        equals(3),
      );
    });

    test('moldboard_plow gives grain cap 4', () {
      expect(
        extractionCapForResourceForUnlocked({
          'land_enclosure': true,
          'seed_drill': true,
          'moldboard_plow': true,
        }, 'grain'),
        equals(4),
      );
    });

    test('timber tech does not raise grain cap', () {
      expect(
        extractionCapForResourceForUnlocked({
          'saw_mill': true,
          'organised_regiments': true,
        }, 'grain'),
        equals(1),
      );
    });

    test('wool design cap chain tops at 3', () {
      expect(
        extractionCapForResourceForUnlocked({
          'sheep_ranching': true,
          'scientific_sheep_breeding': true,
        }, 'wool'),
        equals(3),
      );
    });

    test('horses uses explicit design exception cap 1', () {
      expect(extractionCapForResourceForUnlocked({}, 'horses'), equals(1));
    });
  });

  group('unlockingTechByShipId', () {
    test('fluyte requires superior_hull_design', () {
      expect(unlockingTechByShipId['fluyte'], 'superior_hull_design');
    });
    test('carrack has no unlocking tech (buildable from start)', () {
      expect(unlockingTechByShipId['carrack'], isNull);
    });
  });

  group('techDisplayName', () {
    test('uses catalog displayName when set', () {
      expect(techDisplayName('road_construction'), 'Road Construction');
      expect(techDisplayName('crop_rotation'), 'Crop Rotation');
    });
    test('empty returns empty', () {
      expect(techDisplayName(''), '');
    });
  });

  group('researchableTechIds', () {
    test(
      'empty unlocked returns all root techs (no tech prereqs; discovery techs included when callback null)',
      () {
        final r = researchableTechIds({});
        expect(r, isNotEmpty);
        for (final id in r) {
          final tech = techById(id);
          expect(tech, isNotNull);
          expect(tech!.prerequisiteIds, isEmpty);
        }
      },
    );
    test('all unlocked returns empty', () {
      final unlocked = {for (final id in techCatalog.keys) id: true};
      expect(researchableTechIds(unlocked), isEmpty);
    });
    test('saw_mill unlocked adds wind_saw_mill to researchable', () {
      final r = researchableTechIds({'saw_mill': true});
      expect(r.contains('wind_saw_mill'), isTrue);
      expect(r.contains('saw_mill'), isFalse);
    });
    test('null unlocked same as empty', () {
      expect(researchableTechIds(null), researchableTechIds({}));
    });

    test(
      'discovery tech with null callback is researchable when prereqs met',
      () {
        final r = researchableTechIds({});
        expect(
          r.contains('discovery_of_sugar'),
          isTrue,
          reason:
              'Discovery techs are researchable when hasDiscoveredResource is null',
        );
      },
    );

    test(
      'discovery tech with hasDiscoveredResource always false is not researchable',
      () {
        final r = researchableTechIds({}, hasDiscoveredResource: (_) => false);
        expect(r.contains('discovery_of_sugar'), isFalse);
      },
    );

    test(
      'discovery tech with hasDiscoveredResource true for sugarCane is researchable',
      () {
        final r = researchableTechIds(
          {},
          hasDiscoveredResource: (rid) => rid == 'sugarCane',
        );
        expect(r.contains('discovery_of_sugar'), isTrue);
      },
    );
  });
}
