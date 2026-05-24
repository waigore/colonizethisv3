/// Pins the widget-tree contract of [e2eEnsureNonHomeFleetInNwAfterLoop]
/// (`app/integration_test/e2e_test_shared_final_naval_reach_check.dart`).
///
/// Both `testWidgets` bodies in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` call this helper via
/// the AC1 barrel alias `ensureNonHomeFleetInNwAfterLoop` to bookend the
/// fleet-reach turn loop with a deterministic reach assertion (Bottleneck
/// 4 in `SPEC/program/e2e-integration-tests.md` § Determinism). A silent
/// rename or behavioural drift here would either:
///
///   - Skip the conditional `openNavalPanel` and mask a real reach
///     regression as a clean pass — the harness probe would then read
///     against a stale region/sheet state.
///   - Bypass the `failureMessageBuilder` and orphan the legacy
///     "Last exception: ${tester.takeException()}" suffix on CI failures,
///     degrading triage for the scenario-specific fail message.
///   - Swap the order of `dismissTransientUi` /
///     `e2eTapNewWorldRegionTabIfPresent` and read the harness against
///     the wrong region tab — surfacing as flaky precheck behaviour.
///   - Drop the post-`openNavalPanel` snapshot capture and break test
///     2's bundled-Explore rejection diagnostics composition (the
///     diagnostic surface falls back to the live global, which a later
///     `e2eAdvanceOneHumanTurn` may null out).
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 4.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart' as shared;

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData _emptyRegion = RegionData();
const Orders _emptyOrders = Orders();
const MapTopology _emptyTopology = MapTopology();

Fleet _homeFleet() => Fleet(
  id: 'fleet_$_human',
  ownerId: _human,
  regionId: 'oldWorld',
  inPortAtProvinceId: 'oldWorld|capital',
);

Fleet _splitFleetInNw({String id = 'fleet_split'}) =>
    Fleet(id: id, ownerId: _human, regionId: 'newWorld', seaZoneId: 'nwSea');

