/// Unit coverage for `e2eAdvanceGameStartIntroUntilDismissed` adaptive
/// backoff path. The helper's two idle-pump branches (loading spinner + no
/// tap target) previously paid a fixed 50ms frame per iteration; this test
/// pins the short-circuit behavior and adaptive ramp expectations introduced
/// for GitHub #2336 AC5 / pump-reduction.
///
/// The perf-attribution group at the bottom of the file pins the
/// `E2E_TIMING` / `E2E_COUNTER` markers the helper emits via [E2ePerfLog]
/// when callers thread a perf log through. The bootstrap chain
/// (`e2eBootstrapNewGameToMap` → `e2eWaitForMapHudAfterNewGameStart` →
/// `e2eAdvanceGameStartIntroUntilDismissed`) wires `perf` from the standard
/// scenario opener, so a silent regression in either the phase label, the
/// `result=...` meta tag, or the iteration counter would break the AC8
/// baseline timing pipeline (`tool/run_e2e_timing.sh` +
/// `tool/compare_e2e_timing.sh`) without surfacing in the legacy
/// short-circuit / timeout tests (which all pass `perf: null` by default).
/// Mirrors the perf-attribution pattern landed for
/// `e2eWaitForMapHudAfterNewGameStart` in PR #2960 (`app/test/
/// e2e_wait_for_map_hud_after_new_game_start_test.dart` § perf attribution).
library;

import 'dart:async';

