/// Pins the widget-tree contract of
/// [e2eDismissCtDialogShellBroadSweepIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_ct_dialog_shell_broad_sweep.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its [CtDialogShell] branch (every panel-opener pre-tap dismiss
/// across the three integration scenarios). The pre-lift inline block was a
/// 26-line recipe duplicated inside [e2eDismissTransientUi] and not
/// independently testable. After this lift, every overlay branch of the
/// broad-spectrum sweep delegates to a single-source-of-truth shared helper —
/// no inline dismissal recipes remain in [e2eDismissTransientUi]'s overlay
/// branches.
///
/// This pin guards:
///
/// - Priority ordering of the close-candidate list (`Cancel` text → `Close`
///   text → [Icons.close] → [Icons.arrow_back]). A silent reorder would
///   change which control gets tapped when more than one candidate is
///   hit-testable — for example a dialog with both `Cancel` and `Close`
///   should prefer `Cancel` to avoid accidentally confirming the
///   destructive default action that legacy [CtDialogShell] surfaces
///   sometimes wired to `Close`.
/// - Hit-testable filter on each candidate. A candidate finder that
///   matched without `.hitTestable()` would tap a control covered by a
///   transient overlay and silently miss the dismiss.
/// - The [tester.binding.handlePopRoute] fallback. When **none** of the
///   candidates are hit-testable the helper falls through to
///   `handlePopRoute()` rather than returning `false` — the legacy inline
///   block had no `false` branch when a [CtDialogShell] was mounted.
/// - The `dismiss_ct_dialog_shell_broad_sweep_calls` perf counter is
///   bumped once per **successful** dismissal attempt and **not** bumped
///   on the no-shell short-circuit.
/// - The default 2 s [kE2eDefaultCtDialogShellBroadSweepDismissTimeout]
///   budget — a silent drift here would either inflate the per-call
///   dismiss window (regressing AC9 aggregate wall-clock) or shrink it
///   (risking false negatives when the dismiss animation runs slow under
///   load).
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards. Mirrors the helper used by
/// `e2e_dismiss_alert_dialog_if_present_test.dart` and
/// `e2e_dismiss_snackbar_if_present_test.dart` so this pin verifies counter
/// emission against the same
/// `E2E_COUNTER|...|name=dismiss_ct_dialog_shell_broad_sweep_calls|value=...`
/// substring the [E2ePerfLog.bumpCounter] contract guarantees.
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

bool _hasCounterLine(
  List<String> lines, {
  required String test,
  required int expectedValue,
}) {
  final needle =
      'E2E_COUNTER|test=$test|name=dismiss_ct_dialog_shell_broad_sweep_calls'
      '|value=$expectedValue';
  return lines.any((line) => line == needle);
}

bool _hasAnyCounterLine(List<String> lines, {required String test}) {
  final prefix =
      'E2E_COUNTER|test=$test|'
      'name=dismiss_ct_dialog_shell_broad_sweep_calls|';
  return lines.any((line) => line.startsWith(prefix));
}

class _ShellHost extends StatefulWidget {
  const _ShellHost({required this.builder});

  /// Builds the dialog contents; receives a [close] callback the inner
  /// widgets can invoke from their `onPressed` callbacks to unmount the
  /// shell. Avoids tester.state hops inside button taps that would
  /// otherwise add lookup noise unrelated to the helper contract.
  final Widget Function(BuildContext context, VoidCallback close) builder;

  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  bool open = true;

  void _close() {
    setState(() => open = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }
    return CtDialogShell(child: widget.builder(context, _close));
  }
}

/// Surfaces a [CtDialogShell] **as a route** via `showDialog` so
/// `tester.binding.handlePopRoute()` can dismiss it during the
/// handlePopRoute-fallback pin. The non-route [_ShellHost] above keeps the
/// labelled / icon candidate tests focused on the helper's tap-resolve
/// contract, but `handlePopRoute()` only operates on the navigator's route
/// stack — a route-pushed fixture is required to exercise the fallback arm
/// realistically (the broad-sweep helper is consumed in production by
/// [e2eDismissTransientUi] for shells that were typically mounted via
/// `showDialog` or pushed by the panel openers).
class _RouteShellHost extends StatefulWidget {
  const _RouteShellHost({required this.dialogBuilder});

  /// Builder for the [CtDialogShell] under test. Allowing the host to
  /// supply the shell contents per-case keeps each pin focused.
  final WidgetBuilder dialogBuilder;

  @override
  State<_RouteShellHost> createState() => _RouteShellHostState();
}

