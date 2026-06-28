import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

/// Slice C — cotton weaving recipe gate (Refs #3470).
/// SPEC/game/production-recipes.md § Technology-gated recipes.
void main() {
  group('ProductionRecipe.requiredTechId', () {
    test('fabric_from_cotton requires cotton_weaving', () {
      expect(
        ProductionRecipesCatalog.fabricFromCotton.requiredTechId,
        kTechIdCottonWeaving,
      );
    });

    test('fabric_from_wool has no required tech', () {
      expect(ProductionRecipesCatalog.fabricFromWool.requiredTechId, isNull);
    });

    test('non-gated recipes declare no required tech', () {
      final gated = ProductionRecipesCatalog.all
          .where((r) => r.requiredTechId != null)
          .map((r) => r.id)
          .toSet();
      expect(gated, {'fabric_from_cotton'});
    });
  });

  group('isRecipeAvailableForPlayer', () {
    test('non-gated recipe is available regardless of techUnlocked', () {
      expect(
        ProductionRecipesCatalog.isRecipeAvailableForPlayer(
          ProductionRecipesCatalog.fabricFromWool,
          null,
        ),
        isTrue,
      );
      expect(
        ProductionRecipesCatalog.isRecipeAvailableForPlayer(
          ProductionRecipesCatalog.fabricFromWool,
          const {},
        ),
        isTrue,
      );
    });

    test('gated recipe unavailable when tech missing, null, or false', () {
      // Null techUnlocked.
      expect(
        ProductionRecipesCatalog.isRecipeAvailableForPlayer(
          ProductionRecipesCatalog.fabricFromCotton,
          null,
        ),
        isFalse,
      );
      // Empty / missing entry.
      expect(
        ProductionRecipesCatalog.isRecipeAvailableForPlayer(
          ProductionRecipesCatalog.fabricFromCotton,
          const {},
        ),
        isFalse,
      );
      // Explicit false.
      expect(
        ProductionRecipesCatalog.isRecipeAvailableForPlayer(
          ProductionRecipesCatalog.fabricFromCotton,
          const {kTechIdCottonWeaving: false},
        ),
        isFalse,
      );
    });

    test('gated recipe available when tech unlocked', () {
      expect(
        ProductionRecipesCatalog.isRecipeAvailableForPlayer(
          ProductionRecipesCatalog.fabricFromCotton,
          const {kTechIdCottonWeaving: true},
        ),
        isTrue,
      );
    });
  });

  group('availableForPlayer', () {
    test('excludes fabric_from_cotton without cotton_weaving but keeps wool',
        () {
      final available = ProductionRecipesCatalog.availableForPlayer(const {});
      final ids = available.map((r) => r.id).toSet();
      expect(ids, contains('fabric_from_wool'));
      expect(ids, isNot(contains('fabric_from_cotton')));
      // All other always-available recipes remain present.
      expect(available.length, ProductionRecipesCatalog.all.length - 1);
    });

    test('includes fabric_from_cotton once cotton_weaving is unlocked', () {
      final available = ProductionRecipesCatalog.availableForPlayer(
        const {kTechIdCottonWeaving: true},
      );
      final ids = available.map((r) => r.id).toSet();
      expect(ids, contains('fabric_from_cotton'));
      expect(ids, contains('fabric_from_wool'));
      expect(available.length, ProductionRecipesCatalog.all.length);
    });

    test('preserves catalog order', () {
      final available = ProductionRecipesCatalog.availableForPlayer(
        const {kTechIdCottonWeaving: true},
      );
      expect(
        available.map((r) => r.id).toList(),
        ProductionRecipesCatalog.all.map((r) => r.id).toList(),
      );
    });
  });
}