import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'short-circuits before paying any pump when intro does not block UI',
    (WidgetTester tester) async {
      // No GameStartIntroOverlay / GameStartIntroLoadingIndicator mounted —
      // `e2eGameStartIntroBlocksUi` is false at entry (Branch 2 in
      // `e2e_game_start_intro_blocks_ui_test.dart`). A mounted overlay on its
      // first frame now blocks while Yarn loads (#2867 S10 / Branch 4).
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final sw = Stopwatch()..start();
      await e2eAdvanceGameStartIntroUntilDismissed(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Non-blocking intro state must return before any idle pump (#2336 '
            'AC5 pre-pump short-circuit).',
      );
    },
  );

  testWidgets('caps idle poll at 100ms even during long spinner stretch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GameStartIntroLoadingIndicator()),
    );
    // Spinner blocks UI; helper must time out via the loading-indicator
    // branch using adaptive backoff. Confirm it does **not** burn the full
    // wall clock on tiny fixed pumps by checking that the call returns the
    // failure within a small bounded multiple of its timeout (here 150ms).
    Object? caught;
    try {
      await e2eAdvanceGameStartIntroUntilDismissed(
        tester,
        timeout: const Duration(milliseconds: 150),
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason: 'Persistent spinner must hit the timeout failure path.',
    );
  });

  // -------- Perf attribution pins (Refs GitHub #2336 AC8 / baseline) --------
  //
  // Each pin below threads a non-null [E2ePerfLog] into
  // `e2eAdvanceGameStartIntroUntilDismissed` and captures the `E2E_TIMING` /
  // `E2E_COUNTER` lines via the same `debugPrint` override the
  // `e2e_wait_for_map_hud_after_new_game_start_test.dart` perf-attribution
  // group uses (PR #2960). A silent regression in either the phase label,
  // the `result=...` meta tag, or the iteration counter would break the AC8
  // baseline timing pipeline (`tool/run_e2e_timing.sh` +
  // `tool/compare_e2e_timing.sh`) without showing up in the legacy
  // short-circuit / timeout tests at the top of this file (which all pass
  // `perf: null` by default).

  group('e2eAdvanceGameStartIntroUntilDismissed multi-label pass', () {
    test(
      'control label order and post-tap settle cap stay pinned for bootstrap '
      'wall-clock (#2336 AC5)',
      () {
        expect(
          kE2eGameStartIntroControlLabels,
          ['Continue', 'I shall.'],
          reason:
              'Yarn intro controls must be tried in narrative order so an '
              'intermediate Continue tap can be followed by I shall. in the '
              'same loop iteration.',
        );
        expect(
          kE2eDefaultIntroControlPostTapSettleTimeout,
          const Duration(milliseconds: 500),
          reason:
              'Per-control settle must stay well below the legacy 5 s cap so '
              'bootstrap does not burn seconds waiting for full dismissal '
              'after an intermediate control tap.',
        );
        expect(
          kE2eDefaultIntroControlPostTapSettleTimeout.inMilliseconds,
          lessThan(5000),
        );
      },
    );
  });

  group('e2eAdvanceGameStartIntroUntilDismissed perf attribution', () {
    test('phase constant matches the documented '
        '`advance_game_start_intro_until_dismissed` label', () {
      expect(
        kE2eDefaultAdvanceGameStartIntroPhase,
        'advance_game_start_intro_until_dismissed',
        reason:
            'Phase constant must stay byte-equivalent so the AC8 baseline '
            'timing pipeline can key on the same phase=... label as the '
            'docs in `SPEC/program/e2e-integration-tests.md` § '
            'Determinism (Intro-dismiss perf attribution bullet).',
      );
    });

    test('counter constant matches the documented '
        '`advance_game_start_intro_until_dismissed_iterations` label', () {
      expect(
        kE2eAdvanceGameStartIntroIterationsCounter,
        'advance_game_start_intro_until_dismissed_iterations',
        reason:
            'Counter constant must stay byte-equivalent so the AC8 baseline '
            'timing pipeline can key on the same name=... label as the docs '
            'in `SPEC/program/e2e-integration-tests.md` § Determinism '
            '(Intro-dismiss perf attribution bullet).',
      );
    });

    testWidgets(
      'emits result=already_dismissed with iterations counter value=1 when '
      'intro does not block at entry',
      (WidgetTester tester) async {
        // No GameStartIntroOverlay / GameStartIntroLoadingIndicator mounted →
        // `e2eGameStartIntroBlocksUi` is false at iteration 1, so the helper
        // must short-circuit immediately and report the dedicated
        // `result=already_dismissed` meta tag with counter value `1`.
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final perf = E2ePerfLog('pin_advance_intro');
        final lines = await _captureDebugPrintsAsync(() async {
          await e2eAdvanceGameStartIntroUntilDismissed(tester, perf: perf);
        });

        final iterationsCounter = lines
            .where(
              (line) => line.contains(
                'name=$kE2eAdvanceGameStartIntroIterationsCounter',
              ),
            )
            .toList();
        expect(
          iterationsCounter,
          hasLength(1),
          reason:
              'The entry-iteration short-circuit must still bump the '
              'iterations counter once so a hung intro dismissal is '
              'distinguishable from a fast success in post-run analysis '
              '(#2336 AC8).',
        );
        expect(
          iterationsCounter.single,
          contains('|value=1'),
          reason:
              'Counter value at the already_dismissed short-circuit must be 1 '
              '(the single completed iteration) so the AC8 timing pipeline '
              'can use the counter as the de-duplicated intro-iteration '
              'tally without double-counting the entry frame.',
        );
        expect(
          iterationsCounter.single,
          contains('|meta=phase=$kE2eDefaultAdvanceGameStartIntroPhase'),
          reason:
              'Counter meta must carry the phase label so downstream parsers '
              'can slice the counter by the same phase=... key used by the '
              'timing marker.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains(
                    'phase=$kE2eDefaultAdvanceGameStartIntroPhase',
                  ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'already_dismissed short-circuit so suite aggregators do not '
              'double-count the intro-dismiss wait.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=already_dismissed'),
          reason:
              'The entry-iteration short-circuit must report '
              '`result=already_dismissed` so the baseline timing pipeline can '
              'separate fast already-dismissed returns from successful '
              'polled / tapped advances (#2336 AC8 attribution).',
        );
      },
    );

    testWidgets(
      'emits result=advanced and a counter value > 1 when the spinner clears '
      'mid-loop',
      (WidgetTester tester) async {
        // Mount the spinner first so iteration 1 hits the blocking branch
        // (loading-indicator), then schedule a fake-async unmount so the
        // helper observes the cleared state on a later iteration via its
        // adaptive idle pump. Mirrors the `result=advanced` pattern landed
        // for `e2eWaitForMapHudAfterNewGameStart` (PR #2960) — the only
        // difference is that this helper polls the intro-blocks predicate
        // instead of the home-to-capital button.
        final controller = _IntroSpinnerController(initiallyVisible: true);
        await tester.pumpWidget(
          MaterialApp(
            home: _IntroSpinnerHost(
              controller: controller,
              clearAfter: const Duration(milliseconds: 120),
            ),
          ),
        );
        expect(
          find.byType(GameStartIntroLoadingIndicator),
          findsOneWidget,
          reason:
              'Sanity check: the spinner must be mounted at entry so the '
              'helper actually exercises the blocking → advanced transition.',
        );

        final perf = E2ePerfLog('pin_advance_intro');
        final lines = await _captureDebugPrintsAsync(() async {
          await e2eAdvanceGameStartIntroUntilDismissed(
            tester,
            perf: perf,
            timeout: const Duration(seconds: 5),
          );
        });

        expect(
          find.byType(GameStartIntroLoadingIndicator),
          findsNothing,
          reason:
              'Sanity check: the helper must have observed the cleared '
              'spinner before returning; an early return on the entry '
              'iteration would imply the host scheduled the unmount before '
              'the first iteration check.',
        );

        final iterationsLines = lines
            .where(
              (line) => line.contains(
                'name=$kE2eAdvanceGameStartIntroIterationsCounter',
              ),
            )
            .toList();
        expect(
          iterationsLines.length,
          greaterThan(1),
          reason:
              'A scheduled-clear success path must bump the iterations '
              'counter on every loop iteration (including the success one), '
              'so the AC8 timing pipeline can attribute the wall-clock cost '
              'to the actual number of polling cycles.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains(
                    'phase=$kE2eDefaultAdvanceGameStartIntroPhase',
                  ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'polled-advance success path so suite aggregators do not '
              'double-count the intro-dismiss wait.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=advanced'),
          reason:
              'A polled-advance return must report `result=advanced` (not '
              '`already_dismissed`) so the baseline timing pipeline can '
              'separate fast and slow successful paths (#2336 AC8 '
              'attribution).',
        );
      },
    );

    testWidgets(
      'emits result=timeout on the overall-cap fail path when spinner '
      'persists',
      (WidgetTester tester) async {
        // Persistent spinner → the helper hits the timeout fail path. The
        // perf marker must still fire BEFORE the `fail(...)` throw so a
        // hung intro dismissal surfaces in the AC8 timing pipeline
        // alongside the `TestFailure`, instead of as a silent wall-clock
        // burn (matches the contract documented in
        // `SPEC/program/e2e-integration-tests.md` § Determinism /
        // Intro-dismiss perf attribution bullet).
        await tester.pumpWidget(
          const MaterialApp(home: GameStartIntroLoadingIndicator()),
        );
        final perf = E2ePerfLog('pin_advance_intro');
        final lines = <String>[];
        Object? caught;
        try {
          await _runWithDebugPrintCapture(lines, () async {
            await e2eAdvanceGameStartIntroUntilDismissed(
              tester,
              perf: perf,
              timeout: const Duration(milliseconds: 150),
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
              'fail-fast contract as the no-perf timeout test above.',
        );

        final timingLines = lines
            .where(
              (line) =>
                  line.contains(
                    'phase=$kE2eDefaultAdvanceGameStartIntroPhase',
                  ) &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timingLines,
          hasLength(1),
          reason:
              'Exactly one `E2E_TIMING|phase=...` line must be emitted on the '
              'timeout fail path so a hung intro dismissal surfaces in the '
              'AC8 timing pipeline (alongside the `TestFailure`) instead of '
              'as a silent wall-clock burn.',
        );
        expect(
          timingLines.single,
          contains('|meta=result=timeout'),
          reason:
              'The overall-cap fail path must report `result=timeout` so the '
              'baseline timing pipeline can distinguish a hung intro '
              'dismissal from a successful (slow) one (#2336 AC8 / AC10 '
              'attribution).',
        );
      },
    );

    testWidgets(
      'emits no markers when perf is null (default), preserving the opt-in '
      'attribution contract',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        final lines = <String>[];
        await _runWithDebugPrintCapture(lines, () async {
          await e2eAdvanceGameStartIntroUntilDismissed(tester);
        });
        final introMarkers = lines
            .where(
              (line) =>
                  line.contains(
                    'phase=$kE2eDefaultAdvanceGameStartIntroPhase',
                  ) ||
                  line.contains(
                    'name=$kE2eAdvanceGameStartIntroIterationsCounter',
                  ),
            )
            .toList();
        expect(
          introMarkers,
          isEmpty,
          reason:
              'Default `perf: null` must NOT emit any helper-attribution '
              'markers so callers that opt out of attribution (the legacy '
              'widget-test pins, ad-hoc scenarios, future low-overhead '
              'integration paths) keep their byte-quiet contract.',
        );
      },
    );
  });
}

