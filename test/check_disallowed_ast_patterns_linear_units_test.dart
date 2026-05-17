import 'package:test/test.dart';

import '../tool/check_disallowed_ast_patterns.dart';
import 'disallowed_ast_patterns_test_yaml_fixture.dart';

void main() {
  late List<DisallowedPatternRule> rules;

  setUp(() {
    rules = loadDisallowedAstRulesForTest(disallowedAstPatternsTestYaml);
  });

  group('prohibited_linear_units_armies_fleets_lookup', () {
    test('flags region.units.where(...).firstOrNull under lib/src', () {
      const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? bad(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/world/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isNotEmpty,
      );
    });

    test('flags worldState.armies.where(...).firstOrNull', () {
      const src = r'''
class Army { final String id = ''; }
class WorldState { List<Army> get armies => const []; }
Army? bad(WorldState ws, String id) {
  return ws.armies.where((a) => a.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/orders/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isNotEmpty,
      );
    });

    test('flags fleets.where(...).firstOrNull', () {
      const src = r'''
class Fleet { final String id = ''; }
class WorldState { List<Fleet> get fleets => const []; }
Fleet? bad(WorldState ws, String id) {
  return ws.fleets.where((f) => f.id == id).firstOrNull;
}
''';
      final violations = findDisallowedAstViolations(
        'packages/colonizethis_logic/lib/src/naval/x.dart',
        src,
        rules,
      );
      expect(
        violations.where(
          (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
        ),
        isNotEmpty,
      );
    });

    test(
      'ignores .units.where(...).firstOrNull outside scoped path prefix',
      () {
        const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? still(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull;
}
''';
        expect(
          findDisallowedAstViolations(
            'app/lib/widgets/x.dart',
            src,
            rules,
          ).where(
            (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
          ),
          isEmpty,
        );
      },
    );

    test(
      'respects same-line ignore for prohibited_linear_units_armies_fleets_lookup',
      () {
        const src = r'''
class Unit { final String id = ''; }
class Region { List<Unit> get units => const []; }
Unit? f(Region region, String id) {
  return region.units.where((u) => u.id == id).firstOrNull; // ignore: disallowed_ast_prohibited_linear_units_armies_fleets_lookup
}
''';
        expect(
          findDisallowedAstViolations(
            'packages/colonizethis_logic/lib/src/x.dart',
            src,
            rules,
          ).where(
            (e) => e.ruleId == 'prohibited_linear_units_armies_fleets_lookup',
          ),
          isEmpty,
        );
      },
    );
  });
}