Game _gameWithFleets(List<Fleet> fleets) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: _emptyRegion,
    newWorld: _emptyRegion,
    fleets: fleets,
  ),
  players: const [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot _snapshot({required List<Fleet> fleets}) =>
    CtE2eNavalPanelSnapshot(
      game: _gameWithFleets(fleets),
      humanPlayerId: _human,
      topology: _emptyTopology,
      draftOrders: _emptyOrders,
    );

CtE2eNavalPanelSnapshot _reachedSnapshot() =>
    _snapshot(fleets: [_homeFleet(), _splitFleetInNw()]);

CtE2eNavalPanelSnapshot _homeOnlySnapshot() =>
    _snapshot(fleets: [_homeFleet()]);

/// Pumps an effectively empty material app — no naval panel, no region
/// tab, no rail buttons. Exercises the snapshot-only short-circuit
/// branch where `e2eOpenNavalPanel` is skipped.
Future<void> _pumpEmpty(WidgetTester tester) =>
    tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

/// Pumps a tree with the naval panel root key already mounted so the
/// helper's conditional `e2eOpenNavalPanel` call short-circuits via the
/// hit-testable panel check without needing an empire-rail button.
///
/// Uses a [Container] with an explicit color so the underlying
/// `RenderConstrainedBox` responds to hit-testing — a bare [SizedBox]
/// is not hit-testable and the helper would time out trying to find
/// an empire-rail / first-fleet-marker opener instead.
Future<void> _pumpWithNavalPanelMounted(WidgetTester tester) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Container(
            key: kCtE2ENavalPanelRootKey,
            color: const Color(0xFF000000),
            width: 200,
            height: 200,
          ),
        ),
      ),
    );

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eNavalPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  group('e2eEnsureNonHomeFleetInNwAfterLoop — default constants', () {
    test('kE2eDefaultFinalNavalReachCheckUiWait matches legacy 5 s budget', () {
      expect(
        kE2eDefaultFinalNavalReachCheckUiWait,
        const Duration(seconds: 5),
        reason:
            'A silent budget bump here would either inflate the per-call '
            'wall clock for the post-loop `openNavalPanel` / '
            '`closeBottomSheet` calls or short-circuit them before the '
            'snapshot plumbing settles. Require an explicit override at '
            'the call site instead. Refs GitHub #2336 AC1 / AC2 / '
            'Bottleneck 4.',
      );
    });
  });

  group('e2eEnsureNonHomeFleetInNwAfterLoop — snapshot reach short-circuit',
      () {
    testWidgets(
      'returns successfully without calling failureMessageBuilder when '
      'snapshot precheck reports reach (open-naval-panel branch skipped)',
      (tester) async {
        await _pumpEmpty(tester);
        ctE2eNavalPanelSnapshot = _reachedSnapshot();
        final perf = shared.E2ePerfLog('final_naval_reach_check_pin');
        var failureBuilderInvocations = 0;
        final result = await e2eEnsureNonHomeFleetInNwAfterLoop(
          tester,
          perf: perf,
          failureMessageBuilder: (lastException) {
            failureBuilderInvocations++;
            return 'should not be invoked (lastException=$lastException)';
          },
        );
        expect(
          failureBuilderInvocations,
          0,
          reason:
              'A snapshot that satisfies '
              '`e2eFleetReachDoneFromCtSnapshotOnly` must short-circuit '
              'past the conditional `openNavalPanel` AND the harness '
              'probe must succeed via snapshot — `failureMessageBuilder` '
              'should never fire on the happy reach path. A regression '
              'that called it unconditionally would fail every scenario '
              'with a synthetic message.',
        );
        expect(
          result.lastKnownNavalSnapshot,
          isNotNull,
          reason:
              'When the precheck satisfies via the live global '
              '`ctE2eNavalPanelSnapshot`, the captured snapshot must '
              'propagate into [E2eFinalNavalReachCheckResult.lastKnownNavalSnapshot] '
              'so test 2 can update its `lastKnownNavalSnapshot` tracker '
              'before the bundled-Explore diagnostics fire.',
        );
        expect(
          identical(result.lastKnownNavalSnapshot, ctE2eNavalPanelSnapshot),
          isTrue,
          reason:
              'The captured snapshot must be the same object reference '
              'as the live global at the post-conditional-open probe '
              'point — a defensive copy would either duplicate memory '
              'per call or drift the equality contract used by '
              '[e2eBundledExploreRejectionDiagnostics].',
        );
      },
    );
  });

  group('e2eEnsureNonHomeFleetInNwAfterLoop — failure branch', () {
    testWidgets(
      'calls failureMessageBuilder with tester.takeException() when '
      'snapshot reports no NW fleet and widget tree has no fleet rows '
      '(naval panel mounted so openNavalPanel short-circuits)',
      (tester) async {
        await _pumpWithNavalPanelMounted(tester);
        // Snapshot is non-null so the harness probe consults snapshot only
        // (does NOT fall back to the widget tree) — guarantees the
        // failure path fires deterministically without needing a full
        // naval panel widget tree.
        ctE2eNavalPanelSnapshot = _homeOnlySnapshot();
        final perf = shared.E2ePerfLog('final_naval_reach_check_pin');
        var failureBuilderInvocations = 0;
        Object? lastExceptionSeenByBuilder = 'not-yet-invoked';
        await expectLater(
          e2eEnsureNonHomeFleetInNwAfterLoop(
            tester,
            perf: perf,
            failureMessageBuilder: (lastException) {
              failureBuilderInvocations++;
              lastExceptionSeenByBuilder = lastException;
              return 'scenario-specific fail | lastException=$lastException';
            },
          ),
          throwsA(
            isA<TestFailure>().having(
              (e) => e.message,
              'message',
              contains('scenario-specific fail | lastException='),
            ),
          ),
          reason:
              'When the snapshot reports no NW fleet, the harness probe '
              'returns false and the helper MUST call '
              '`fail(failureMessageBuilder(tester.takeException()))` so '
              'the scenario-specific fail message preserves the legacy '
              '"Last exception:" suffix the inline blocks appended. A '
              'regression that swallowed the failure or used a hardcoded '
              'message would surface here as either no throw or a wrong '
              'message string.',
        );
        expect(
          failureBuilderInvocations,
          1,
          reason:
              '`failureMessageBuilder` must be invoked exactly once on '
              'the failure path so the scenario-specific fail message '
              'is the only one rendered. A regression that bypassed '
              'the builder would leave the count at 0; one that called '
              'it twice would double-render the message.',
        );
        // `tester.takeException()` returns `null` when no framework
        // exception was raised inside the helper body; pin that the
        // builder still receives the call with `null` so the legacy
        // "Last exception: null" rendering is preserved byte-identically
        // for log scrapers that consume the suffix.
        expect(
          lastExceptionSeenByBuilder,
          isNull,
          reason:
              'The builder must be invoked with the value of '
              '`tester.takeException()` even when that value is `null` '
              '(no framework exception raised inside the helper body). '
              'A regression that swapped to a sentinel "no exception" '
              'string or a placeholder Object would break log scrapers '
              'keyed on the literal "Last exception: null" suffix.',
        );
      },
    );
  });

  group('e2eEnsureNonHomeFleetInNwAfterLoop — AC1 barrel forwarding', () {
    testWidgets(
      'ensureNonHomeFleetInNwAfterLoop (barrel alias) short-circuits '
      'identically to the lifted form on the snapshot reach path',
      (tester) async {
        await _pumpEmpty(tester);
        ctE2eNavalPanelSnapshot = _reachedSnapshot();
        final perf = shared.E2ePerfLog('final_naval_reach_check_pin');
        var failureBuilderInvocations = 0;
        final result = await ensureNonHomeFleetInNwAfterLoop(
          tester,
          perf: perf,
          failureMessageBuilder: (lastException) {
            failureBuilderInvocations++;
            return 'should not fire';
          },
        );
        expect(
          failureBuilderInvocations,
          0,
          reason:
              'The AC1 barrel wrapper must forward arguments in the '
              'documented order — a regression that swapped '
              '`failureMessageBuilder` with `maxUiResponseWait`, '
              'dropped `perf`, or accidentally inserted a default '
              'message would surface here as a spurious failure on the '
              'happy reach path.',
        );
        expect(
          result.lastKnownNavalSnapshot,
          isNotNull,
          reason:
              'Barrel-aliased call must propagate the captured snapshot '
              'identically to the lifted form so the post-loop tracker '
              'in test 2 stays in sync between the two entrypoints.',
        );
      },
    );

    test(
      'ensureNonHomeFleetInNwAfterLoop is re-exported as a tear-off '
      '(compile-time signature pin)',
      () {
        final Future<E2eFinalNavalReachCheckResult> Function(
          WidgetTester, {
          required shared.E2ePerfLog perf,
          required String Function(Object? lastException)
              failureMessageBuilder,
          Duration maxUiResponseWait,
        })
        ref = ensureNonHomeFleetInNwAfterLoop;
        expect(
          ref,
          isNotNull,
          reason:
              'The AC1 barrel must continue to export the helper with '
              'the documented signature. A silent removal from the '
              '`show` clause or an arg-order swap on the wrapper would '
              'fail this assignment at compile time, surfacing a '
              'breaking change before CI rather than after.',
        );
      },
    );
  });

  group('e2eEnsureNonHomeFleetInNwAfterLoop — fixture sanity', () {
    test(
      '_reachedSnapshot reports reach via e2eFleetReachDoneFromCtSnapshotOnly',
      () {
        expect(
          shared.e2eFleetReachDoneFromCtSnapshotOnly(_reachedSnapshot()),
          isTrue,
          reason:
              'Pin must depend on the same predicate the helper uses so '
              'the "snapshot reach short-circuit" assertion is genuinely '
              'exercising the lifted contract — drift here would silently '
              'turn the happy-path test into a no-op.',
        );
      },
    );

    test(
      '_homeOnlySnapshot reports NO reach via '
      'e2eFleetReachDoneFromCtSnapshotOnly',
      () {
        expect(
          shared.e2eFleetReachDoneFromCtSnapshotOnly(_homeOnlySnapshot()),
          isFalse,
          reason:
              'Pin must depend on the same predicate the helper uses so '
              'the "failure branch" assertion really sends the helper '
              'down the openNavalPanel → harness-probe-fails path — '
              'drift here would short-circuit the failure path and '
              'leave the scenario-specific message untested.',
        );
      },
    );
  });
}
