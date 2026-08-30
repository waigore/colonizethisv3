library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:flutter_test/flutter_test.dart';

import 'ensure_non_home_fleet_nw_fixtures.dart';

void registerEnsureNonHomeFleetSanityGroup() {
  group('e2eEnsureNonHomeFleetInNwAfterLoop — fixture sanity', () {
    test(
      'ensureNonHomeReachedSnapshot reports reach via e2eFleetReachDoneFromCtSnapshotOnly',
      () {
        expect(
          shared.e2eFleetReachDoneFromCtSnapshotOnly(
            ensureNonHomeReachedSnapshot(),
          ),
          isTrue,
          reason:
              'Pin must depend on the same predicate the helper uses so '
              'the "snapshot reach short-circuit" assertion is genuinely '
              'exercising the lifted contract — drift here would silently '
              'turn the happy-path test into a no-op.',
        );
      },
    );

    test('ensureNonHomeHomeOnlySnapshot reports NO reach via '
        'e2eFleetReachDoneFromCtSnapshotOnly', () {
      expect(
        shared.e2eFleetReachDoneFromCtSnapshotOnly(
          ensureNonHomeHomeOnlySnapshot(),
        ),
        isFalse,
        reason:
            'Pin must depend on the same predicate the helper uses so '
            'the "failure branch" assertion really sends the helper '
            'down the openNavalPanel → harness-probe-fails path — '
            'drift here would short-circuit the failure path and '
            'leave the scenario-specific message untested.',
      );
    });
  });
}
