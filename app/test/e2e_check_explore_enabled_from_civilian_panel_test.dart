/// Pins the widget-tree contract of
/// [e2eCheckExploreEnabledFromCivilianPanel]
/// (`app/integration_test/e2e_test_shared_panels.dart`).
///
/// The post-bundle Explore scenario in
/// `new_game_fleet_reaches_new_world_e2e_test.dart` calls this helper via
/// the AC1 barrel alias `checkExploreEnabledFromCivilianPanel` inside a
/// bounded `maxBoundedTurnRetries (8)` retry loop. The helper composes
/// four sub-steps (`open civilian panel`, `wait for root`, `Assign sweep`,
/// `close bottom sheet`) and emits a single `perf.timing(...)` entry per
/// invocation under the canonical
/// `kE2eDefaultBundledExploreRetryLoopPhase` ('bundled_explore_retry_loop')
/// phase label.
///
/// A silent regression here would either:
///
///   - Skip the `closeBottomSheet` call and stall the next retry
///     iteration on a stale Assign sheet — burning wall-clock the
///     bottom-sheet-close timeout already caps.
///   - Drop the `perf.timing(...)` invocation and orphan any telemetry /
///     dashboards keyed on the `bundled_explore_retry_loop` phase, hiding
///     Bottleneck 5 regressions.
///   - Forward the wrong [maxUiResponseWait] into either
///     [e2eAnyExplorerHasEnabledExploreAssignFleet] or
///     [e2eCloseBottomSheet] — inflating the per-iteration wall clock
///     past the `_kMaxUiResponseWait (5s)` cap #2336 is reducing.
///   - Flip the `meta=` payload between `result=enabled` /
///     `result=not_enabled`, masking a real Explore-enabled regression as
///     a steady-state pass.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
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
import '../integration_test/e2e_test_shared.dart' as shared;

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

CtE2eCivilianPanelSnapshot _civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: _human,
  currentOrders: _emptyOrders,
  availableWorkTargets: availableWorkTargets,
);

