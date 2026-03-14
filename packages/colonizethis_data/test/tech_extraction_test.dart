import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('extractionCapForUnlocked', () {
    test('null returns defaultExtractionCap (4)', () {
      expect(extractionCapForUnlocked(null), equals(defaultExtractionCap));
    });

    test('empty map returns defaultExtractionCap (4)', () {
      expect(extractionCapForUnlocked({}), equals(defaultExtractionCap));
    });

    test('only non-gathering techs returns defaultExtractionCap (4)', () {
      expect(
        extractionCapForUnlocked({'organised_regiments': true}),
        equals(defaultExtractionCap),
      );
      expect(
        extractionCapForUnlocked({
          'road_construction': true,
          'early_steam_engine': true,
          'improved_iron_weapons': true,
        }),
        equals(defaultExtractionCap),
      );
    });

    test('saw_mill gives cap 2', () {
      expect(
        extractionCapForUnlocked({'saw_mill': true}),
        equals(2),
      );
    });

    test('seed_drill gives cap 3', () {
      expect(
        extractionCapForUnlocked({'saw_mill': true, 'seed_drill': true}),
        equals(3),
      );
    });

    test('circular_saw gives cap 4', () {
      expect(
        extractionCapForUnlocked({
          'saw_mill': true,
          'seed_drill': true,
          'circular_saw': true,
        }),
        equals(4),
      );
    });

    test('gathering with other techs still uses gathering level', () {
      expect(
        extractionCapForUnlocked({
          'saw_mill': true,
          'organised_regiments': true,
        }),
        equals(2),
      );
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
    test('empty unlocked returns all root techs (no tech prereqs; discovery techs included when callback null)', () {
      final r = researchableTechIds({});
      expect(r, isNotEmpty);
      for (final id in r) {
        final tech = techById(id);
        expect(tech, isNotNull);
        expect(tech!.prerequisiteIds, isEmpty);
      }
    });
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

    test('discovery tech with null callback is researchable when prereqs met', () {
      final r = researchableTechIds({});
      expect(r.contains('discovery_of_sugar'), isTrue, reason: 'Discovery techs are researchable when hasDiscoveredResource is null');
    });

    test('discovery tech with hasDiscoveredResource always false is not researchable', () {
      final r = researchableTechIds({}, hasDiscoveredResource: (_) => false);
      expect(r.contains('discovery_of_sugar'), isFalse);
    });

    test('discovery tech with hasDiscoveredResource true for sugarCane is researchable', () {
      final r = researchableTechIds({}, hasDiscoveredResource: (rid) => rid == 'sugarCane');
      expect(r.contains('discovery_of_sugar'), isTrue);
    });
  });
}
