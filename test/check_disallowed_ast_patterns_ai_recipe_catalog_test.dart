import 'package:test/test.dart';

import '../tool/check_disallowed_ast_patterns.dart';
import 'disallowed_ast_patterns_test_yaml_fixture.dart';

void main() {
  late List<DisallowedPatternRule> rules;

  setUp(() {
    rules = loadDisallowedAstRulesForTest(disallowedAstPatternsTestYaml);
  });

  Iterable<DisallowedAstViolation> recipeScanViolations(
    String path,
    String src,
  ) =>
      findDisallowedAstViolations(path, src, rules)
          .where((e) => e.ruleId == 'ai_full_recipe_catalog_scan');

  group('ai_full_recipe_catalog_scan', () {
    test('flags ProductionRecipesCatalog.all under colonizethis_ai/lib', () {
      const src = r'''
List<Object> bad() {
  final recipes = ProductionRecipesCatalog.all;
  return recipes;
}
''';
      expect(
        recipeScanViolations(
          'packages/colonizethis_ai/lib/src/planning/economy_planner.dart',
          src,
        ),
        isNotEmpty,
      );
    });

    test('flags ProductionRecipesCatalog.all inside a spread literal', () {
      const src = r'''
List<Object> bad() {
  final sorted = [...ProductionRecipesCatalog.all];
  return sorted;
}
''';
      expect(
        recipeScanViolations(
          'packages/colonizethis_ai/lib/src/planning/treasury_planner.dart',
          src,
        ),
        isNotEmpty,
      );
    });

    test('ignores producing()/byId index lookups', () {
      const src = r'''
Object? ok(String commodityId, String recipeId) {
  for (final recipe in ProductionRecipesCatalog.producing(commodityId)) {
    return recipe;
  }
  return ProductionRecipesCatalog.byId[recipeId];
}
''';
      expect(
        recipeScanViolations(
          'packages/colonizethis_ai/lib/src/planning/economy_planner.dart',
          src,
        ),
        isEmpty,
      );
    });

    test('ignores ProductionRecipesCatalog.all outside colonizethis_ai/lib',
        () {
      const src = r'''
List<Object> still() {
  final recipes = ProductionRecipesCatalog.all;
  return recipes;
}
''';
      expect(
        recipeScanViolations(
          'packages/colonizethis_data/lib/src/catalog.dart',
          src,
        ),
        isEmpty,
      );
    });

    test('respects same-line ignore for ai_full_recipe_catalog_scan', () {
      const src = r'''
List<Object> suppressed() {
  // ignore: disallowed_ast_ai_full_recipe_catalog_scan
  final recipes = ProductionRecipesCatalog.all;
  return recipes;
}
''';
      expect(
        recipeScanViolations(
          'packages/colonizethis_ai/lib/src/planning/economy_planner.dart',
          src,
        ),
        isEmpty,
      );
    });
  });
}
