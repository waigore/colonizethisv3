import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('unlockingTechByShipId', () {
    test('fluyte requires superior_hull_design', () {
      expect(unlockingTechByShipId['fluyte'], kTechIdSuperiorHullDesign);
    });
    test('carrack has no unlocking tech (buildable from start)', () {
      expect(unlockingTechByShipId['carrack'], isNull);
    });
  });

  group('unlock maps cached (Refs #4412 AC2)', () {
    test(
      'unlockingTechByRegimentId returns the same instance on consecutive reads',
      () {
        expect(
          identical(unlockingTechByRegimentId, unlockingTechByRegimentId),
          isTrue,
        );
      },
    );

    test(
      'unlockingTechByShipId returns the same instance on consecutive reads',
      () {
        expect(identical(unlockingTechByShipId, unlockingTechByShipId), isTrue);
      },
    );

    test('cached maps still match catalog-derived unlock ids', () {
      expect(unlockingTechByShipId['fluyte'], kTechIdSuperiorHullDesign);
      expect(unlockingTechByShipId.containsKey('carrack'), isFalse);
      expect(unlockingTechByRegimentId, isNotEmpty);
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
}