class _RouteShellHostState extends State<_RouteShellHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: widget.dialogBuilder,
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

/// Surfaces a [CtDialogShell] whose contents include the [firstLabel] text
/// covered by an opaque [AbsorbPointer] overlay (so the first labelled
/// candidate is mounted but non-hit-testable) plus a hit-testable
/// [secondLabel] action.
///
/// Exercises the hit-testable filter contract — a regression that dropped
/// `.hitTestable()` would tap the covered first action and miss the
/// dismiss.
class _CoveredFirstActionShell extends StatelessWidget {
  const _CoveredFirstActionShell({
    required this.firstLabel,
    required this.onTapSecond,
    required this.secondLabel,
  });

  final String firstLabel;
  final String secondLabel;
  final VoidCallback onTapSecond;

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 48,
            child: Stack(
              children: [
                TextButton(onPressed: () {}, child: Text(firstLabel)),
                const Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(color: Color(0xFFFF0000)),
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTapSecond, child: Text(secondLabel)),
        ],
      ),
    );
  }
}

Widget _wrap(Widget body) => MaterialApp(
  home: Scaffold(body: Center(child: body)),
);

/// Top-level [WidgetBuilder] tear-off used by the route-based handlePopRoute
/// fallback pin. Surfaces a [CtDialogShell] with **no** labelled candidates
/// so the helper has to fall through to `tester.binding.handlePopRoute()`.
/// Must be a top-level function so the const constructor of [_RouteShellHost]
/// can hold it as a [WidgetBuilder] tear-off constant.
Widget _routeShellNoCandidatesBuilder(BuildContext context) {
  return const CtDialogShell(child: Text('Nothing tappable'));
}

/// Top-level [WidgetBuilder] tear-off used by the route-based perf-counter
/// handlePopRoute fallback pin. Same shape as
/// [_routeShellNoCandidatesBuilder] (no labelled candidates) so the helper
/// must escalate to `tester.binding.handlePopRoute()`.
Widget _routeShellNoCandidatesPerfBuilder(BuildContext context) {
  return const CtDialogShell(child: Text('Nothing tappable for perf'));
}

