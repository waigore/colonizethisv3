import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resource rules', () {
    test('default rules cover every resource for every map', () {
      final rules = ResourceRules.defaultRules;
      for (final resource in Resource.values) {
        expect(rules.regionRule.containsKey(resource), isTrue);
        expect(rules.allowedTerrains.containsKey(resource), isTrue);
        expect(rules.defaultMarketPrice.containsKey(resource), isTrue);
        expect(rules.allowedTerrains[resource], isNotEmpty);
        expect(rules.defaultMarketPrice[resource]! > 0, isTrue);
      }
    });

    test('spawn weights are inverse to market price', () {
      final rules = ResourceRules.defaultRules;
      expect(rules.spawnWeight(Resource.timber), closeTo(1 / 30, 1e-9));
      expect(rules.spawnWeight(Resource.diamonds), closeTo(1 / 500, 1e-9));
      expect(
        rules.spawnWeight(Resource.timber) >
            rules.spawnWeight(Resource.diamonds),
        isTrue,
      );
    });

    test('isAllowedInRegion enforces old world, new world, and both rules', () {
      final rules = ResourceRules.defaultRules;
      expect(
        rules.isAllowedInRegion(Resource.grain, kOldWorldRegionId),
        isTrue,
      );
      expect(
        rules.isAllowedInRegion(Resource.grain, kNewWorldRegionId),
        isFalse,
      );
      expect(
        rules.isAllowedInRegion(Resource.sugarCane, kOldWorldRegionId),
        isFalse,
      );
      expect(
        rules.isAllowedInRegion(Resource.sugarCane, kNewWorldRegionId),
        isTrue,
      );
      expect(
        rules.isAllowedInRegion(Resource.timber, kOldWorldRegionId),
        isTrue,
      );
      expect(
        rules.isAllowedInRegion(Resource.timber, kNewWorldRegionId),
        isTrue,
      );
    });

    test('isAllowedOnTerrain validates explicit terrain lists', () {
      final rules = ResourceRules.defaultRules;
      expect(rules.isAllowedOnTerrain(Resource.tin, TerrainType.swamp), isTrue);
      expect(
        rules.isAllowedOnTerrain(Resource.tin, TerrainType.hardwoodForest),
        isFalse,
      );
      expect(
        rules.isAllowedOnTerrain(Resource.gold, TerrainType.mountain),
        isTrue,
      );
      expect(
        rules.isAllowedOnTerrain(Resource.gold, TerrainType.hills),
        isFalse,
      );
    });

    test('timber spawns on both hardwood and scrub forest (#3573 R2)', () {
      final rules = ResourceRules.defaultRules;
      expect(
        rules.isAllowedOnTerrain(Resource.timber, TerrainType.hardwoodForest),
        isTrue,
      );
      expect(
        rules.isAllowedOnTerrain(Resource.timber, TerrainType.scrubForest),
        isTrue,
      );
      // Negative: timber is still forest-only (not on plains).
      expect(
        rules.isAllowedOnTerrain(Resource.timber, TerrainType.plains),
        isFalse,
      );
    });

    test('furs spawns on hardwood forest only, never scrub (#3573 R2)', () {
      final rules = ResourceRules.defaultRules;
      expect(
        rules.isAllowedOnTerrain(Resource.furs, TerrainType.hardwoodForest),
        isTrue,
      );
      // Negative: furs never appears on scrub forest.
      expect(
        rules.isAllowedOnTerrain(Resource.furs, TerrainType.scrubForest),
        isFalse,
      );
    });
  });
}
