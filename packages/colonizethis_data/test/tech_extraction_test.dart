import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('extractionCapForResourceForUnlocked', () {
    test('null tech returns default cap 1 for grain', () {
      expect(
        extractionCapForResourceForUnlocked(null, Resource.grain.name),
        equals(defaultExtractionCap),
      );
    });

    test('empty tech returns default cap 1 for grain', () {
      expect(
        extractionCapForResourceForUnlocked({}, Resource.grain.name),
        equals(defaultExtractionCap),
      );
    });

    test('only non-gathering techs keep default cap for grain', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdOrganisedRegiments: true,
        }, Resource.grain.name),
        equals(defaultExtractionCap),
      );
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdRoadConstruction: true,
          kTechIdEarlySteamEngine: true,
          kTechIdImprovedIronWeapons: true,
        }, Resource.grain.name),
        equals(defaultExtractionCap),
      );
    });

    test('land_enclosure gives grain cap 2', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdLandEnclosure: true,
        }, Resource.grain.name),
        equals(2),
      );
    });

    test('seed_drill gives grain cap 3', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdLandEnclosure: true,
          kTechIdSeedDrill: true,
        }, Resource.grain.name),
        equals(3),
      );
    });

    test('moldboard_plow gives grain cap 4', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdLandEnclosure: true,
          kTechIdSeedDrill: true,
          kTechIdMoldboardPlow: true,
        }, Resource.grain.name),
        equals(4),
      );
    });

    test('timber tech does not raise grain cap', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdSawMill: true,
          kTechIdOrganisedRegiments: true,
        }, Resource.grain.name),
        equals(1),
      );
    });

    test('wool design cap chain tops at 3', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdSheepRanching: true,
          kTechIdScientificSheepBreeding: true,
        }, Resource.wool.name),
        equals(3),
      );
    });

    test('horses uses explicit design exception cap 1', () {
      expect(
        extractionCapForResourceForUnlocked({}, Resource.horses.name),
        equals(1),
      );
    });
  });
}
