/// Pins the **branch waterfall** of `e2eWaitForMapHudAfterNewGameStart`
/// (`app/integration_test/e2e_test_shared_bootstrap.dart`) at the widget-unit
/// layer so each short-circuit of the new-game → map HUD setup wait is locked
/// against silent refactors that would only surface as confusing E2E flakes
/// (Refs GitHub #2336 AC4 / AC5 / AC10).
///
/// The helper drives every E2E new-game scenario (`e2eBootstrapNewGameToMap`
/// → fleet-reach, full-turn, capital-panel) — it polls until the in-game map
/// HUD's home-to-capital button is mounted, fails fast on the `Could not
/// create game` error dialog, hands off to `e2eAdvanceGameStartIntroUntilDismissed`
/// while the intro overlay (or its loading indicator) blocks the UI, and
/// times out via `fail(...)` when nothing settles within the wall-clock cap.
///
/// Because the `integration_test/` suite runs behind the no-op `app_e2e_linux`
/// lane today (`SPEC/program/e2e-integration-tests.md` § CI), the behavioral
/// pins live in the widget-test layer and use a fake-async `Timer` flip plus
/// host-mounted widgets so the helper's `tester.pump` loop drives state
/// transitions without the test pumping itself.
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart' show E2ePerfLog;
import '../integration_test/e2e_test_shared_bootstrap.dart';

/// Host that toggles which of the new-game setup states is mounted so the
/// helper's poll loop drives the branch under test through its short-circuit
/// or fail path.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past their delays, so the helper observes each
/// scheduled transition on a later polling iteration without the test
/// calling `tester.pump` itself (which would deadlock against the helper's
/// guarded pump loop).
class _NewGameSetupHost extends StatefulWidget {
  const _NewGameSetupHost({
    required this.controller,
    this.transitionAfter,
    this.transitionTo,
  });

  final _NewGameSetupController controller;

  /// Fake-async delay before the host applies [transitionTo], or `null`
  /// to leave the controller untouched (no scheduled transition).
  final Duration? transitionAfter;

  /// Target setup phase to apply when [transitionAfter] elapses, or
  /// `null` to leave the controller untouched.
  final _SetupPhase? transitionTo;

  @override
  State<_NewGameSetupHost> createState() => _NewGameSetupHostState();
}

class _NewGameSetupHostState extends State<_NewGameSetupHost> {
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.transitionAfter;
    final next = widget.transitionTo;
    if (after != null && next != null) {
      _transitionTimer = Timer(after, () => widget.controller.phase = next);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.controller.phase) {
      case _SetupPhase.idle:
        return const SizedBox.shrink();
      case _SetupPhase.errorDialog:
        return const Center(child: Text('Could not create game'));
      case _SetupPhase.creatingGame:
        return const Center(child: Text('Creating game'));
      case _SetupPhase.introLoading:
        return const Center(child: GameStartIntroLoadingIndicator());
      case _SetupPhase.mapHud:
        return Center(
          child: TextButton(
            key: kHomeToCapitalButtonKey,
            onPressed: () {},
            child: const Text('Capital'),
          ),
        );
    }
  }
}

class _NewGameSetupController extends ChangeNotifier {
  _NewGameSetupController({_SetupPhase initial = _SetupPhase.idle})
      : _phase = initial;

  _SetupPhase _phase;

  _SetupPhase get phase => _phase;

  set phase(_SetupPhase value) {
    if (_phase == value) {
      return;
    }
    _phase = value;
    notifyListeners();
  }
}

enum _SetupPhase { idle, errorDialog, creatingGame, introLoading, mapHud }

