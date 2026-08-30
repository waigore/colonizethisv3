library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundled_explore_failure_fixtures.dart';
import 'e2e_widget_pump_harness.dart';

void registerBundledExploreFailureDeterminismGroup() {
  group('e2eHandleBundledExploreFailure — determinism', () {
    testWidgets('identical inputs always yield identical failure messages '
        '(Refs #2336 AC2)', (tester) async {
      // Determinism pin: two calls with the same inputs must raise the
      // same TestFailure message. A regression that introduced
      // non-determinism (e.g. `DateTime.now()` in the message) would
      // diverge the two captures and trip this test.
      await pumpE2eEmptyScaffold(tester);
      Future<String?> capture() async {
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: bundledExploreNavalWithFoggedNwTile(),
            civilianSnapshot: null,
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          return e.toString();
        }
        return null;
      }

      final first = await capture();
      final second = await capture();
      expect(first, isNotNull);
      expect(second, first);
    });
  });
}
