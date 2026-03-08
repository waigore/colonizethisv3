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

    test('gathering_1 gives cap 2', () {
      expect(
        extractionCapForUnlocked({'gathering_1': true}),
        equals(2),
      );
    });

    test('gathering_2 gives cap 3', () {
      expect(
        extractionCapForUnlocked({'gathering_1': true, 'gathering_2': true}),
        equals(3),
      );
    });

    test('gathering_3 gives cap 4', () {
      expect(
        extractionCapForUnlocked({
          'gathering_1': true,
          'gathering_2': true,
          'gathering_3': true,
        }),
        equals(4),
      );
    });

    test('gathering with other techs still uses gathering level', () {
      expect(
        extractionCapForUnlocked({
          'gathering_1': true,
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
}