void main() {
  suppressLogsForTests();

  group('e2eDismissCtDialogShellBroadSweepIfPresent — constant pins', () {
    test('kE2eDefaultCtDialogShellBroadSweepDismissTimeout matches legacy 2 s '
        'budget', () {
      // The legacy inline CtDialogShell branch of e2eDismissTransientUi
      // used a hardcoded 2 s timeout. A silent drift here would either
      // inflate the per-call dismiss window (regressing AC9 aggregate
      // wall-clock) or shrink it (risking false negatives when the
      // shell dismiss animation runs slow under load).
      expect(
        kE2eDefaultCtDialogShellBroadSweepDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultCtDialogShellBroadSweepDismissTimeout must '
            'preserve the legacy 2 s inline budget to keep AC9 aggregate '
            'wall-clock attribution stable across the lift.',
      );
    });
  });

  group('e2eDismissCtDialogShellBroadSweepIfPresent — no-shell branch', () {
    testWidgets(
      'returns false without tapping or popping when no CtDialogShell is '
      'mounted',
      (WidgetTester tester) async {
        var siblingTaps = 0;
        await tester.pumpWidget(
          _wrap(
            TextButton(
              onPressed: () => siblingTaps++,
              child: const Text('Cancel'),
            ),
          ),
        );

        final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
          tester,
        );

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must short-circuit and return false when no '
              'CtDialogShell is mounted; otherwise a stray Cancel '
              'TextButton elsewhere in the tree would be tapped between '
              'phases.',
        );
        expect(
          siblingTaps,
          0,
          reason:
              'No tap should fire when the CtDialogShell branch '
              'short-circuits.',
        );
      },
    );
  });

  group(
    'e2eDismissCtDialogShellBroadSweepIfPresent — close-candidate priority',
    () {
      testWidgets('taps Cancel first when both Cancel and Close are mounted', (
        WidgetTester tester,
      ) async {
        var cancelTaps = 0;
        var closeTaps = 0;
        await tester.pumpWidget(
          _wrap(
            _ShellHost(
              builder: (context, close) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      cancelTaps++;
                      close();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => closeTaps++,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
          tester,
        );

        expect(
          dismissed,
          isTrue,
          reason:
              'Helper must return true after dismissing a labelled '
              'CtDialogShell.',
        );
        expect(
          cancelTaps,
          1,
          reason:
              'Cancel must be tapped first when both Cancel and Close are '
              'hit-testable — a reorder that put Close first would silently '
              'tap the destructive default action.',
        );
        expect(closeTaps, 0);
        expect(find.byType(CtDialogShell), findsNothing);
      });

      testWidgets(
        'taps Close when Cancel is absent and Close is hit-testable',
        (WidgetTester tester) async {
          var closeTaps = 0;
          await tester.pumpWidget(
            _wrap(
              _ShellHost(
                builder: (context, close) => TextButton(
                  onPressed: () {
                    closeTaps++;
                    close();
                  },
                  child: const Text('Close'),
                ),
              ),
            ),
          );

          final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
            tester,
          );

          expect(dismissed, isTrue);
          expect(closeTaps, 1);
          expect(find.byType(CtDialogShell), findsNothing);
        },
      );

      testWidgets(
        'taps Icons.close when neither Cancel nor Close text is present',
        (WidgetTester tester) async {
          var iconTaps = 0;
          await tester.pumpWidget(
            _wrap(
              _ShellHost(
                builder: (context, close) => IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    iconTaps++;
                    close();
                  },
                ),
              ),
            ),
          );

          final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
            tester,
          );

          expect(dismissed, isTrue);
          expect(
            iconTaps,
            1,
            reason:
                'Icons.close must dismiss when neither Cancel nor Close '
                'text candidates resolve; a regression that skipped this '
                'arm would surface as a hung shell on production opener '
                'paths that surface only the icon button.',
          );
          expect(find.byType(CtDialogShell), findsNothing);
        },
      );

      testWidgets(
        'taps Icons.arrow_back when Cancel/Close/Icons.close are all absent',
        (WidgetTester tester) async {
          var arrowTaps = 0;
          await tester.pumpWidget(
            _wrap(
              _ShellHost(
                builder: (context, close) => IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    arrowTaps++;
                    close();
                  },
                ),
              ),
            ),
          );

          final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
            tester,
          );

          expect(dismissed, isTrue);
          expect(
            arrowTaps,
            1,
            reason:
                'Icons.arrow_back is the lowest-priority labelled candidate '
                'and must dismiss when no higher-priority candidate '
                'resolves; this arm exists specifically to handle '
                'CtDialogShell variants that surface only the back-icon '
                'navigation control.',
          );
          expect(find.byType(CtDialogShell), findsNothing);
        },
      );
    },
  );

  group('e2eDismissCtDialogShellBroadSweepIfPresent — hit-testable filter', () {
    testWidgets('taps a later candidate when the higher-priority candidate is '
        'covered (non-hit-testable)', (WidgetTester tester) async {
      var closeTaps = 0;
      await tester.pumpWidget(
        _wrap(
          _CoveredFirstActionShell(
            firstLabel: 'Cancel',
            secondLabel: 'Close',
            onTapSecond: () => closeTaps++,
          ),
        ),
      );
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(
        find.text('Cancel'),
        findsOneWidget,
        reason:
            'Fixture must keep the Cancel candidate mounted (covered by '
            'an opaque overlay) so the hit-testable filter has a '
            'non-trivial choice to make.',
      );
      expect(find.text('Close'), findsOneWidget);

      // A regression that drops `.hitTestable()` would resolve `Cancel`
      // to the covered first action, tap it, and the dismiss would
      // miss — the shell would remain mounted. The lifted form filters
      // `Cancel` to zero hit-testable matches up-front, falls through,
      // and finds the hit-testable `Close` button on the next iteration.
      final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
        tester,
      );

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true even when the higher-priority '
            'Cancel is non-hit-testable, by tapping the hit-testable '
            'Close fallback.',
      );
      expect(
        closeTaps,
        1,
        reason:
            'A regression that dropped the hit-testable filter would '
            'tap the covered Cancel and never reach Close; the lifted '
            'form must tap exactly the visible Close button.',
      );
    });
  });

  group(
    'e2eDismissCtDialogShellBroadSweepIfPresent — handlePopRoute fallback',
    () {
      testWidgets(
        'falls back to handlePopRoute when no candidate is hit-testable and '
        'still returns true',
        (WidgetTester tester) async {
          // When the shell is mounted but contains no labelled candidate,
          // the helper must fall through to tester.binding.handlePopRoute.
          // The legacy inline block had no `false` branch when the shell
          // was mounted; preserving that semantic prevents callers (notably
          // [e2eDismissCtDialogShellWithPopRouteEscalation]) from skipping
          // the escalation arm because the helper falsely reported "did
          // nothing".
          //
          // The fixture pushes the shell as a route so `handlePopRoute()`
          // can actually pop it (the inline `_ShellHost` keeps the labelled
          // tests focused on the tap-resolve contract but is unaffected by
          // `handlePopRoute()`). This route-based fixture mirrors the
          // sibling AlertDialog pin's `_AlertDialogHost` pattern.
          await tester.pumpWidget(
            const MaterialApp(
              home: _RouteShellHost(
                dialogBuilder: _routeShellNoCandidatesBuilder,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.byType(CtDialogShell), findsOneWidget);

          final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
            tester,
          );
          await tester.pump(const Duration(milliseconds: 50));

          expect(
            dismissed,
            isTrue,
            reason:
                'handlePopRoute fallback must be reported as a successful '
                'dismissal attempt — the legacy inline block had no '
                '`false` branch when the shell was mounted.',
          );
          expect(
            find.byType(CtDialogShell),
            findsNothing,
            reason:
                'handlePopRoute() must close the CtDialogShell when no '
                'candidate is hit-testable. A regression that skipped the '
                'fallback would leave the shell mounted and starve the '
                'subsequent phase.',
          );
        },
      );
    },
  );

  group(
    'e2eDismissCtDialogShellBroadSweepIfPresent — perf counter bump pin',
    () {
      testWidgets(
        'emits exactly one E2E_COUNTER bump on labelled-tap success',
        (WidgetTester tester) async {
          final perf = E2ePerfLog('shell_broad_sweep_perf_pin');
          await tester.pumpWidget(
            _wrap(
              _ShellHost(
                builder: (context, close) =>
                    TextButton(onPressed: close, child: const Text('Cancel')),
              ),
            ),
          );

          late bool dismissed;
          final lines = await _captureDebugPrints(() async {
            dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
              tester,
              perf: perf,
            );
          });

          expect(dismissed, isTrue);
          expect(
            _hasCounterLine(
              lines,
              test: 'shell_broad_sweep_perf_pin',
              expectedValue: 1,
            ),
            isTrue,
            reason:
                'Labelled-tap success must emit exactly one '
                'E2E_COUNTER|...|name=dismiss_ct_dialog_shell_broad_sweep_calls'
                '|value=1 marker so observer dashboards can attribute the '
                'cost of stray CtDialogShell overlays per scenario. '
                'Captured lines: $lines',
          );
          final bumpCount = lines
              .where(
                (line) => line.startsWith(
                  'E2E_COUNTER|test=shell_broad_sweep_perf_pin|'
                  'name=dismiss_ct_dialog_shell_broad_sweep_calls|',
                ),
              )
              .length;
          expect(
            bumpCount,
            1,
            reason:
                'Success path must bump '
                'dismiss_ct_dialog_shell_broad_sweep_calls exactly once; '
                'a regression that double-bumped would inflate downstream '
                'counter aggregations. Captured lines: $lines',
          );
        },
      );

      testWidgets(
        'emits a single bump on handlePopRoute fallback (any successful '
        'dismissal attempt counts)',
        (WidgetTester tester) async {
          final perf = E2ePerfLog('shell_broad_sweep_fallback_perf_pin');
          await tester.pumpWidget(
            const MaterialApp(
              home: _RouteShellHost(
                dialogBuilder: _routeShellNoCandidatesPerfBuilder,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));

          final lines = await _captureDebugPrints(() async {
            await e2eDismissCtDialogShellBroadSweepIfPresent(
              tester,
              perf: perf,
            );
          });
          await tester.pump(const Duration(milliseconds: 50));

          expect(
            _hasCounterLine(
              lines,
              test: 'shell_broad_sweep_fallback_perf_pin',
              expectedValue: 1,
            ),
            isTrue,
            reason:
                'handlePopRoute fallback must also count as a successful '
                'dismissal attempt — the counter measures "stray '
                'CtDialogShells observed", not "labelled-button taps". '
                'Captured lines: $lines',
          );
        },
      );

      testWidgets(
        'does not emit dismiss_ct_dialog_shell_broad_sweep_calls when no '
        'CtDialogShell is mounted',
        (WidgetTester tester) async {
          final perf = E2ePerfLog('shell_broad_sweep_perf_no_shell_pin');
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: SizedBox())),
          );

          final lines = await _captureDebugPrints(() async {
            await e2eDismissCtDialogShellBroadSweepIfPresent(
              tester,
              perf: perf,
            );
          });

          expect(
            _hasAnyCounterLine(
              lines,
              test: 'shell_broad_sweep_perf_no_shell_pin',
            ),
            isFalse,
            reason:
                'No-shell short-circuit must not emit the counter marker '
                '(the helper returned false without tapping or popping). '
                'Captured lines: $lines',
          );
        },
      );
    },
  );
}
