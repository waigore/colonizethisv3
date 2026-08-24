import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('terrain extraction caps (R4 #3573)', () {
    test('scrub forest hard-caps timber at level 1', () {
      expect(
        terrainExtractionHardCap(Resource.timber.name, TerrainType.scrubForest),
        equals(1),
      );
    });

    test('hardwood forest imposes no timber hard cap', () {
      expect(
        terrainExtractionHardCap(
          Resource.timber.name,
          TerrainType.hardwoodForest,
        ),
        isNull,
      );
    });

    test('scrub forest hard cap applies only to timber, not furs', () {
      expect(
        terrainExtractionHardCap(Resource.furs.name, TerrainType.scrubForest),
        isNull,
      );
    });

    test('scrub timber capped at 1 even with circular_saw (tech cap 4)', () {
      final fullTech = {
        kTechIdSawMill: true,
        kTechIdWindSawMill: true,
        kTechIdCircularSaw: true,
      };
      expect(
        extractionCapForResourceForUnlocked(fullTech, Resource.timber.name),
        equals(4),
      );
      expect(
        extractionCapForResourceOnTerrain(
          fullTech,
          Resource.timber.name,
          TerrainType.scrubForest,
        ),
        equals(1),
      );
    });

    test('hardwood timber follows normal tech progression to 4', () {
      final fullTech = {
        kTechIdSawMill: true,
        kTechIdWindSawMill: true,
        kTechIdCircularSaw: true,
      };
      expect(
        extractionCapForResourceOnTerrain(
          fullTech,
          Resource.timber.name,
          TerrainType.hardwoodForest,
        ),
        equals(4),
      );
    });

    test('hardwood timber defaults to 1 with no gathering tech', () {
      expect(
        extractionCapForResourceOnTerrain(
          {},
          Resource.timber.name,
          TerrainType.hardwoodForest,
        ),
        equals(defaultExtractionCap),
      );
    });

    test('clampExtractionCapForTerrain clamps scrub timber down', () {
      expect(
        clampExtractionCapForTerrain(
          4,
          Resource.timber.name,
          TerrainType.scrubForest,
        ),
        equals(1),
      );
    });

    test(
      'clampExtractionCapForTerrain leaves non-capped terrain unchanged',
      () {
        expect(
          clampExtractionCapForTerrain(
            3,
            Resource.timber.name,
            TerrainType.hardwoodForest,
          ),
          equals(3),
        );
        expect(
          clampExtractionCapForTerrain(
            2,
            Resource.grain.name,
            TerrainType.plains,
          ),
          equals(2),
        );
      },
    );
  });
}
