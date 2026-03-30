// Integration tests for productionDesiredOutputProvider + mapping helpers.
// SPEC/ui/production-panel.md.

import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededProductionDesiredOutputNotifier
    extends ProductionDesiredOutputNotifier {
  _SeededProductionDesiredOutputNotifier(this._initial);

  final Map<String, int> _initial;

  @override
  Map<String, int> build() => _initial;
}

void main() {
  suppressLogsForTests();

  group('production desired output provider integration', () {
    test('preseeded provider state is reflected', () {
      final container = ProviderContainer(
        overrides: [
          productionDesiredOutputProvider.overrideWith(
            () => _SeededProductionDesiredOutputNotifier(const {
              'lumber_from_timber': 5,
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(productionDesiredOutputProvider);
      expect(state, const {'lumber_from_timber': 5});
      expect(desiredOutputToAssignments(state), isNotEmpty);
    });

    test('updating provider rebuilds derived assignment list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(productionDesiredOutputProvider), isEmpty);
      expect(
        desiredOutputToAssignments(
          container.read(productionDesiredOutputProvider),
        ),
        isEmpty,
      );

      container.read(productionDesiredOutputProvider.notifier).replaceAll(
        const {'lumber_from_timber': 2},
      );

      final next = container.read(productionDesiredOutputProvider);
      final assignments = desiredOutputToAssignments(next);
      expect(next['lumber_from_timber'], 2);
      expect(assignments, hasLength(1));
      expect(assignments.first.recipeId, 'lumber_from_timber');
      expect(assignments.first.assignedLabour, 4);
    });
  });
}
