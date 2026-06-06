import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('CommodityCatalog', () {
    test('all ids are unique', () {
      final ids = CommodityCatalog.all.map((c) => c.id).toList();
      final unique = ids.toSet();
      expect(unique.length, ids.length);
    });

    test('byId covers all commodities', () {
      for (final c in CommodityCatalog.all) {
        expect(CommodityCatalog.byId[c.id], isNotNull);
      }
    });
  });

  group('riches base prices', () {
    test('spices base price is 50 (Imperialism II)', () {
      expect(richesBasePrice('spices'), 50);
    });

    test('riches base prices increase with scarcity (diamonds > gems > gold > silver > spices)', () {
      expect(richesBasePrice('diamonds'), greaterThan(richesBasePrice('gems')));
      expect(richesBasePrice('gems'), greaterThan(richesBasePrice('gold')));
      expect(richesBasePrice('gold'), greaterThan(richesBasePrice('silver')));
      expect(richesBasePrice('silver'), greaterThan(richesBasePrice('spices')));
      expect(richesBasePrice('spices'), 50);
    });

    test('non-riches commodity returns 0', () {
      expect(richesBasePrice('grain'), 0);
    });

    test('richesCommodityIds contains all five riches', () {
      expect(richesCommodityIds, hasLength(5));
      expect(richesCommodityIds, contains('spices'));
      expect(richesCommodityIds, contains('gold'));
      expect(richesCommodityIds, contains('silver'));
      expect(richesCommodityIds, contains('gems'));
      expect(richesCommodityIds, contains('diamonds'));
    });
  });

  group('landPurchaseBasePrice', () {
    test('riches use richesBasePrice (spices 50)', () {
      expect(landPurchaseBasePrice('spices'), 50);
    });
    test('non-riches use landPurchaseDefaultBasePrice (10)', () {
      expect(landPurchaseBasePrice('grain'), landPurchaseDefaultBasePrice);
      expect(landPurchaseBasePrice('grain'), 10);
    });
    test('landPurchaseDefaultBasePrice is 10 (SPEC civilian-units)', () {
      expect(landPurchaseDefaultBasePrice, 10);
    });
  });

  group('ResourceRules defaultRules', () {
    test('diamonds allowed on desert (SPEC resource-terrain-region-rules)', () {
      final rules = ResourceRules.defaultRules;
      expect(rules.isAllowedOnTerrain(Resource.diamonds, TerrainType.desert), isTrue);
      expect(rules.isAllowedOnTerrain(Resource.diamonds, TerrainType.swamp), isFalse);
    });
  });

  group('ProductionRecipesCatalog', () {
    test('all recipe ids are unique', () {
      final ids = ProductionRecipesCatalog.all.map((r) => r.id).toList();
      final unique = ids.toSet();
      expect(unique.length, ids.length);
    });

    test('all recipes reference valid commodity ids', () {
      final validIds = CommodityCatalog.byId.keys.toSet();
      for (final recipe in ProductionRecipesCatalog.all) {
        expect(validIds.contains(recipe.outputCommodityId), isTrue,
            reason: 'Output commodity ${recipe.outputCommodityId} must exist');
        for (final id in recipe.inputQuantities.keys) {
          expect(validIds.contains(id), isTrue,
              reason: 'Input commodity $id must exist');
        }
      }
    });

    test('recipe structure is consistent with spec', () {
      final castIron = ProductionRecipesCatalog.castIronFromTimberIronCoal;
      expect(castIron.labourPerOutput > 0, isTrue);
      expect(
        castIron.inputQuantities[CommodityCatalog.timber.id],
        2,
      );
      expect(
        castIron.inputQuantities[CommodityCatalog.iron.id],
        2,
      );
      expect(
        castIron.inputQuantities.containsKey(CommodityCatalog.coal.id),
        isFalse,
      );
    });

    group('byOutputCommodityId index (Refs #3288)', () {
      test('producing(c) matches a full scan of all by outputCommodityId', () {
        final outputs = ProductionRecipesCatalog.all
            .map((r) => r.outputCommodityId)
            .toSet();
        for (final commodityId in outputs) {
          final expected = ProductionRecipesCatalog.all
              .where((r) => r.outputCommodityId == commodityId)
              .toList();
          expect(
            ProductionRecipesCatalog.producing(commodityId),
            equals(expected),
            reason: 'producing($commodityId) must equal the filtered all-scan',
          );
        }
      });

      test('producing preserves all-list order within a commodity bucket', () {
        // fabric is produced by two recipes; order must follow `all`.
        expect(
          ProductionRecipesCatalog.producing(CommodityCatalog.fabric.id),
          equals(<ProductionRecipe>[
            ProductionRecipesCatalog.fabricFromWool,
            ProductionRecipesCatalog.fabricFromCotton,
          ]),
        );
      });

      test('producing returns empty list for an unproduced commodity', () {
        expect(
          ProductionRecipesCatalog.producing(CommodityCatalog.grain.id),
          isEmpty,
        );
        expect(
          ProductionRecipesCatalog.producing('not_a_real_commodity'),
          isEmpty,
        );
      });

      test('byOutputCommodityId covers every recipe exactly once', () {
        final indexed = ProductionRecipesCatalog.byOutputCommodityId.values
            .expand((recipes) => recipes)
            .toList();
        expect(indexed.length, ProductionRecipesCatalog.all.length);
        expect(indexed.toSet(), ProductionRecipesCatalog.all.toSet());
      });
    });
  });
}

