/// Pins the widget-tree contract of [e2eFleetReachTurnLoop]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// Both fleet-reach `testWidgets` bodies in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` call this helper via the
/// AC1 barrel alias `fleetReachTurnLoop` to drive up to
/// `_kMaxNextTurnTapsForNwFleetReach (35)` next-turn taps inside the 5-minute
/// scenario wall-clock cap (Bottleneck 4 in
/// `SPEC/program/e2e-integration-tests.md` § Determinism). A silent rename
/// or behavioural drift here would either:
///
///   - Burn the full 35 × ~5 s budget on a snapshot that already satisfies
///     `e2eFleetReachDoneFromCtSnapshotOnly` (the precheck short-circuit
///     keys the loop's "early exit" contract).
///   - Drop one of the `result=reached_*` enum branches and silently flip
///     the call site's `perf.timing('test_total', ..., meta: ...)` payload
///     to a stale label — breaking AC8 timing attribution.
///   - Stop bumping the `turn_loop_iterations` perf counter and orphan any
///     dashboard counting per-iteration cost.
///   - Stop emitting the canonical `ensureUnderWallClock` step labels and
///     surface as opaque `wall_clock_exceeded` failures with no
///     helper-level attribution.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test layer
/// carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 4.
library;

import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/l10n/app_localizations_contract.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
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

Future<void> _pumpEmpty(WidgetTester tester) =>
    tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
Future<List<String>> _captureDebugPrints(Future<void> Function() body) async {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
  return captured;
}

