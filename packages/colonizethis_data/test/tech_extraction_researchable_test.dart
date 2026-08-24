import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
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
          hasDiscoveredResource: (rid) => rid == Resource.sugarCane.name,
        );
        expect(r.contains(kTechIdDiscoveryOfSugar), isTrue);
      },
    );
  });

  group('envyMirrorTechCategoryForExtractionResource', () {
    test('returns gathering for extraction-cap resources', () {
      expect(
        envyMirrorTechCategoryForExtractionResource(Resource.grain.name),
        'gathering',
      );
      expect(
        envyMirrorTechCategoryForExtractionResource(Resource.iron.name),
        'gathering',
      );
    });

    test('returns null for unknown or empty resource id', () {
      expect(envyMirrorTechCategoryForExtractionResource(null), isNull);
      expect(envyMirrorTechCategoryForExtractionResource(''), isNull);
      expect(envyMirrorTechCategoryForExtractionResource('unknown'), isNull);
    });
  });
}
