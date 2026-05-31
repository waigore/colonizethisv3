// Pins the branch behaviour of `e2eDismissTransientUi` (Refs GitHub #2336
// AC2 / AC5 — shared E2E helper hardening).
//
// `e2eDismissTransientUi` is one of the most-called shared helpers across
// every integration_test (panel openers, fleet/turn loops, region tab
// flips). Its dismissal path is a multi-branch waterfall: GameStartIntro
// blocker → SnackBar action → top-level OK → AlertDialog labelled close →
// AlertDialog pop fallback → BottomSheet → CtDialogShell. A tuning
// regression that silently reorders or skips any branch would inflate every
// scenario's wall-clock cost (and, in the AlertDialog/SnackBar cases, can
// strand transient UI so subsequent opener calls time out).
//
// `integration_test/` is not part of the PR `quality` workflow (SPEC §
// `e2e-integration-tests.md`), so this widget-test layer is the only
// per-PR pin for the dismissal contract. Tests mirror the structure of
// the existing helper pins for sibling helpers
// (`app/test/e2e_close_bottom_sheet_test.dart`,
// `app/test/e2e_open_panel_prepump_test.dart`,
// `app/test/e2e_advance_game_start_intro_test.dart`).
//
// Coverage layers:
//   - Pre-pump short-circuit: an empty widget tree must not pay even one
//     idle pump (mirrors the AC5 prepump short-circuit pins for the panel
//     openers).
//   - SnackBar with action: tapping the SnackBar action removes the
//     SnackBar from the tree before the helper returns.
//   - Top-level OK button: tapping OK removes the OK label.
//   - AlertDialog with `Close` label: helper prefers the labelled close
//     button over the generic pop-route fallback.
//   - AlertDialog with no labelled close button: helper falls through to
//     `handlePopRoute` and clears the dialog.
//
// The `CtDialogShell` and `BottomSheet` branches are pinned in their own
// helpers (`e2e_close_bottom_sheet_test.dart` and the existing
// integration paths) and rely on Flame asset loading, so they are not
// exercised again here.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

class _SnackBarHost extends StatefulWidget {
  const _SnackBarHost();

  @override
  State<_SnackBarHost> createState() => _SnackBarHostState();
}

class _SnackBarHostState extends State<_SnackBarHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 30),
        content: const Text('snack-content'),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

class _AlertDialogHost extends StatefulWidget {
  const _AlertDialogHost({required this.actions});

  final List<Widget> actions;

  @override
  State<_AlertDialogHost> createState() => _AlertDialogHostState();
}