void main() {
  suppressLogsForTests();

  setUp(() {
    ctE2eNavalPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  group('e2eFleetReachTurnLoop — default constants', () {
    test('kE2eDefaultFleetReachLoopMaxTurns matches the legacy 35-turn cap', () {
      expect(
        kE2eDefaultFleetReachLoopMaxTurns,
        35,
        reason:
            'Lifted-from default must equal the legacy private '
            '`_kMaxNextTurnTapsForNwFleetReach = 35` literal in '
            '`new_game_fleet_reaches_new_world_e2e_helpers.dart`. A silent '
            'change would either burn additional turns past the documented '
            'Bottleneck 4 ceiling (#2336) or short-circuit the fleet-reach '
            'scenarios before they exercise the legacy reach window.',
      );
    });
  });

  group('e2eFleetReachTurnLoop — bounded loop', () {
    testWidgets(
      'maxTurns: 0 is a complete no-op — ensureUnderWallClock never invoked '
      'and the loop returns loopExhausted with iterationsRun=0',
      (tester) async {
        await _pumpEmpty(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        late E2eFleetReachLoopResult result;
        final lines = await _captureDebugPrints(() async {
          result = await e2eFleetReachTurnLoop(
            tester,
            l10n,
            perf: perf,
            ensureUnderWallClock: steps.add,
            maxTurns: 0,
          );
        });
        expect(
          steps,
          isEmpty,
          reason:
              'A zero-iteration call must not enter the for-body, must '
              'not invoke the wall-clock guard, and must not call any of '
              'the per-iteration helpers (dismiss / region-tab / open '
              'naval / try move / advance turn). Without this, callers '
              'cannot pass `maxTurns: 0` as a safe disarm in tests.',
        );
        expect(
          result.exit,
          E2eFleetReachLoopExit.loopExhausted,
          reason:
              'maxTurns: 0 must return [loopExhausted] so call sites that '
              'switch on the exit branch fall through to their post-loop '
              'path rather than misattributing a no-op to a reach result.',
        );
        expect(
          result.iterationsRun,
          0,
          reason:
              '[iterationsRun] for a zero-budget call must equal the '
              'budget itself — a regression that hardcoded a non-zero '
              'value would break the loop-exhausted invariant '
              '`iterationsRun == maxTurns`.',
        );
        expect(
          result.lastKnownNavalSnapshot,
          isNull,
          reason:
              'Without entering the body, no `ctE2eNavalPanelSnapshot` '
              'capture point ever fires; [lastKnownNavalSnapshot] must '
              'remain null so test 2 diagnostics fall back to the live '
              'global rather than an undefined value.',
        );
        expect(
          lines.where(
            (line) => line.startsWith(
              'E2E_COUNTER|test=fleet_reach_loop_pin|name=turn_loop_iterations|',
            ),
          ),
          isEmpty,
          reason:
              'A zero-iteration call must not bump the '
              '`turn_loop_iterations` counter. A regression that emitted '
              'one before the bounds check would skew Bottleneck 4 '
              'iteration counts on any scenario that disabled the loop.',
        );
      },
    );
  });

  group('e2eFleetReachTurnLoop — snapshot precheck short-circuit', () {
    testWidgets(
      'reached snapshot at iteration 0 returns [reachedSnapshotPrecheck] '
      'with iterationsRun=0 and a single ensureUnderWallClock callback',
      (tester) async {
        await _pumpEmpty(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = _reachedSnapshot();
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        late E2eFleetReachLoopResult result;
        final lines = await _captureDebugPrints(() async {
          result = await e2eFleetReachTurnLoop(
            tester,
            l10n,
            perf: perf,
            ensureUnderWallClock: steps.add,
            maxTurns: kE2eDefaultFleetReachLoopMaxTurns,
          );
        });
        expect(
          result.exit,
          E2eFleetReachLoopExit.reachedSnapshotPrecheck,
          reason:
              'A snapshot satisfying '
              '`e2eFleetReachDoneFromCtSnapshotOnly` at the very first '
              'probe of iteration 0 must map to '
              '[reachedSnapshotPrecheck] so call sites emit the legacy '
              '`meta: result=reached_snapshot_precheck` perf marker — '
              'never the more generic [reachedAfterMove] or post-turn '
              'branches.',
        );
        expect(
          result.iterationsRun,
          0,
          reason:
              'Reach on iteration 0 means iterationsRun must be 0; a '
              'regression that incremented inside the precheck branch '
              'would surface here as off-by-one and skew per-iteration '
              'wall-clock attribution.',
        );
        expect(
          steps,
          equals(<String>['turn loop start turnIdx=0']),
          reason:
              'The first per-iteration `ensureUnderWallClock` callback '
              'must fire before the snapshot probe so wall-clock guards '
              'apply uniformly across every iteration. Dropping it on '
              'iteration 0 would let a degenerate "always satisfied" '
              'snapshot mask a wall-clock breach.',
        );
        expect(
          lines.where(
            (line) => line.startsWith(
              'E2E_COUNTER|test=fleet_reach_loop_pin|name=turn_loop_iterations|',
            ),
          ).toList(),
          <String>[
            'E2E_COUNTER|test=fleet_reach_loop_pin|name=turn_loop_iterations|value=1',
          ],
          reason:
              'Even a precheck-only iteration must bump '
              '`turn_loop_iterations` exactly once so dashboards counting '
              'per-iteration cost attribute the entry to the right '
              'scenario; dropping the bump on the precheck branch would '
              'under-count the cheapest exit path.',
        );
      },
    );
  });

  group('e2eFleetReachTurnLoop — step label format', () {
    testWidgets(
      'step label uses `turn loop start turnIdx=<idx>` form on iteration 0',
      (tester) async {
        await _pumpEmpty(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = _reachedSnapshot();
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        await e2eFleetReachTurnLoop(
          tester,
          l10n,
          perf: perf,
          ensureUnderWallClock: steps.add,
          maxTurns: 1,
        );
        expect(
          steps.single,
          matches(RegExp(r'^turn loop start turnIdx=\d+$')),
          reason:
              'Wall-clock guards captured for `#2336` debug runs key on '
              'the `turn loop start turnIdx=` label prefix to attribute '
              'loop overshoot to this helper. A silent rename would '
              'surface in CI as an opaque `wall_clock_exceeded` failure '
              'with no helper attribution.',
        );
        expect(
          steps.single,
          equals('turn loop start turnIdx=0'),
          reason:
              'Iteration index must be 0-based and embedded into the '
              'label so a regression that reset the counter or used '
              '1-based indexing surfaces here, not as a confusing '
              'off-by-one in CI logs.',
        );
      },
    );
  });

  group('e2eFleetReachTurnLoop — AC1 barrel forwarding', () {
    testWidgets(
      'fleetReachTurnLoop (barrel alias) short-circuits identically to '
      'the lifted form when the snapshot precheck satisfies',
      (tester) async {
        await _pumpEmpty(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));
        ctE2eNavalPanelSnapshot = _reachedSnapshot();
        final perf = shared.E2ePerfLog('fleet_reach_loop_pin');
        final steps = <String>[];
        final result = await fleetReachTurnLoop(
          tester,
          l10n,
          perf: perf,
          ensureUnderWallClock: steps.add,
          maxTurns: kE2eDefaultFleetReachLoopMaxTurns,
        );
        expect(
          result.exit,
          E2eFleetReachLoopExit.reachedSnapshotPrecheck,
          reason:
              'The AC1 barrel wrapper must forward arguments in the '
              'documented order — a regression that swapped '
              '`ensureUnderWallClock` with `maxTurns`, dropped `l10n`, '
              'or accidentally captured a fresh `maxTurns` default would '
              'surface here, not in the slow CI lane.',
        );
        expect(
          result.iterationsRun,
          0,
          reason:
              'Barrel-aliased call must report the same '
              '[iterationsRun] as the lifted form so AC8 timing harness '
              'aggregating per-iteration cost stays attribution-stable '
              'across the lift.',
        );
        expect(
          steps,
          equals(<String>['turn loop start turnIdx=0']),
          reason:
              'Barrel alias must invoke `ensureUnderWallClock` exactly '
              'as the lifted form; an extra or missing callback would '
              'drift the wall-clock attribution between the two '
              'entrypoints.',
        );
      },
    );

    test(
      'fleetReachTurnLoop is re-exported as a tear-off '
      '(compile-time signature pin)',
      () {
        final Future<E2eFleetReachLoopResult> Function(
          WidgetTester,
          AppLocalizations, {
          required shared.E2ePerfLog perf,
          required void Function(String step) ensureUnderWallClock,
          Duration maxUiResponseWait,
          int maxTurns,
        })
        ref = fleetReachTurnLoop;
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
}
