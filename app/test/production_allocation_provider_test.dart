// Unit tests for production allocation provider. SPEC/ui/production-panel.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/providers/production_allocation_provider.dart';

void main() {
  suppressLogsForTests();

  group('desiredOutputToAssignments', () {
    test('empty map returns empty list', () {
      expect(desiredOutputToAssignments({}), isEmpty);
    });

    test('zero desired output omitted', () {
      final result = desiredOutputToAssignments({
        'lumber_from_timber': 0,
      });
      expect(result, isEmpty);
    });

    test('single recipe yields one AssignedRecipe with correct labour', () {
      final result = desiredOutputToAssignments({
        'lumber_from_timber': 3,
      });
      expect(result.length, 1);
      expect(result.first.recipeId, 'lumber_from_timber');
      expect(result.first.assignedLabour, 6); // 3 * 2 labourPerOutput
    });

    test('multiple recipes yield multiple assignments', () {
      final result = desiredOutputToAssignments({
        'lumber_from_timber': 2,
        'refinedSugar_from_sugarCane': 1,
      });
      expect(result.length, 2);
      final byId = {for (final a in result) a.recipeId: a};
      expect(byId['lumber_from_timber']!.assignedLabour, 4);
      expect(byId['refinedSugar_from_sugarCane']!.assignedLabour, 2);
    });

    test('unknown recipe id skipped', () {
      final result = desiredOutputToAssignments({
        'unknown_recipe': 5,
        'lumber_from_timber': 1,
      });
      expect(result.length, 1);
      expect(result.first.recipeId, 'lumber_from_timber');
    });
  });
}
