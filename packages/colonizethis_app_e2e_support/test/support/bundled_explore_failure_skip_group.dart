library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundled_explore_failure_fixtures.dart';
import 'e2e_widget_pump_harness.dart';

void registerBundledExploreFailureSkipGroup() {
  group('e2eHandleBundledExploreFailure — topology skip arm', () {
    testWidgets('returns normally without raising when navalSnapshot has no NW '
        'fogged-or-better tiles', (tester) async {
      // Empty NW region → e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot
      // returns false → helper takes the skip arm. The surrounding
      // testWidgets body must continue without seeing a TestFailure so the
      // CI seed/topology bypass behaves as documented.
      await pumpE2eEmptyScaffold(tester);
      Object? caught;
      try {
        await e2eHandleBundledExploreFailure(
          tester,
          navalSnapshot: bundledExploreNavalSnapshot(),
          civilianSnapshot: null,
          maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNull,
        reason:
            'Skip arm must not raise — a TestFailure here would convert an '
            'environmental CI bypass into a flaky failure (#2336 AC10).',
      );
    });

    testWidgets(
      'returns normally without raising when navalSnapshot is null '
      '(missing snapshot routes through the skip arm per pre-lift contract)',
      (tester) async {
        // A null navalSnapshot historically read the global
        // `ctE2eNavalPanelSnapshot` and skipped via the same predicate;
        // the lifted contract preserves that behaviour by passing null
        // straight into [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot]
        // which reports false. Pin the contract so a future regression
        // that flipped the null-skip arm to a null-fail arm cannot land
        // silently.
        await pumpE2eEmptyScaffold(tester);
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: null,
            civilianSnapshot: null,
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isNull,
          reason:
              'Null navalSnapshot must follow the same skip arm as a snapshot '
              'with no fogged-or-better NW tiles; otherwise post-failure '
              'environments where the global was never plumbed would fail '
              'rather than skip.',
        );
      },
    );
  });
}
