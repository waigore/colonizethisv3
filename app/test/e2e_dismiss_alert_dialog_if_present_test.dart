/// Pins the widget-tree contract of [e2eDismissAlertDialogIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_alert_dialog.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its AlertDialog branch (every panel-opener pre-tap dismiss
/// across the three integration scenarios). The pre-lift inline block had
/// the same structural shape but was duplicated copy across the test files
/// and not testable in isolation. This pin guards:
///
/// - Priority ordering of [kE2eDefaultAlertDialogDismissLabels] (`Close` →
///   `OK` → `Cancel` → `Yes`). A silent reorder would change which button
///   gets tapped when more than one candidate is hit-testable — for example
///   a dialog with both `Close` and `OK` should prefer `Close` to avoid
///   accidentally confirming a destructive default action.
/// - Hit-testable filter on the labelled candidates. A label finder that
///   matched without `.hitTestable()` would tap a button covered by a
///   transient overlay and silently miss the dismiss.
/// - The `handlePopRoute` fallback. When no labelled button is
///   hit-testable the helper falls through to
///   `tester.binding.handlePopRoute()` rather than returning `false`
///   (the legacy inline block had no `false` branch when an AlertDialog
///   was mounted).
/// - The `dismiss_alert_dialog_calls` perf counter is bumped once per
///   successful dismissal attempt and **not** bumped on the no-AlertDialog
///   short-circuit.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards. Mirrors the helper used by the existing
/// `e2e_dismiss_snackbar_if_present_test.dart` so this pin verifies counter
/// emission against the same
/// `E2E_COUNTER|...|name=dismiss_alert_dialog_calls|value=...` substring
/// the `E2ePerfLog.bumpCounter` contract guarantees.
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

bool _hasAlertDialogCounterLine(
  List<String> lines, {
  required String test,
  required int expectedValue,
}) {
  final needle =
      'E2E_COUNTER|test=$test|name=dismiss_alert_dialog_calls'
      '|value=$expectedValue';
  return lines.any((line) => line == needle);
}

bool _hasAnyAlertDialogCounterLine(List<String> lines, {required String test}) {
  final prefix = 'E2E_COUNTER|test=$test|name=dismiss_alert_dialog_calls|';
  return lines.any((line) => line.startsWith(prefix));
}

/// Surfaces an [AlertDialog] once after the first frame so test bodies can
/// assert against a steady state without driving `showDialog` directly from
/// a stateless [Widget.build].
class _AlertDialogHost extends StatefulWidget {
  const _AlertDialogHost({required this.dialogBuilder});

  /// Builder for the [AlertDialog] under test. Allowing the host to supply
  /// the actions per-case keeps each pin focused.
  final WidgetBuilder dialogBuilder;

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

/// Surfaces an [AlertDialog] whose [actions] contain two [TextButton]s
/// matching the requested labels, with the first action **covered** by an
/// opaque [AbsorbPointer] overlay so the first labelled button is mounted
/// but non-hit-testable. The second labelled button remains hit-testable.
///
/// Exercises the hit-testable filter contract — a regression that dropped
/// `.hitTestable()` would tap the covered first action and miss the
/// dismiss.
class _CoveredFirstActionDialog extends StatelessWidget {
  const _CoveredFirstActionDialog({
    required this.firstLabel,
    required this.secondLabel,
  });

  final String firstLabel;
  final String secondLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('covered-first-dialog'),
      actions: [
        SizedBox(
          width: 120,
          height: 48,
          child: Stack(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(firstLabel),
              ),
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(color: Color(0xFFFF0000)),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(secondLabel),
        ),
      ],
    );
  }
}

