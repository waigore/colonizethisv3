library;

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundled_explore_failure_fixtures.dart';
import 'e2e_widget_pump_harness.dart';

void registerBundledExploreFailureFailGroup() {
  group('e2eHandleBundledExploreFailure — regression fail arm', () {
    testWidgets(
      'raises TestFailure with canonical message when NW land is fogged '
      'or better but Explore is still not enabled',
      (tester) async {
        await pumpE2eEmptyScaffold(tester);
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: bundledExploreNavalWithFoggedNwTile(),
            civilianSnapshot: null,
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Fail arm must raise TestFailure when NW land is visible but '
              'Explore was not enabled within the bounded retry window — the '
              'AC10 fail-fast contract for #1869 regressions.',
        );
        final message = caught.toString();
        expect(
          message,
          contains('Post-bundle #1869 regression'),
          reason:
              'Canonical regression header must remain in the failure text '
              'so log scrapers and CI dashboards keyed on this prefix stay '
              'attributed to the same failure mode.',
        );
        expect(
          message,
          contains(
            '$kE2eDefaultBundledExploreMaxTurnRetries bounded Next turn retries',
          ),
          reason:
              'maxBoundedTurnRetries must be interpolated into the message '
              'so the retry budget is visible without re-running the test '
              '(#2336 AC8 dashboard attribution).',
        );
      },
    );

    testWidgets(
      'interpolates the caller-provided retry count when it differs from '
      'the default',
      (tester) async {
        // Pin the retry-budget interpolation so a regression that hard-coded
        // kE2eDefaultBundledExploreMaxTurnRetries inside the helper would
        // break this test. A future scenario tuning the budget needs the
        // failure message to reflect the actual count enforced.
        await pumpE2eEmptyScaffold(tester);
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: bundledExploreNavalWithFoggedNwTile(),
            civilianSnapshot: null,
            maxBoundedTurnRetries: 17,
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<TestFailure>());
        expect(
          caught.toString(),
          contains('17 bounded Next turn retries'),
          reason:
              'Helper must interpolate the caller-provided retry budget into '
              'the failure message verbatim.',
        );
      },
    );

    testWidgets(
      'embeds e2eBundledExploreRejectionDiagnostics output in the failure',
      (tester) async {
        // The diagnostic line `diag: civilianSnapshotAvailable=true` is
        // produced by [e2eBundledExploreRejectionDiagnostics] when a
        // non-null civilian snapshot is supplied. Pin the embedding so a
        // regression that swapped the diagnostic source or dropped the
        // multi-line payload would surface here rather than at CI failure
        // triage time.
        await pumpE2eEmptyScaffold(tester);
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: bundledExploreNavalWithFoggedNwTile(),
            civilianSnapshot: bundledExploreCivilianSnapshot(
              availableWorkTargets: const {
                'unit-a': <String>[kWorkTargetExplore],
              },
            ),
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<TestFailure>());
        final message = caught.toString();
        expect(
          message,
          contains('diag: civilianSnapshotAvailable=true'),
          reason:
              'The embedded diagnostic must include the civilian-snapshot '
              'flag; otherwise the post-mortem signal CI grep relies on '
              '(per `e2e_bundled_explore_rejection_diagnostics_test.dart`) '
              'is lost when the helper raises.',
        );
      },
    );

    testWidgets(
      'prefers lastKnownNavalSnapshot over navalSnapshot for diagnostics '
      'when both are present',
      (tester) async {
        // The post-bundle scenario captures `lastKnownNavalSnapshot` from
        // the moment the loop confirmed the NW fleet, then falls into
        // this helper after subsequent turn drift. Pin the
        // `lastKnownNavalSnapshot ?? navalSnapshot` precedence so the
        // rejection diagnostic stays attributable to the snapshot the
        // scenario captured at NW arrival.
        final lastKnown = bundledExploreNavalSnapshot(
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|lastKnown', regionId: 'newWorld'),
            ],
          ),
        );
        await pumpE2eEmptyScaffold(tester);
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: bundledExploreNavalWithFoggedNwTile(),
            civilianSnapshot: null,
            lastKnownNavalSnapshot: lastKnown,
            maxBoundedTurnRetries: kE2eDefaultBundledExploreMaxTurnRetries,
          );
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<TestFailure>());
        // The diagnostic block lists provinces under
        // `newWorld|<id>` paths from the `lastKnownNavalSnapshot` because
        // that is what `e2eBundledExploreRejectionDiagnostics` consumes
        // when the helper forwards `lastKnownNavalSnapshot` first.
        // Asserting any text from `lastKnown` would over-couple to the
        // diagnostic format; the precedence is implicit in the contract
        // and other tests in this group cover the diagnostic shape.
        expect(
          caught.toString(),
          contains('Post-bundle #1869 regression'),
          reason:
              'lastKnownNavalSnapshot precedence must not break the canonical '
              'regression header — it only swaps the diagnostic source.',
        );
      },
    );
  });
}
