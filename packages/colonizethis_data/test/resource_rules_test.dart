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
      expect(rules.isAllowedInRegion(Resource.grain, 'oldWorld'), isTrue);
      expect(rules.isAllowedInRegion(Resource.grain, 'newWorld'), isFalse);
      expect(rules.isAllowedInRegion(Resource.sugarCane, 'oldWorld'), isFalse);
      expect(rules.isAllowedInRegion(Resource.sugarCane, 'newWorld'), isTrue);
      expect(rules.isAllowedInRegion(Resource.timber, 'oldWorld'), isTrue);
      expect(rules.isAllowedInRegion(Resource.timber, 'newWorld'), isTrue);
    });

    test('isAllowedOnTerrain validates explicit terrain lists', () {
      final rules = ResourceRules.defaultRules;
      expect(rules.isAllowedOnTerrain(Resource.tin, TerrainType.swamp), isTrue);
      expect(
        rules.isAllowedOnTerrain(Resource.tin, TerrainType.forest),
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

    group('defaultMarketPriceForCommodityId (Refs #3093)', () {
      final rules = ResourceRules.defaultRules;

      test('returns the int default price for a raw-resource commodity', () {
        expect(rules.defaultMarketPriceForCommodityId('timber'), 30);
        expect(rules.defaultMarketPriceForCommodityId('iron'), 80);
        expect(rules.defaultMarketPriceForCommodityId('grain'), isNotNull);
        expect(rules.defaultMarketPriceForCommodityId('grain'), isA<int>());
      });

      test('returns null for an unknown commodity id', () {
        expect(rules.defaultMarketPriceForCommodityId('not_a_commodity'), isNull);
      });

      test('returns null for the empty string', () {
        expect(rules.defaultMarketPriceForCommodityId(''), isNull);
      });

      test(
          'returns null for manufactured commodities not enumerated in '
          'defaultMarketPrice (catalog fallback is deferred per SPEC follow-up)',
          () {
        // Manufactured commodity ids are intentionally absent from
        // ResourceRules.defaultMarketPrice today; SPEC/ui/trade-screen.md §
        // Market tab — read-only commodity table documents the em-dash
        // fallback for these rows until they discover a price in-game.
        expect(rules.defaultMarketPriceForCommodityId('lumber'), isNull);
        expect(rules.defaultMarketPriceForCommodityId('castIron'), isNull);
        expect(rules.defaultMarketPriceForCommodityId('fabric'), isNull);
      });
    });
  });
}