void main() {
  suppressLogsForTests();

  group('e2eDismissAlertDialogIfPresent — constant pins', () {
    test('kE2eDefaultAlertDialogDismissTimeout matches legacy 2 s budget', () {
      // The legacy inline AlertDialog branch of e2eDismissTransientUi used a
      // hardcoded 2 s timeout. A silent drift here would either inflate the
      // per-call dismiss window (regressing AC9 aggregate wall-clock) or
      // shrink it (risking false negatives when the dialog dismiss
      // animation runs slow under load).
      expect(
        kE2eDefaultAlertDialogDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultAlertDialogDismissTimeout must preserve the legacy 2 s '
            'inline budget to keep AC9 aggregate wall-clock attribution '
            'stable across the lift.',
      );
    });

    test('kE2eDefaultAlertDialogDismissLabels priority is Close > OK > '
        'Cancel > Yes', () {
      // Pre-lift literal order in `e2eDismissTransientUi`. Reordering would
      // silently change which button gets tapped when more than one label
      // is hit-testable (e.g. dialog with both `Close` and `OK` actions
      // should prefer `Close` to avoid accidentally confirming a default).
      expect(
        kE2eDefaultAlertDialogDismissLabels,
        const <String>['Close', 'OK', 'Cancel', 'Yes'],
        reason:
            'kE2eDefaultAlertDialogDismissLabels priority must remain '
            '[Close, OK, Cancel, Yes] to preserve the legacy dismissal '
            'precedence.',
      );
    });
  });

  group('e2eDismissAlertDialogIfPresent — no-AlertDialog branch', () {
    testWidgets(
      'returns false without tapping or popping when no AlertDialog is mounted',
      (WidgetTester tester) async {
        var siblingTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => siblingTaps++,
                  child: const Text('Close'),
                ),
              ),
            ),
          ),
        );

        final dismissed = await e2eDismissAlertDialogIfPresent(tester);

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must short-circuit and return false when no AlertDialog '
              'is mounted; otherwise a stray `Close` TextButton elsewhere in '
              'the tree would be tapped between phases.',
        );
        expect(
          siblingTaps,
          0,
          reason:
              'No tap should fire when the AlertDialog branch short-circuits.',
        );
      },
    );
  });

  group('e2eDismissAlertDialogIfPresent — labelled-button priority', () {
    testWidgets('taps Close first when both Close and OK are hit-testable', (
      WidgetTester tester,
    ) async {
      var closeTaps = 0;
      var okTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: _AlertDialogHost(
            dialogBuilder: (context) => AlertDialog(
              title: const Text('priority-pin'),
              actions: [
                TextButton(
                  onPressed: () {
                    okTaps++;
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    closeTaps++;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AlertDialog), findsOneWidget);

      final dismissed = await e2eDismissAlertDialogIfPresent(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true after dismissing a labelled '
            'AlertDialog.',
      );
      expect(
        closeTaps,
        1,
        reason:
            'Close must be tapped first when both Close and OK are '
            'hit-testable — a reorder would silently confirm OK and the '
            'dismiss would still succeed but with the wrong action '
            'semantic.',
      );
      expect(okTaps, 0);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'taps OK when Close is absent and OK + Cancel are hit-testable',
      (WidgetTester tester) async {
        var okTaps = 0;
        var cancelTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: _AlertDialogHost(
              dialogBuilder: (context) => AlertDialog(
                title: const Text('ok-priority-pin'),
                actions: [
                  TextButton(
                    onPressed: () {
                      cancelTaps++;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      okTaps++;
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final dismissed = await e2eDismissAlertDialogIfPresent(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          okTaps,
          1,
          reason:
              'OK must take precedence over Cancel when Close is absent — '
              'a reorder that put Cancel first would silently dismiss '
              'via the wrong action.',
        );
        expect(cancelTaps, 0);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets('taps Yes when only Yes is present (last-priority label)', (
      WidgetTester tester,
    ) async {
      var yesTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: _AlertDialogHost(
            dialogBuilder: (context) => AlertDialog(
              title: const Text('yes-only-pin'),
              actions: [
                TextButton(
                  onPressed: () {
                    yesTaps++;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Yes'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final dismissed = await e2eDismissAlertDialogIfPresent(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(dismissed, isTrue);
      expect(yesTaps, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('e2eDismissAlertDialogIfPresent — hit-testable filter contract', () {
    testWidgets('taps a later labelled match when the higher-priority label is '
        'covered (non-hit-testable)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _AlertDialogHost(
            dialogBuilder: (context) => const _CoveredFirstActionDialog(
              firstLabel: 'Close',
              secondLabel: 'OK',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Close'),
        findsOneWidget,
        reason:
            'Fixture must keep the Close action mounted (covered by an '
            'opaque overlay) so the hit-testable filter has a non-trivial '
            'choice to make.',
      );
      expect(find.text('OK'), findsOneWidget);

      // A regression that drops `.hitTestable()` would resolve `Close`
      // to the covered first action, tap it, and the dismiss would
      // miss — the AlertDialog would remain mounted and the loop
      // moves to `OK`. The lifted form filters `Close` to zero hit-
      // testable matches up-front, falls through, and finds the
      // hit-testable `OK` button on the next iteration.
      final dismissed = await e2eDismissAlertDialogIfPresent(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true even when the higher-priority Close '
            'is non-hit-testable, by tapping the hit-testable OK fallback.',
      );
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason:
            'The hit-testable OK must dismiss the AlertDialog; if this '
            'fails the helper has regressed past the hit-testable filter '
            'and is tapping the covered, non-hit-testable Close.',
      );
    });
  });

  group('e2eDismissAlertDialogIfPresent — handlePopRoute fallback', () {
    testWidgets(
      'falls back to handlePopRoute when no labelled button is present',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _AlertDialogHost(
              dialogBuilder: (context) => const AlertDialog(
                title: Text('no-buttons-pin'),
                content: Text('AlertDialog with no labelled actions'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(AlertDialog), findsOneWidget);

        final dismissed = await e2eDismissAlertDialogIfPresent(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          dismissed,
          isTrue,
          reason:
              'Helper must return true even when no labelled button is '
              'present — the legacy inline block had no `false` branch '
              'after entering the AlertDialog arm.',
        );
        expect(
          find.byType(AlertDialog),
          findsNothing,
          reason:
              'handlePopRoute() must close the AlertDialog when no labelled '
              'button is hit-testable. A regression that skipped the '
              'fallback would leave the dialog mounted and starve the '
              'subsequent phase.',
        );
      },
    );

    testWidgets(
      'custom dismissLabels override skips the default Close/OK/Cancel/Yes',
      (WidgetTester tester) async {
        var customTaps = 0;
        var closeTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: _AlertDialogHost(
              dialogBuilder: (context) => AlertDialog(
                title: const Text('custom-labels-pin'),
                actions: [
                  TextButton(
                    onPressed: () {
                      closeTaps++;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      customTaps++;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final dismissed = await e2eDismissAlertDialogIfPresent(
          tester,
          dismissLabels: const <String>['Dismiss'],
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          customTaps,
          1,
          reason:
              'Custom dismissLabels override must tap the matching custom '
              'label exactly once.',
        );
        expect(
          closeTaps,
          0,
          reason:
              'A custom dismissLabels list must NOT fall back to the default '
              'Close/OK/Cancel/Yes labels; otherwise the override has no '
              'effect.',
        );
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });

  group('e2eDismissAlertDialogIfPresent — perf counter bump pin', () {
    testWidgets(
      'emits exactly one E2E_COUNTER dismiss_alert_dialog_calls bump on '
      'labelled-tap success',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_perf_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: _AlertDialogHost(
              dialogBuilder: (context) => AlertDialog(
                title: const Text('counter-success'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        late bool dismissed;
        final lines = await _captureDebugPrints(() async {
          dismissed = await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          _hasAlertDialogCounterLine(
            lines,
            test: 'alert_dialog_perf_pin',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'Labelled-tap success must emit exactly one '
              'E2E_COUNTER|...|name=dismiss_alert_dialog_calls|value=1 '
              'marker so observer dashboards can attribute the cost of '
              'stray AlertDialogs per scenario. Captured lines: $lines',
        );
        final bumpCount = lines
            .where(
              (line) => line.startsWith(
                'E2E_COUNTER|test=alert_dialog_perf_pin|'
                'name=dismiss_alert_dialog_calls|',
              ),
            )
            .length;
        expect(
          bumpCount,
          1,
          reason:
              'Success path must bump dismiss_alert_dialog_calls exactly '
              'once; a regression that double-bumped would inflate '
              'downstream counter aggregations. Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'emits a single bump on handlePopRoute fallback (any successful '
      'dismissal attempt counts)',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_fallback_perf_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: _AlertDialogHost(
              dialogBuilder: (context) => const AlertDialog(
                title: Text('counter-fallback'),
                content: Text('No labelled actions'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final lines = await _captureDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          _hasAlertDialogCounterLine(
            lines,
            test: 'alert_dialog_fallback_perf_pin',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'handlePopRoute fallback must also count as a successful '
              'dismissal attempt — the counter measures "stray AlertDialogs '
              'observed", not "labelled-button taps". Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_alert_dialog_calls when no AlertDialog is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('alert_dialog_perf_no_dialog_pin');
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissAlertDialogIfPresent(tester, perf: perf);
        });

        expect(
          _hasAnyAlertDialogCounterLine(
            lines,
            test: 'alert_dialog_perf_no_dialog_pin',
          ),
          isFalse,
          reason:
              'No-AlertDialog short-circuit must not emit the counter '
              'marker (the helper returned false without tapping or '
              'popping). Captured lines: $lines',
        );
      },
    );
  });
}
