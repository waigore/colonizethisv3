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
          kTechIdOrganisedRegiments: true,
        }, 'grain'),
        equals(defaultExtractionCap),
      );
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdRoadConstruction: true,
          kTechIdEarlySteamEngine: true,
          kTechIdImprovedIronWeapons: true,
        }, 'grain'),
        equals(defaultExtractionCap),
      );
    });

    test('land_enclosure gives grain cap 2', () {
      expect(
        extractionCapForResourceForUnlocked({kTechIdLandEnclosure: true}, 'grain'),
        equals(2),
      );
    });

    test('seed_drill gives grain cap 3', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdLandEnclosure: true,
          kTechIdSeedDrill: true,
        }, 'grain'),
        equals(3),
      );
    });

    test('moldboard_plow gives grain cap 4', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdLandEnclosure: true,
          kTechIdSeedDrill: true,
          kTechIdMoldboardPlow: true,
        }, 'grain'),
        equals(4),
      );
    });

    test('timber tech does not raise grain cap', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdSawMill: true,
          kTechIdOrganisedRegiments: true,
        }, 'grain'),
        equals(1),
      );
    });

    test('wool design cap chain tops at 3', () {
      expect(
        extractionCapForResourceForUnlocked({
          kTechIdSheepRanching: true,
          kTechIdScientificSheepBreeding: true,
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
      expect(unlockingTechByShipId['fluyte'], kTechIdSuperiorHullDesign);
    });
    test('carrack has no unlocking tech (buildable from start)', () {
      expect(unlockingTechByShipId['carrack'], isNull);
    });
  });

  group('techDisplayName', () {
    test('uses catalog displayName when set', () {
      expect(techDisplayName(kTechIdRoadConstruction), 'Road Construction');
      expect(techDisplayName(kTechIdCropRotation), 'Crop Rotation');
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
      final r = researchableTechIds({kTechIdSawMill: true});
      expect(r.contains(kTechIdWindSawMill), isTrue);
      expect(r.contains(kTechIdSawMill), isFalse);
    });
    test('null unlocked same as empty', () {
      expect(researchableTechIds(null), researchableTechIds({}));
    });

    test(
      'discovery tech with null callback is researchable when prereqs met',
      () {
        final r = researchableTechIds({});
        expect(
          r.contains(kTechIdDiscoveryOfSugar),
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
        expect(r.contains(kTechIdDiscoveryOfSugar), isFalse);
      },
    );

    test(
      'discovery tech with hasDiscoveredResource true for sugarCane is researchable',
      () {
        final r = researchableTechIds(
          {},
          hasDiscoveredResource: (rid) => rid == 'sugarCane',
        );
        expect(r.contains(kTechIdDiscoveryOfSugar), isTrue);
      },
    );
  });

  group('envyMirrorTechCategoryForExtractionResource', () {
    test('returns gathering for extraction-cap resources', () {
      expect(envyMirrorTechCategoryForExtractionResource('grain'), 'gathering');
      expect(envyMirrorTechCategoryForExtractionResource('iron'), 'gathering');
    });

    test('returns null for unknown or empty resource id', () {
      expect(envyMirrorTechCategoryForExtractionResource(null), isNull);
      expect(envyMirrorTechCategoryForExtractionResource(''), isNull);
      expect(envyMirrorTechCategoryForExtractionResource('unknown'), isNull);
    });
  });
}
