/// Pins the widget-tree contract of
/// [e2eCheckExploreEnabledFromCivilianPanel]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `checkExploreEnabledFromCivilianPanel` once
/// initially and again on each retry of the bounded
/// `maxBoundedTurnRetries = 8` window. A silent rename or fail-open here
/// would either:
///
///   - Skip the open-civilian / wait / Explore-readiness / close-sheet
///     orchestration and let the strict Explore-enabled assertion run
///     against stale UI — masking a real production regression; or
///   - Stall on the slow `maxPanelSweepSteps (16) × per-step Assign sweep`
///     path the snapshot short-circuit already avoids — Bottleneck 5 in
///     `SPEC/program/e2e-integration-tests.md` § Determinism, burning
///     wall-clock the lift was meant to centralise.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so the widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC5 / Bottleneck 5.
library;

import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildRoad, kWorkTargetExplore;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const String _human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const Orders _emptyOrders = Orders();

Game _game() => const Game(
  id: 'g1',
  worldState: WorldState(
    turnState: _orderingTurn,
    oldWorld: RegionData(),
    newWorld: RegionData(),
  ),
  players: [Player(id: _human, displayName: 'You', isHuman: true)],
);

CtE2eCivilianPanelSnapshot _snapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

/// Mounts an already-visible civilian panel root under
/// [kCtE2ECivilianPanelRootKey]. The lifted helper's first step
/// ([e2eOpenCivilianPanel]) short-circuits when this key resolves to a
/// hit-testable element, so the widget test never needs to drive the empire
/// rail / marker tap path (those production-only triggers are out of scope
/// for the pin).
Widget _wrapPanelAlreadyOpen() => MaterialApp(
  home: Scaffold(
    body: KeyedSubtree(
      key: kCtE2ECivilianPanelRootKey,
      child: ListView(
        children: const [ListTile(title: Text('panel content placeholder'))],
      ),
    ),
  ),
);

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests). Mirrors the
/// pattern used by `e2e_perf_log_markers_test.dart`.
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
    ctE2eCivilianPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  group('e2eCheckExploreEnabledFromCivilianPanel — phase label const', () {
    test(
      'kE2eCheckExploreEnabledFromCivilianPanelPhase matches the legacy '
      '`bundled_explore_retry_loop` literal',
      () {
        expect(
          kE2eCheckExploreEnabledFromCivilianPanelPhase,
          'bundled_explore_retry_loop',
          reason:
              'The lifted-from constant must match the legacy private '
              'closure literal `bundled_explore_retry_loop` so any AC8 '
              'timing aggregator (or future `tool/run_e2e_timing.sh` '
              'consumer) that groups per-phase totals continues to see '
              'the same key. A silent rename would surface as missing '
              'phase data in the readiness retry slice, not as a test '
              'failure here in the slow CI lane.',
        );
      },
    );
  });

  group(
    'e2eCheckExploreEnabledFromCivilianPanel — snapshot-driven verdict',
    () {
      testWidgets(
        'snapshot hints Explore enabled → returns true, emits '
        '`result=enabled` timing',
        (tester) async {
          ctE2eCivilianPanelSnapshot = _snapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore],
            },
          );
          await tester.pumpWidget(_wrapPanelAlreadyOpen());
          final perf = E2ePerfLog('pin_check_explore_enabled');
          late bool result;
          final lines = await _captureDebugPrints(() async {
            result = await e2eCheckExploreEnabledFromCivilianPanel(
              tester,
              perf: perf,
            );
          });
          expect(
            result,
            isTrue,
            reason:
                'The snapshot short-circuit `true` verdict from '
                '[e2eAnyExplorerHasEnabledExploreAssignFleet] must propagate '
                'verbatim — a regression that re-walked the (empty) panel '
                'would either flip the verdict or burn the Bottleneck 5 '
                'sweep budget on every retry.',
          );
          expect(
            lines.where(
              (l) => l.contains(
                'phase=bundled_explore_retry_loop',
              ),
            ),
            hasLength(1),
            reason:
                'Exactly one `bundled_explore_retry_loop` timing marker '
                'must be emitted per call so the AC8 retry-loop slice '
                'stays attributable. Zero entries would surface as '
                'missing data in the timing pipeline; two or more would '
                'double-count the slice.',
          );
          expect(
            lines.singleWhere(
              (l) => l.contains('phase=bundled_explore_retry_loop'),
            ),
            contains('meta=result=enabled'),
            reason:
                'The `result=enabled` meta is how the AC8 timing pipeline '
                'distinguishes a true verdict from a false one without '
                're-running the helper. A regression that dropped the meta '
                'or used a different literal (e.g. `true` instead of '
                '`enabled`) would silently collapse the two branches in '
                'aggregates.',
          );
        },
      );

      testWidgets(
        'snapshot hints no Explore enabled → returns false, emits '
        '`result=not_enabled` timing',
        (tester) async {
          ctE2eCivilianPanelSnapshot = _snapshot(
            availableWorkTargets: const {
              'unit-1': [kWorkTargetBuildRoad],
            },
          );
          await tester.pumpWidget(_wrapPanelAlreadyOpen());
          final perf = E2ePerfLog('pin_check_explore_disabled');
          late bool result;
          final lines = await _captureDebugPrints(() async {
            result = await e2eCheckExploreEnabledFromCivilianPanel(
              tester,
              perf: perf,
            );
          });
          expect(
            result,
            isFalse,
            reason:
                'The snapshot short-circuit `false` verdict is '
                'contractually distinct from `null` and must propagate '
                'verbatim. A regression that conflated `false` with '
                '`null` would attempt the (empty) panel sweep and then '
                'time out, masking the real "Explore not assignable" '
                'state with a flaky timeout.',
          );
          expect(
            lines.singleWhere(
              (l) => l.contains('phase=bundled_explore_retry_loop'),
            ),
            contains('meta=result=not_enabled'),
            reason:
                'The `result=not_enabled` meta is the only signal a '
                'downstream timing aggregator has for the false branch. '
                'A regression that emitted `result=false` or no meta '
                'would lose the per-branch breakdown the AC8 pipeline '
                'depends on.',
          );
        },
      );
    },
  );

  group('e2eCheckExploreEnabledFromCivilianPanel — perf forwarding', () {
    testWidgets(
      'perf: null is a no-op (no `bundled_explore_retry_loop` marker emitted)',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _snapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(_wrapPanelAlreadyOpen());
        final lines = await _captureDebugPrints(() async {
          await e2eCheckExploreEnabledFromCivilianPanel(tester);
        });
        expect(
          lines.where(
            (l) => l.contains('phase=bundled_explore_retry_loop'),
          ),
          isEmpty,
          reason:
              'When the caller passes `perf: null`, the helper must not '
              'fabricate a perf log or call `timing` against a fallback '
              'sink. A regression that auto-instantiated `E2ePerfLog` '
              'here would emit unattributed markers in any production '
              'tester that opted out of perf logging.',
        );
      },
    );
  });

  group('e2eCheckExploreEnabledFromCivilianPanel — AC1 barrel forwarding', () {
    testWidgets(
      'checkExploreEnabledFromCivilianPanel (barrel alias) returns the same '
      'verdict as the lifted form',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _snapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(_wrapPanelAlreadyOpen());
        final result = await checkExploreEnabledFromCivilianPanel(tester);
        expect(
          result,
          isTrue,
          reason:
              'The AC1 barrel wrapper must forward arguments in the '
              'documented order and produce identical verdicts — a '
              'regression that swapped `perf` with `maxUiResponseWait`, '
              'dropped the snapshot path, or accidentally captured a '
              'fresh default would surface here, not in the slow CI '
              'lane.',
        );
      },
    );

    test(
      'checkExploreEnabledFromCivilianPanel is re-exported as a tear-off '
      '(compile-time signature pin)',
      () {
        final Future<bool> Function(
          WidgetTester, {
          E2ePerfLog? perf,
          Duration maxUiResponseWait,
          String waitUntilFoundPhase,
          String afterSheetPanelsClearPhase,
        })
        ref = checkExploreEnabledFromCivilianPanel;
        expect(
          ref,
          isNotNull,
          reason:
              'The AC1 barrel must continue to export the helper with '
              'the documented signature. A silent removal from the '
              '`show` clause or an arg-name change on the wrapper would '
              'fail this tear-off assignment at compile time.',
        );
      },
    );
  });
}
