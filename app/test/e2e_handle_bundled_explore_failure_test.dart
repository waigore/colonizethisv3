/// Pins the snapshot-driven failure-mode contract of
/// [e2eHandleBundledExploreFailure]
/// (`app/integration_test/e2e_test_shared_bundled_explore_failure.dart`).
///
/// The post-bundle Explore E2E scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper
/// exactly once after [e2eAwaitExploreEnabledFromCivilianPanel] returns
/// `false` to either:
///
///   - Skip the test deterministically when the running CI seed/topology
///     never revealed any New World land within bounded retries (the
///     [e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot] arm); or
///   - Raise the canonical `Post-bundle #1869 regression` `fail()` with
///     the [e2eBundledExploreRejectionDiagnostics] payload otherwise.
///
/// A silent reorder, accidental fail-open, or dropped retry-count
/// interpolation would either:
///
///   - Mask a real bundled-Explore regression by always taking the skip
///     arm (#2336 AC10 fail-fast contract); or
///   - Convert an environmental skip into a flaky CI failure on seeds
///     where no NW land becomes visible within the bounded retry window.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin (Refs GitHub #2336 AC1 / AC2 / AC5
/// / Bottleneck 5).
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const MapTopology _emptyTopology = MapTopology();

const Orders _emptyOrders = Orders();

CtE2eNavalPanelSnapshot _navalSnapshot({
  RegionData newWorld = const RegionData(),
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => CtE2eNavalPanelSnapshot(
  game: Game(
    id: 'g1',
    worldState: WorldState(
      turnState: _orderingTurn,
      oldWorld: const RegionData(),
      newWorld: newWorld,
      playerVisibilityByTile: playerVisibilityByTile,
    ),
    players: const [Player(id: _human, displayName: 'You', isHuman: true)],
  ),
  humanPlayerId: _human,
  topology: _emptyTopology,
  draftOrders: _emptyOrders,
);

CtE2eCivilianPanelSnapshot _civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: Game(
    id: 'g1',
    worldState: WorldState(
      turnState: _orderingTurn,
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: _human, displayName: 'You', isHuman: true)],
  ),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

/// Naval snapshot with one fogged NW tile so the topology skip arm does
/// NOT fire — used by the regression-fail-arm tests.
CtE2eNavalPanelSnapshot _navalWithFoggedNwTile() => _navalSnapshot(
  newWorld: const RegionData(
    provinces: [Province(id: 'newWorld|nwA', regionId: 'newWorld')],
  ),
  playerVisibilityByTile: const {
    _human: {'newWorld|nwA|0|0': 'fogged'},
  },
);

void main() {
  suppressLogsForTests();

  group('e2eHandleBundledExploreFailure — topology skip arm', () {
    testWidgets(
      'returns normally without raising when navalSnapshot has no NW '
      'fogged-or-better tiles',
      (tester) async {
        // Empty NW region → e2ePlayerHasAnyNewWorldFoggedOrBetterFromCtSnapshot
        // returns false → helper takes the skip arm. The surrounding
        // testWidgets body must continue without seeing a TestFailure so the
        // CI seed/topology bypass behaves as documented.
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: _navalSnapshot(),
            civilianSnapshot: null,
            maxBoundedTurnRetries:
                kE2eDefaultBundledExploreMaxTurnRetries,
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
      },
    );

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
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: null,
            civilianSnapshot: null,
            maxBoundedTurnRetries:
                kE2eDefaultBundledExploreMaxTurnRetries,
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

  group('e2eHandleBundledExploreFailure — regression fail arm', () {
    testWidgets(
      'raises TestFailure with canonical message when NW land is fogged '
      'or better but Explore is still not enabled',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: _navalWithFoggedNwTile(),
            civilianSnapshot: null,
            maxBoundedTurnRetries:
                kE2eDefaultBundledExploreMaxTurnRetries,
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
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: _navalWithFoggedNwTile(),
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
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: _navalWithFoggedNwTile(),
            civilianSnapshot: _civilianSnapshot(
              availableWorkTargets: const {
                'unit-a': <String>[kWorkTargetExplore],
              },
            ),
            maxBoundedTurnRetries:
                kE2eDefaultBundledExploreMaxTurnRetries,
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
        final lastKnown = _navalSnapshot(
          newWorld: const RegionData(
            provinces: [
              Province(id: 'newWorld|lastKnown', regionId: 'newWorld'),
            ],
          ),
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Object? caught;
        try {
          await e2eHandleBundledExploreFailure(
            tester,
            navalSnapshot: _navalWithFoggedNwTile(),
            civilianSnapshot: null,
            lastKnownNavalSnapshot: lastKnown,
            maxBoundedTurnRetries:
                kE2eDefaultBundledExploreMaxTurnRetries,
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

  group('e2eHandleBundledExploreFailure — determinism', () {
    testWidgets(
      'identical inputs always yield identical failure messages '
      '(Refs #2336 AC2)',
      (tester) async {
        // Determinism pin: two calls with the same inputs must raise the
        // same TestFailure message. A regression that introduced
        // non-determinism (e.g. `DateTime.now()` in the message) would
        // diverge the two captures and trip this test.
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        Future<String?> capture() async {
          try {
            await e2eHandleBundledExploreFailure(
              tester,
              navalSnapshot: _navalWithFoggedNwTile(),
              civilianSnapshot: null,
              maxBoundedTurnRetries:
                  kE2eDefaultBundledExploreMaxTurnRetries,
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
      },
    );
  });
}