/// Host that mounts (or unmounts) a [GameStartIntroLoadingIndicator] so the
/// `e2eAdvanceGameStartIntroUntilDismissed` polling loop drives the spinner →
/// cleared transition through its adaptive idle pump.
///
/// `Timer` callbacks scheduled in [State.initState] fire when `tester.pump`
/// advances fake-time past their delays, so the helper observes the
/// scheduled unmount on a later polling iteration without the test calling
/// `tester.pump` itself (which would deadlock against the helper's guarded
/// pump loop). Mirrors the `_NewGameSetupHost` controller pattern in
/// `app/test/e2e_wait_for_map_hud_after_new_game_start_test.dart`.
class _IntroSpinnerHost extends StatefulWidget {
  const _IntroSpinnerHost({required this.controller, this.clearAfter});

  final _IntroSpinnerController controller;

  /// Fake-async delay before the host unmounts the spinner, or `null`
  /// to leave the controller untouched (no scheduled transition).
  final Duration? clearAfter;

  @override
  State<_IntroSpinnerHost> createState() => _IntroSpinnerHostState();
}

class _IntroSpinnerHostState extends State<_IntroSpinnerHost> {
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    final after = widget.clearAfter;
    if (after != null) {
      _clearTimer = Timer(after, () => widget.controller.visible = false);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.visible) {
      return const SizedBox.shrink();
    }
    return const Center(child: GameStartIntroLoadingIndicator());
  }
}

class _IntroSpinnerController extends ChangeNotifier {
  _IntroSpinnerController({required bool initiallyVisible})
    : _visible = initiallyVisible;

  bool _visible;

  bool get visible => _visible;

  set visible(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    notifyListeners();
  }
}

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards (defensive in `finally` so a thrown
/// expectation does not leak the override into later tests).
///
/// Mirrors the `_captureDebugPrintsAsync` helper in
/// `app/test/e2e_wait_for_map_hud_after_new_game_start_test.dart` so the
/// perf-attribution pins added here use the same capture contract as the
/// canonical map-HUD bootstrap perf-attribution group. Refs GitHub #2336
/// AC8 baseline-marker contract.
Future<List<String>> _captureDebugPrintsAsync(
  Future<void> Function() body,
) async {
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