class _AlertDialogHostState extends State<_AlertDialogHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('alert-title'),
        content: const Text('alert-content'),
        actions: widget.actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eDismissTransientUi short-circuits when no transient UI is present',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final sw = Stopwatch()..start();
      await e2eDismissTransientUi(tester);
      expect(
        sw.elapsed < const Duration(milliseconds: 150),
        isTrue,
        reason:
            'Empty transient-UI tree must return before paying any pump frame '
            '(GitHub #2336 AC5: prepump short-circuit parity with sibling '
            'panel-opener helpers).',
      );
    },
  );

  testWidgets(
    'e2eDismissTransientUi taps SnackBar action and removes the SnackBar',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: _SnackBarHost()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'Test fixture must surface a SnackBar before the helper runs.',
      );

      await e2eDismissTransientUi(tester);
      // Allow the SnackBar dismissal animation to settle within the
      // helper's 2s pump-until-empty budget.
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byType(SnackBar),
        findsNothing,
        reason:
            'SnackBar with a tappable TextButton action must be dismissed via '
            'the action tap (e2eDismissTransientUi SnackBar branch) so the '
            'next caller does not race a still-mounted overlay.',
      );
    },
  );

  testWidgets('e2eDismissTransientUi taps a top-level OK button', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () {
                tapped = true;
              },
              child: const Text('OK'),
            ),
          ),
        ),
      ),
    );

    await e2eDismissTransientUi(tester);

    expect(
      tapped,
      isTrue,
      reason:
          'Top-level OK button must be tapped by the OK branch of '
          'e2eDismissTransientUi when no SnackBar/AlertDialog/BottomSheet '
          'is present.',
    );
  });

  testWidgets(
    'e2eDismissTransientUi taps a labelled Close action on an AlertDialog',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _AlertDialogHost(
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(tester.element(find.text('Close'))).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AlertDialog), findsOneWidget);

      await e2eDismissTransientUi(tester);
      // Dialog dismissal animations need a few extra frames after the
      // helper returns to fully unmount the route.
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'AlertDialog with a labelled Close action must be dismissed via '
            'the labelled-button branch (preferred over the pop-route '
            'fallback) so future calls do not race an extra pop.',
      );
    },
  );

  testWidgets(
    'e2eDismissTransientUi pops an AlertDialog with no recognised label',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _AlertDialogHost(actions: <Widget>[])),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AlertDialog), findsOneWidget);

      await e2eDismissTransientUi(tester);
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'AlertDialog with none of {Close, OK, Cancel, Yes} must be '
            'dismissed via the handlePopRoute fallback so the helper never '
            'returns with a stranded modal that blocks subsequent panel '
            'opener calls.',
      );
    },
  );

  // Perf-attribution group (Refs GitHub #2336 AC8 baseline timing):
  // Pins the dispatcher-level `E2E_TIMING|phase=dismiss_transient_ui` marker
  // and its `result=...` meta tag for every branch the helper can reach
  // (`intro_advanced`, `snackbar`, `generic_ok`, `alert_dialog`,
  // `broad_sweep`), plus the opt-out contract when `perf: null` is passed.
  // The dispatcher counter `dismiss_transient_ui_calls` keeps bumping on
  // entry regardless of branch so legacy log scrapers stay stable.
  //
  // Mirrors the perf-attribution group landed for
  // `e2eAdvanceGameStartIntroUntilDismissed` (PR #2966) and
  // `e2eWaitForMapHudAfterNewGameStart` (PR #2960). The integration suite
  // cannot validate the dispatcher attribution directly today
  // (`app_e2e_linux` is a no-op per `SPEC/program/e2e-integration-tests.md` §
  // CI), so this widget-test layer is the only per-PR pin for the new
  // dispatch markers and their meta-tag taxonomy.
  group('e2eDismissTransientUi perf attribution', () {
    test(
      'phase constant matches the documented `dismiss_transient_ui` label',
      () {
        expect(
          kE2eDefaultDismissTransientUiPhase,
          'dismiss_transient_ui',
          reason:
              'Phase constant must stay byte-equivalent so the AC8 baseline '
              'timing pipeline can key on the same phase=... label as the '
              'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
              '(Dismiss-transient-UI dispatch perf attribution bullet).',
        );
      },
    );

    testWidgets(
      'emits result=broad_sweep with the dispatcher counter still bumping '
      'when no transient UI is present',
      (WidgetTester tester) async {
        // Empty tree → none of the early-return branches fire, so the
        // dispatcher must report `result=broad_sweep` (the fall-through
        // path) and still bump `dismiss_transient_ui_calls` once on entry.
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );
        final perf = E2ePerfLog('pin_dismiss_transient_ui');
        final lines = await _captureDebugPrintsAsync(() async {
          await e2eDismissTransientUi(tester, perf: perf);
        });

        final dispatcherCounter = lines
            .where((line) => line.contains('name=dismiss_transient_ui_calls'))
            .toList();
        expect(
          dispatcherCounter,
          hasLength(1),
          reason:
              'The dispatcher counter `dismiss_transient_ui_calls` must bump '
              'exactly once on entry regardless of which branch handles the '
              'call so legacy log scrapers that aggregate dispatch '
              'invocations stay stable.',
        );

        final dispatcherTiming = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          dispatcherTiming,
          hasLength(1),
          reason:
              'Exactly one dispatcher-level `E2E_TIMING|phase=...` line must '
              'be emitted per call so suite aggregators do not double-count '
              'the dispatch wall-clock.',
        );
        expect(
          dispatcherTiming.single,
          contains('|meta=result=broad_sweep'),
          reason:
              'An empty-tree dispatch falls through every early-return '
              'branch, so the dispatcher must report `result=broad_sweep` '
              'so the AC8 timing pipeline can separate fast labelled-branch '
              'returns from the broad-sweep tail.',
        );
      },
    );

    testWidgets('emits result=snackbar when a SnackBar action is dispatched', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _SnackBarHost()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'Test fixture must surface a SnackBar before the helper runs.',
      );

      final perf = E2ePerfLog('pin_dismiss_transient_ui');
      final lines = await _captureDebugPrintsAsync(() async {
        await e2eDismissTransientUi(tester, perf: perf);
      });

      final dispatcherTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        dispatcherTiming,
        hasLength(1),
        reason:
            'Exactly one dispatcher-level `E2E_TIMING|phase=...` line must '
            'be emitted on a snackbar dispatch so the AC8 timing pipeline '
            'attributes the dispatch wall-clock without losing the inner '
            'snackbar helper attribution.',
      );
      expect(
        dispatcherTiming.single,
        contains('|meta=result=snackbar'),
        reason:
            'A snackbar dispatch must report `result=snackbar` so the AC8 '
            'timing pipeline can separate snackbar dispatches from other '
            'early-return branches and the broad-sweep tail.',
      );
    });

    testWidgets('emits result=generic_ok when a top-level OK is dispatched', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(onPressed: () {}, child: const Text('OK')),
            ),
          ),
        ),
      );
      final perf = E2ePerfLog('pin_dismiss_transient_ui');
      final lines = await _captureDebugPrintsAsync(() async {
        await e2eDismissTransientUi(tester, perf: perf);
      });

      final dispatcherTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        dispatcherTiming,
        hasLength(1),
        reason:
            'A top-level OK dispatch must emit exactly one dispatcher-level '
            '`E2E_TIMING|phase=dismiss_transient_ui` line so the AC8 '
            'pipeline never double-counts the dispatch wall-clock.',
      );
      expect(
        dispatcherTiming.single,
        contains('|meta=result=generic_ok'),
        reason:
            'A top-level OK dispatch must report `result=generic_ok` so '
            'the AC8 pipeline can separate generic-OK dispatches from the '
            'sibling alert-dialog labelled-close path that also includes '
            '`OK` in its label priority list.',
      );
    });

    testWidgets(
      'emits result=alert_dialog when a labelled AlertDialog action is '
      'dispatched',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _AlertDialogHost(
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(tester.element(find.text('Close'))).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(AlertDialog), findsOneWidget);

        final perf = E2ePerfLog('pin_dismiss_transient_ui');
        final lines = await _captureDebugPrintsAsync(() async {
          await e2eDismissTransientUi(tester, perf: perf);
        });
        // Allow dismissal animation to settle so the dispatcher does not
        // race the post-tap unmount; this does not affect the captured
        // perf markers above.
        await tester.pump(const Duration(milliseconds: 250));

        final dispatcherTiming = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissTransientUiPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          dispatcherTiming,
          hasLength(1),
          reason:
              'An AlertDialog dispatch must emit exactly one dispatcher-level '
              '`E2E_TIMING|phase=dismiss_transient_ui` line so the AC8 '
              'pipeline never double-counts the dispatch wall-clock.',
        );
        expect(
          dispatcherTiming.single,
          contains('|meta=result=alert_dialog'),
          reason:
              'An AlertDialog dispatch must report `result=alert_dialog` so '
              'the AC8 pipeline can separate AlertDialog dispatches from '
              'the snackbar / generic-OK / broad-sweep paths.',
        );
      },
    );

    testWidgets('emits no dispatcher-level timing when perf is null (default), '
        'preserving the opt-in attribution contract', (
      WidgetTester tester,
    ) async {
      // Default `perf: null` must not emit any dispatcher-level
      // `E2E_TIMING|phase=dismiss_transient_ui` line so legacy callers
      // that opt out of attribution keep their byte-quiet contract. The
      // inner helpers also stay byte-quiet because they only emit when a
      // non-null perf is threaded through.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final lines = <String>[];
      await _runWithDebugPrintCapture(lines, () async {
        await e2eDismissTransientUi(tester);
      });

      final dispatcherTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase'),
          )
          .toList();
      expect(
        dispatcherTiming,
        isEmpty,
        reason:
            'Default `perf: null` must NOT emit any dispatcher-level '
            'attribution markers so callers that opt out of attribution '
            '(the legacy widget-test pins, ad-hoc scenarios, future '
            'low-overhead integration paths) keep their byte-quiet '
            'contract.',
      );
    });

    testWidgets('a custom phaseName overrides the default dispatcher label', (
      WidgetTester tester,
    ) async {
      // Distinct dispatch sites can pass their own phaseName to keep
      // their timing markers separable in perf-timing dumps. The
      // dispatcher counter and the result=... taxonomy must stay the
      // same; only the phase=... label changes.
      const customPhase = 'dismiss_transient_ui_custom_call_site';
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      final perf = E2ePerfLog('pin_dismiss_transient_ui');
      final lines = await _captureDebugPrintsAsync(() async {
        await e2eDismissTransientUi(tester, perf: perf, phaseName: customPhase);
      });

      final customTiming = lines
          .where(
            (line) =>
                line.contains('phase=$customPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        customTiming,
        hasLength(1),
        reason:
            'Custom phaseName must reach the dispatcher-level timing '
            'emission so distinct dispatch sites can be filtered '
            'independently in AC8 perf-timing dumps.',
      );
      expect(
        customTiming.single,
        contains('|meta=result=broad_sweep'),
        reason:
            'The result=... taxonomy must be independent of phaseName so '
            'a custom dispatch site still reports the same branch tags '
            '(here `broad_sweep` for the empty-tree fall-through).',
      );

      // Match the full `phase=<label>|` field so a custom phaseName that
      // legitimately contains the default label as a substring (here
      // `dismiss_transient_ui_custom_call_site`) does not falsely register
      // as a duplicate marker. The trailing `|` is the canonical field
      // separator used in every `E2E_TIMING|...` line emitted by
      // `E2ePerfLog.timing`.
      final defaultTiming = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissTransientUiPhase|'),
          )
          .toList();
      expect(
        defaultTiming,
        isEmpty,
        reason:
            'A non-default phaseName must not also emit a marker keyed '
            'on the default label, or AC8 aggregators would double-count '
            'the same dispatch under two phase keys.',
      );
    });
  });
}

/// Captures `debugPrint` output during [body]. Mirrors the
/// `_captureDebugPrintsAsync` helper in
/// `app/test/e2e_advance_game_start_intro_test.dart` so the
/// dispatcher-level perf-attribution pins added here use the same capture
/// contract as the canonical intro-dismiss perf-attribution group. Refs
/// GitHub #2336 AC8 baseline-marker contract.
Future<List<String>> _captureDebugPrintsAsync(
  Future<void> Function() body,
) async {
  final captured = <String>[];
  await _runWithDebugPrintCapture(captured, body);
  return captured;
}

/// Underlying `debugPrint` override used by [_captureDebugPrintsAsync] and
/// any future fail-path perf tests that need to inspect captured lines even
/// when [body] throws.
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