/// Mounts a hit-testable civilian panel root with the given children so
/// [e2eOpenCivilianPanel] short-circuits on its
/// `civilianPanel.hitTestable().evaluate().isNotEmpty` precondition. The
/// helper exits before attempting to open the empire rail / marker
/// triggers, isolating the contract under test to the wait/sweep/close
/// composition only.
Widget _wrap({required List<Widget> children}) => MaterialApp(
  home: Scaffold(
    body: KeyedSubtree(
      key: kCtE2ECivilianPanelRootKey,
      child: ListView(children: children),
    ),
  ),
);

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
    ctE2eCivilianPanelSnapshot = null;
  });

  tearDown(() {
    ctE2eCivilianPanelSnapshot = null;
  });

  group('e2eCheckExploreEnabledFromCivilianPanel — default constants', () {
    test('kE2eDefaultBundledExploreRetryLoopPhase preserves the legacy '
        'inline-closure phase literal', () {
      expect(
        kE2eDefaultBundledExploreRetryLoopPhase,
        'bundled_explore_retry_loop',
        reason:
            'Pre-lift `perf.timing("bundled_explore_retry_loop", ...)` '
            'callers (and downstream `E2E_TIMING|phase=...` scrapers) '
            'must keep seeing the same canonical phase name; a silent '
            'rename would orphan every dashboard/key keyed on '
            '`bundled_explore_retry_loop` and hide Bottleneck 5 '
            'regressions.',
      );
    });

    test('kE2eDefaultFleetCivilianOpenAfterSheetClearPhase preserves the '
        'legacy fleet-scenario attribution label', () {
      expect(
        kE2eDefaultFleetCivilianOpenAfterSheetClearPhase,
        'pump_until_panels_cleared_after_close_sheet_fleet_civilian_open',
        reason:
            'The fleet-scenario override label is distinct from the '
            'generic `_civilian_open` default used by '
            '[e2eOpenCivilianPanel] callers in the full-turn scenario; '
            'collapsing the two would attribute fleet retry-loop '
            'post-sheet-close pumps to the wrong scenario in AC8 '
            'timing tables.',
      );
    });
  });

  group('e2eCheckExploreEnabledFromCivilianPanel — snapshot short-circuit', () {
    testWidgets('snapshot says Explore enabled -> returns true and emits '
        'result=enabled timing event', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'explorer-1': [kWorkTargetExplore],
        },
      );
      await tester.pumpWidget(
        _wrap(children: const [ListTile(title: Text('Stub'))]),
      );
      final perf = shared.E2ePerfLog('check_explore_pin');
      late bool result;
      final lines = await _captureDebugPrints(() async {
        result = await e2eCheckExploreEnabledFromCivilianPanel(
          tester,
          perf: perf,
          maxUiResponseWait: const Duration(seconds: 5),
        );
      });
      expect(result, isTrue);
      final timingLines = lines
          .where((line) => line.startsWith('E2E_TIMING|'))
          .toList();
      expect(
        timingLines.any(
          (line) =>
              line.contains('|phase=$kE2eDefaultBundledExploreRetryLoopPhase|'),
        ),
        isTrue,
        reason:
            'A successful return must emit exactly one `E2E_TIMING` '
            'marker keyed on `bundled_explore_retry_loop` — the '
            'phase name AC8 / Bottleneck 5 dashboards key on.',
      );
      expect(
        timingLines.any((line) => line.endsWith('|meta=result=enabled')),
        isTrue,
        reason:
            'The `meta=result=enabled` payload distinguishes successful '
            'Explore detection from the `not_enabled` exhaustion path; '
            'a regression that flipped the boolean encoding would '
            'silently invert AC8 success/fail attribution.',
      );
    });

    testWidgets('snapshot says no Explore enabled -> returns false and emits '
        'result=not_enabled timing event', (tester) async {
      ctE2eCivilianPanelSnapshot = _civilianSnapshot(
        availableWorkTargets: const {
          'unit-1': [kWorkTargetBuildRoad],
        },
      );
      await tester.pumpWidget(
        _wrap(children: const [ListTile(title: Text('Stub'))]),
      );
      final perf = shared.E2ePerfLog('check_explore_pin');
      late bool result;
      final lines = await _captureDebugPrints(() async {
        result = await e2eCheckExploreEnabledFromCivilianPanel(
          tester,
          perf: perf,
        );
      });
      expect(result, isFalse);
      final timingLines = lines
          .where((line) => line.startsWith('E2E_TIMING|'))
          .toList();
      expect(
        timingLines.any((line) => line.endsWith('|meta=result=not_enabled')),
        isTrue,
        reason:
            'A snapshot `false` verdict must still emit a timing '
            'event so dashboards counting retry iterations (every '
            'iteration of the bounded retry window) attribute the '
            'exhaustion path correctly; dropping the marker on '
            '`false` would skew Bottleneck 5 cost attribution.',
      );
    });

    testWidgets(
      'perf parameter is optional — no E2E_TIMING marker emitted when '
      'perf is null',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _civilianSnapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(
          _wrap(children: const [ListTile(title: Text('Stub'))]),
        );
        late bool result;
        final lines = await _captureDebugPrints(() async {
          result = await e2eCheckExploreEnabledFromCivilianPanel(tester);
        });
        expect(result, isTrue);
        expect(
          lines.where((line) => line.startsWith('E2E_TIMING|')),
          isEmpty,
          reason:
              'Callers that opt out of perf logging (no shared '
              '`E2ePerfLog`) must not trigger spurious markers; the '
              'helper must guard the `perf?.timing(...)` call with a '
              'null check so unit tests / future stand-alone callers '
              'can use the helper without instantiating a perf log.',
        );
      },
    );
  });

  group(
    'e2eCheckExploreEnabledFromCivilianPanel — phaseTimingLabel override',
    () {
      testWidgets(
        'phaseTimingLabel overrides the default phase= field while keeping '
        'meta=result=...',
        (tester) async {
          ctE2eCivilianPanelSnapshot = _civilianSnapshot(
            availableWorkTargets: const {
              'explorer-1': [kWorkTargetExplore],
            },
          );
          await tester.pumpWidget(
            _wrap(children: const [ListTile(title: Text('Stub'))]),
          );
          final perf = shared.E2ePerfLog('check_explore_pin');
          final lines = await _captureDebugPrints(() async {
            await e2eCheckExploreEnabledFromCivilianPanel(
              tester,
              perf: perf,
              phaseTimingLabel: 'pin_custom_phase',
            );
          });
          final timingLines = lines
              .where((line) => line.startsWith('E2E_TIMING|'))
              .toList();
          expect(
            timingLines.any(
              (line) =>
                  line.contains('|phase=pin_custom_phase|') &&
                  line.endsWith('|meta=result=enabled'),
            ),
            isTrue,
            reason:
                'Callers (for example a future develop-phase retry loop '
                'reusing the same composition) must be able to attribute '
                'their timing under a distinct phase label without '
                'forking the helper implementation. A regression that '
                'hard-coded the default would silently merge attribution '
                'across scenarios.',
          );
        },
      );
    },
  );

  group('e2eCheckExploreEnabledFromCivilianPanel — AC1 barrel forwarding', () {
    testWidgets(
      'checkExploreEnabledFromCivilianPanel (barrel alias) returns the '
      'same boolean as the lifted form',
      (tester) async {
        ctE2eCivilianPanelSnapshot = _civilianSnapshot(
          availableWorkTargets: const {
            'explorer-1': [kWorkTargetExplore],
          },
        );
        await tester.pumpWidget(
          _wrap(children: const [ListTile(title: Text('Stub'))]),
        );
        final result = await checkExploreEnabledFromCivilianPanel(tester);
        expect(
          result,
          isTrue,
          reason:
              'The AC1 barrel wrapper must forward all named arguments '
              'in the documented order and preserve the boolean return '
              'value. A regression that dropped `tester` from the '
              'signature, swapped `perf` with `maxUiResponseWait`, or '
              'fail-opened to `false` would surface here, not in the '
              'slow CI lane.',
        );
      },
    );

    test('checkExploreEnabledFromCivilianPanel is re-exported as a tear-off '
        '(compile-time signature pin)', () {
      final Future<bool> Function(
        WidgetTester, {
        shared.E2ePerfLog? perf,
        Duration maxUiResponseWait,
        String afterSheetPanelsClearPhase,
        String phaseTimingLabel,
      })
      ref = checkExploreEnabledFromCivilianPanel;
      expect(
        ref,
        isNotNull,
        reason:
            'The AC1 barrel must continue to export the helper with '
            'the documented signature. A silent removal from the '
            '`show` clause, an arg-order swap on the wrapper, or a '
            'changed default for `maxUiResponseWait` / '
            '`afterSheetPanelsClearPhase` / `phaseTimingLabel` '
            'would fail this assignment at compile time.',
      );
    });
  });
}