Future<_NewGameSetupController> _pumpHost(
  WidgetTester tester, {
  _SetupPhase initial = _SetupPhase.idle,
  Duration? transitionAfter,
  _SetupPhase? transitionTo,
}) async {
  final controller = _NewGameSetupController(initial: initial);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _NewGameSetupHost(
          controller: controller,
          transitionAfter: transitionAfter,
          transitionTo: transitionTo,
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'returns immediately when home-to-capital button is already mounted',
    (WidgetTester tester) async {
      await _pumpHost(tester, initial: _SetupPhase.mapHud);
      final sw = Stopwatch()..start();
      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 500)),
        reason:
            'Helper must short-circuit on the entry home-to-capital check '
            'when the map HUD is already mounted; reaching the overall cap '
            'would imply the pre-pump branch order regressed (#2336 AC5).',
      );
      expect(
        find.byKey(kHomeToCapitalButtonKey),
        findsOneWidget,
        reason:
            'Sanity check: the host kept the home-to-capital button mounted '
            'across the helper return so callers can chain on the same key.',
      );
    },
  );

  testWidgets(
    'fails with TestFailure when the "Could not create game" dialog is mounted',
    (WidgetTester tester) async {
      await _pumpHost(tester, initial: _SetupPhase.errorDialog);
      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(seconds: 5),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            '"Could not create game" must drive the fail-fast branch so a '
            'broken setup is not silently masked by the home-capital wait '
            '(#2336 AC10).',
      );
      expect(
        caught.toString(),
        allOf(
          contains('New game setup failed'),
          contains('error dialog'),
        ),
        reason:
            'Failure message must attribute the failure to the new-game '
            'setup branch ("New game setup failed") and the originating '
            'control ("error dialog") so the call site is unambiguous in '
            'CI logs (#2336 bootstrap contract).',
      );
    },
  );

  testWidgets(
    'fails on "Could not create game" even when home-to-capital is also mounted',
    (WidgetTester tester) async {
      // Build a host that mounts BOTH the error text and the home-to-capital
      // button in the same frame. The helper inspects them in declaration
      // order — error precedes home-capital — so the fail-fast branch must
      // win deterministically. Regressions that reorder the checks (or
      // demote the error to a soft warning) would let a broken setup leak
      // through as a green E2E run (#2336 AC10).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Could not create game')),
                Positioned(
                  top: 0,
                  child: TextButton(
                    key: kHomeToCapitalButtonKey,
                    onPressed: () {},
                    child: const Text('Capital'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(seconds: 5),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Error-dialog check must precede the home-capital short-circuit; '
            'a race that lets the success branch run before the error branch '
            'would silently hide setup failures.',
      );
    },
  );

  testWidgets(
    'returns once a scheduled home-to-capital mount lands during pump',
    (WidgetTester tester) async {
      // Schedule the host to flip into the mapHud phase after 80 ms of
      // fake-async time so the helper's adaptive pump loop advances the
      // clock past the Timer deadline and observes the change on a later
      // iteration (no guarded `tester.pump` from the test itself; #2336
      // AC5 adaptive polling).
      final controller = await _pumpHost(
        tester,
        initial: _SetupPhase.idle,
        transitionAfter: const Duration(milliseconds: 80),
        transitionTo: _SetupPhase.mapHud,
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsNothing);

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );

      expect(
        controller.phase,
        _SetupPhase.mapHud,
        reason:
            'Sanity check: the scheduled mount must have applied before the '
            'helper returned, otherwise the helper short-circuited on a '
            'stale state.',
      );
      expect(
        find.byKey(kHomeToCapitalButtonKey),
        findsOneWidget,
        reason:
            'Helper must return with the map HUD already mounted so callers '
            'can issue follow-up taps without an extra wait.',
      );
    },
  );

  testWidgets(
    'continues polling while "Creating game" text is mounted and returns once HUD lands',
    (WidgetTester tester) async {
      // Initial phase is `creatingGame` so the helper exercises the
      // dedicated "Creating game" branch on early iterations (idle pump
      // with adaptive backoff, no intro-dismiss handoff). After 120 ms of
      // fake-async time the host swaps to the map HUD, which the helper
      // must observe on a later iteration and return cleanly. A regression
      // that promoted "Creating game" to a fail-fast (or rerouted it
      // through the intro-dismiss path) would either throw here or burn
      // wall clock through unnecessary dismiss calls.
      await _pumpHost(
        tester,
        initial: _SetupPhase.creatingGame,
        transitionAfter: const Duration(milliseconds: 120),
        transitionTo: _SetupPhase.mapHud,
      );

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );

      expect(
        find.text('Creating game'),
        findsNothing,
        reason:
            'Sanity check: the host must have left the "Creating game" '
            'screen before the helper returned.',
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
    },
  );

  testWidgets(
    'hands off to intro-dismiss while loading indicator blocks, then returns once HUD lands',
    (WidgetTester tester) async {
      // `GameStartIntroLoadingIndicator` makes `e2eGameStartIntroBlocksUi`
      // return true, so the helper must enter the intro-dismiss branch
      // (resets the poll cadence and awaits the dismissal helper). The
      // host swaps to the map HUD after 100 ms of fake-async time —
      // crucially, removing the loading indicator first so the dismiss
      // helper returns and the outer loop can advance through the
      // home-to-capital short-circuit. A regression that demoted the
      // intro-blocks branch to the generic idle pump would either spin on
      // the loading indicator forever (it never clears on its own) or
      // race the home-capital check while the intro shell is still up.
      await _pumpHost(
        tester,
        initial: _SetupPhase.introLoading,
        transitionAfter: const Duration(milliseconds: 100),
        transitionTo: _SetupPhase.mapHud,
      );

      await e2eWaitForMapHudAfterNewGameStart(
        tester,
        overallCap: const Duration(seconds: 5),
      );

      expect(
        find.byType(GameStartIntroLoadingIndicator),
        findsNothing,
        reason:
            'Sanity check: the loading indicator must have left the tree '
            'before the helper returned, otherwise the intro-dismiss handoff '
            'was bypassed.',
      );
      expect(find.byKey(kHomeToCapitalButtonKey), findsOneWidget);
    },
  );

  testWidgets(
    'fails with TestFailure when overall cap elapses with no settle',
    (WidgetTester tester) async {
      await _pumpHost(tester, initial: _SetupPhase.idle);
      Object? caught;
      try {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(milliseconds: 150),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isA<TestFailure>(),
        reason:
            'Persistent empty setup state must hit the timeout fail path so '
            'real bootstrap regressions are not silently swallowed (#2336 '
            'AC10).',
      );
      final message = caught.toString();
      expect(
        message,
        contains('Timed out'),
        reason:
            'Failure message must call out the timeout so the helper failure '
            'is attributable in CI logs.',
      );
      expect(
        message,
        contains('map (home→capital)'),
        reason:
            'Failure message must reference the map (home→capital) wait so '
            'the failure is unambiguously attributed to '
            '`e2eWaitForMapHudAfterNewGameStart` (and not a sibling poll '
            'helper).',
      );
    },
  );

  // -------- Perf attribution pins (Refs GitHub #2336 AC8 / baseline) --------
  //
  // The pins below capture the `E2E_TIMING` / `E2E_COUNTER` markers the helper
  // emits via [E2ePerfLog] when callers thread a perf log through. The
  // bootstrap (`e2eBootstrapNewGameToMap`) wires `perf` from the standard
  // scenario opener, so a silent regression in either the phase label, the
  // `result=...` meta tag, or the iteration counter would break the AC8
  // baseline timing pipeline (`tool/run_e2e_timing.sh` +
  // `tool/compare_e2e_timing.sh`) without surfacing in the existing branch
  // waterfall tests (which all pass `perf: null` by default).

  group('e2eWaitForMapHudAfterNewGameStart perf attribution', () {
    testWidgets(
      'emits result=already_mounted with iterations counter value=1 when HUD is '
      'already mounted at entry',
      (WidgetTester tester) async {
        await _pumpHost(tester, initial: _SetupPhase.mapHud);
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = await _captureDebugPrintsAsync(() async {
          await e2eWaitForMapHudAfterNewGameStart(
            tester,
            overallCap: const Duration(seconds: 5),
            perf: perf,
          );
        });

        final iterationsCounter = lines
            .where(
              (line) => line.contains(
                'name=$kE2eWaitForMapHudIterationsCounter',
              ),
            )
            .toList();
        expect(
          iterationsCounter,
          hasLength(1),
          reason:
              'The entry-iteration short-circuit must still bump the '
              'iterations counter once so a hung bootstrap is distinguishable '
              'from a fast success in post-run analysis (#2336 AC8).',
        );
        expect(
          iterationsCounter.single,
          contains('|value=1'),
          reason:
              'Counter value at the already_mounted short-circuit must be 1 '
              '(the single completed iteration) so the AC8 timing pipeline '
              'can use the counter as the de-duplicated bootstrap-iteration '
              'tally without double-counting the entry frame.',
        );
        expect(
          iterationsCounter.single,
          contains('|meta=phase=$kE2eDefaultWaitForMapHudPhase'),
          reason:
              'Counter meta must carry the phase label so downstream parsers '
              'can slice the counter by the same phase=... key used by the '
              'timing marker.',
        );

        final timingLines = lines
            .where(
              (line) => line.contains(
                'phase=$kE2eDefaultWaitForMapHudPhase',
              ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'success path so suite aggregators do not double-count the '
              'bootstrap wait.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=already_mounted'),
          reason:
              'The entry-iteration short-circuit must report '
              '`result=already_mounted` so the baseline timing pipeline can '
              'separate fast already-mounted returns from successful polled '
              'advances (#2336 AC8 attribution).',
        );
      },
    );

    testWidgets(
      'emits result=advanced and a counter value > 1 when the HUD lands during '
      'the poll loop',
      (WidgetTester tester) async {
        await _pumpHost(
          tester,
          initial: _SetupPhase.creatingGame,
          transitionAfter: const Duration(milliseconds: 120),
          transitionTo: _SetupPhase.mapHud,
        );
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = await _captureDebugPrintsAsync(() async {
          await e2eWaitForMapHudAfterNewGameStart(
            tester,
            overallCap: const Duration(seconds: 5),
            perf: perf,
          );
        });

        final iterationsLines = lines
            .where(
              (line) => line.contains(
                'name=$kE2eWaitForMapHudIterationsCounter',
              ),
            )
            .toList();
        expect(
          iterationsLines.length,
          greaterThan(1),
          reason:
              'A scheduled-transition success path must bump the iterations '
              'counter on every loop iteration (including the success one), '
              'so the AC8 timing pipeline can attribute the wall-clock cost '
              'to the actual number of polling cycles.',
        );

        final timingLines = lines
            .where(
              (line) => line.contains(
                'phase=$kE2eDefaultWaitForMapHudPhase',
              ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'polled-advance success path.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=advanced'),
          reason:
              'A polled-advance return must report `result=advanced` (not '
              '`already_mounted`) so the baseline timing pipeline can '
              'separate fast and slow successful paths (#2336 AC8 '
              'attribution).',
        );
      },
    );

    testWidgets(
      'emits result=timeout on the overall-cap fail path',
      (WidgetTester tester) async {
        await _pumpHost(tester, initial: _SetupPhase.idle);
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = <String>[];
        Object? caught;
        try {
          await _runWithDebugPrintCapture(lines, () async {
            await e2eWaitForMapHudAfterNewGameStart(
              tester,
              overallCap: const Duration(milliseconds: 150),
              perf: perf,
            );
          });
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Sanity check: the timeout-fail-path test must still raise so '
              'the perf assertion below is exercised against the same '
              'fail-fast contract as the no-perf timeout test.',
        );

        final timingLines = lines
            .where(
              (line) => line.contains(
                'phase=$kE2eDefaultWaitForMapHudPhase',
              ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'timeout fail path so a hung bootstrap surfaces in the AC8 '
              'timing pipeline (alongside the `TestFailure`) instead of as a '
              'silent wall-clock burn.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=timeout'),
          reason:
              'The overall-cap fail path must report `result=timeout` so the '
              'baseline timing pipeline can distinguish a hung bootstrap from '
              'a successful (slow) one (#2336 AC8 / AC10 attribution).',
        );
      },
    );

    testWidgets(
      'emits result=error_dialog before failing on "Could not create game"',
      (WidgetTester tester) async {
        await _pumpHost(tester, initial: _SetupPhase.errorDialog);
        final perf = E2ePerfLog('pin_wait_for_map_hud');
        final lines = <String>[];
        Object? caught;
        try {
          await _runWithDebugPrintCapture(lines, () async {
            await e2eWaitForMapHudAfterNewGameStart(
              tester,
              overallCap: const Duration(seconds: 5),
              perf: perf,
            );
          });
        } catch (e) {
          caught = e;
        }
        expect(
          caught,
          isA<TestFailure>(),
          reason:
              'Sanity check: the error-dialog branch must still raise so the '
              'perf assertion below covers the same fail-fast contract as '
              'the no-perf error-dialog test.',
        );

        final timingLines = lines
            .where(
              (line) => line.contains(
                'phase=$kE2eDefaultWaitForMapHudPhase',
              ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'error-dialog fail-fast path so a broken new-game setup is '
              'attributable in the AC8 timing pipeline (alongside the '
              '`TestFailure`).',
        );
        expect(
          timingLines.single,
          contains('|meta=result=error_dialog'),
          reason:
              'The error-dialog fail path must report `result=error_dialog` '
              '(distinct from `result=timeout`) so the baseline timing '
              'pipeline can separate fast setup-failure paths from genuine '
              'wall-clock overruns (#2336 AC8 / AC10 attribution).',
        );
      },
    );

    testWidgets(
      'emits no markers when perf is null (default), preserving the '
      'opt-in attribution contract',
      (WidgetTester tester) async {
        await _pumpHost(tester, initial: _SetupPhase.mapHud);
        final lines = <String>[];
        await _runWithDebugPrintCapture(lines, () async {
          await e2eWaitForMapHudAfterNewGameStart(
            tester,
            overallCap: const Duration(seconds: 5),
          );
        });
        final mapHudMarkers = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultWaitForMapHudPhase') ||
                  line.contains('name=$kE2eWaitForMapHudIterationsCounter'),
            )
            .toList();
        expect(
          mapHudMarkers,
          isEmpty,
          reason:
              'Default `perf: null` must NOT emit any helper-attribution '
              'markers so callers that opt out of attribution (the existing '
              'widget-test pins, ad-hoc scenarios, future low-overhead '
              'integration paths) keep their byte-quiet contract.',
        );
      },
    );
  });
}

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
///
/// Mirrors the `_captureDebugPrints` helper in
/// `app/test/e2e_perf_log_markers_test.dart` so the perf-attribution pins
/// added here use the same capture contract as the canonical `E2ePerfLog`
/// marker tests. Refs GitHub #2336 AC8 baseline-marker contract.
Future<List<String>> _captureDebugPrintsAsync(Future<void> Function() body) async {
  final captured = <String>[];
  await _runWithDebugPrintCapture(captured, body);
  return captured;
}

/// Underlying `debugPrint` override used by [_captureDebugPrintsAsync] and the
/// fail-path perf tests, which need to inspect the captured lines even when
/// [body] throws.
Future<void> _runWithDebugPrintCapture(
  List<String> out,
  Future<void> Function() body,
) async {
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    out.add(message ?? '');
  };
  try {
    await body();
  } finally {
    debugPrint = original;
  }
}
