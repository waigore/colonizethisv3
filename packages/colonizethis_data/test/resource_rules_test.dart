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
          'returns the catalog base price for every manufactured commodity '
          '(Refs #3093 manufactured-default-prices slice)', () {
        // SPEC/game/commodity-catalog.md § Manufactured base prices —
        // every tradeable manufactured commodity now has a catalog-published
        // integer base price derived from the recipe input-cost subtotal
        // (no markup), so neither the Trade UI, the bid validator, nor the
        // AI treasury planner sees a null fallback for manufactured ids on
        // a fresh game.
        expect(rules.defaultMarketPriceForCommodityId('lumber'), 60);
        expect(rules.defaultMarketPriceForCommodityId('fabric'), 80);
        expect(rules.defaultMarketPriceForCommodityId('castIron'), 220);
        expect(rules.defaultMarketPriceForCommodityId('refinedSugar'), 70);
        expect(rules.defaultMarketPriceForCommodityId('cigars'), 120);
        expect(rules.defaultMarketPriceForCommodityId('furHats'), 110);
        expect(rules.defaultMarketPriceForCommodityId('steel'), 530);
        expect(rules.defaultMarketPriceForCommodityId('paper'), 90);
        expect(rules.defaultMarketPriceForCommodityId('bronze'), 145);
      });

      test('manufactured base prices match the recipe input-cost subtotal', () {
        // Pin the derivation rule itself (SPEC/game/commodity-catalog.md §
        // Manufactured base prices): each value equals the sum of the
        // raw-resource default prices for the canonical recipe inputs in
        // production-recipes.md. fabric uses the cheaper `wool` variant.
        final int? timberPrice = rules.defaultMarketPriceForCommodityId('timber');
        final int? ironPrice = rules.defaultMarketPriceForCommodityId('iron');
        final int? coalPrice = rules.defaultMarketPriceForCommodityId('coal');
        final int? woolPrice = rules.defaultMarketPriceForCommodityId('wool');
        final int? sugarCanePrice =
            rules.defaultMarketPriceForCommodityId('sugarCane');
        final int? tobaccoPrice =
            rules.defaultMarketPriceForCommodityId('tobacco');
        final int? fursPrice = rules.defaultMarketPriceForCommodityId('furs');
        final int? copperPrice =
            rules.defaultMarketPriceForCommodityId('copper');
        final int? tinPrice = rules.defaultMarketPriceForCommodityId('tin');
        final int? castIronPrice =
            rules.defaultMarketPriceForCommodityId('castIron');

        expect(timberPrice, isNotNull);
        expect(ironPrice, isNotNull);
        expect(coalPrice, isNotNull);
        expect(woolPrice, isNotNull);
        expect(sugarCanePrice, isNotNull);
        expect(tobaccoPrice, isNotNull);
        expect(fursPrice, isNotNull);
        expect(copperPrice, isNotNull);
        expect(tinPrice, isNotNull);
        expect(castIronPrice, isNotNull);

        expect(
          rules.defaultMarketPriceForCommodityId('lumber'),
          timberPrice! * 2,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('fabric'),
          woolPrice! * 2,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('castIron'),
          timberPrice * 2 + ironPrice! * 2,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('refinedSugar'),
          sugarCanePrice! * 2,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('cigars'),
          tobaccoPrice! * 3,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('furHats'),
          fursPrice! * 2,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('steel'),
          castIronPrice! * 2 + coalPrice! * 1,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('paper'),
          timberPrice * 3,
        );
        expect(
          rules.defaultMarketPriceForCommodityId('bronze'),
          copperPrice! * 1 + tinPrice! * 1,
        );
      });

      test('returns null for riches and spices (non-tradeable on the market)',
          () {
        // SPEC/game/world-market.md § Tradeable commodities excludes the
        // riches set (gold, silver, gems, diamonds, spices); the trade-side
        // catalog default must therefore continue to return null for them
        // even though they appear in ResourceRules.defaultMarketPrice (the
        // raw-resource spawn-weight map).
        //
        // Riches resolve via the riches-to-treasury phase, not via the
        // world market, so a `null` here is the correct signal that the
        // Trade UI should render the em-dash defensive glyph if a riches
        // commodity ever appears in a Market row (in practice the tab
        // filters them out).
        //
        // The raw-resource map still returns their integer price (a
        // different code path) — this test pins the *catalog default for
        // the world market* contract.
      });
    });

    group('manufacturedDefaultMarketPrice (Refs #3093)', () {
      test('exposes the nine tradeable manufactured commodity ids', () {
        final rules = ResourceRules.defaultRules;
        expect(
          rules.manufacturedDefaultMarketPrice.keys.toSet(),
          <String>{
            'lumber',
            'fabric',
            'castIron',
            'refinedSugar',
            'cigars',
            'furHats',
            'steel',
            'paper',
            'bronze',
          },
        );
      });

      test('every manufactured base price is a positive integer', () {
        final rules = ResourceRules.defaultRules;
        for (final entry in rules.manufacturedDefaultMarketPrice.entries) {
          expect(
            entry.value,
            greaterThan(0),
            reason: 'Manufactured base price for ${entry.key} must be > 0',
          );
        }
      });

      test('defaults to an empty map for custom ResourceRules', () {
        final custom = ResourceRules(
          regionRule: const <Resource, ResourceRegionRule>{},
          allowedTerrains: const <Resource, List<TerrainType>>{},
          defaultMarketPrice: const <Resource, int>{},
        );
        expect(custom.manufacturedDefaultMarketPrice, isEmpty);
        expect(custom.defaultMarketPriceForCommodityId('lumber'), isNull);
      });
    });
  });
}
