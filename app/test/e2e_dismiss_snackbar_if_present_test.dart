/// Pins the widget-tree contract of [e2eDismissSnackBarIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_snackbar.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its SnackBar branch (every panel-opener pre-tap dismiss
/// across the three integration scenarios). The pre-lift inline block had
/// a subtle defect: it checked
/// `snackAction.hitTestable().evaluate().isNotEmpty` for presence but
/// tapped `snackAction.first` — the **first [TextButton]** in the SnackBar
/// **without** the hit-testable filter. A SnackBar whose first action was
/// covered by a transient overlay (rare but possible — a SnackBar plus a
/// SnackBar replaces it during animation, leaving a stale non-hit-testable
/// first TextButton in the tree briefly) would therefore record a
/// "dismiss attempted" tap that never landed, and the surrounding
/// [e2ePumpUntilFinderEmpty] would burn the full 2 s budget before
/// returning. The lift fixes this by tapping the **hit-testable filter's
/// first match** — matching the adjacent AlertDialog and CtDialogShell
/// branches of [e2eDismissTransientUi] that already use the filtered
/// finder for both the presence check and the tap.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Coverage layers:
///
///   - **No-SnackBar short-circuit**: helper returns `false` without
///     pumping or tapping when no [SnackBar] is mounted; sibling
///     [TextButton] widgets elsewhere in the tree must not be tapped.
///   - **Hit-testable action happy path**: helper taps the single
///     hit-testable action and returns `true`; the SnackBar leaves the
///     tree.
///   - **Multi-action hit-testable filter pin**: a SnackBar with two
///     [TextButton] descendants — the first non-hit-testable (covered by
///     an opaque overlay), the second hit-testable — must tap the
///     hit-testable button, **not** the first non-hit-testable one. This
///     guards against a regression that reverts the lift to
///     `snackAction.first` and starts dropping the SnackBar dismissal.
///   - **No-hit-testable-action fallback**: helper returns `false` when
///     the SnackBar has no hit-testable [TextButton] (caller is expected
///     to fall back to a broader dismissal strategy).
///   - **`perf` counter**: [E2ePerfLog] receives a single
///     `dismiss_snackbar_calls` bump only on the success path (the
///     no-shortcut and no-hit-testable branches do not bump).
///   - **`dismissTimeout` is forwarded**: setting [dismissTimeout] to
///     [Duration.zero] does not cause the helper to throw or hang
///     (proves the timeout is plumbed through [e2ePumpUntilFinderEmpty]
///     correctly; the SnackBar may not finish unmounting under a
///     zero-budget but the call still returns `true`).
///
/// Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards. Mirrors the helper used by the existing
/// `e2e_perf_log_markers_test.dart` so this pin verifies counter emission
/// against the same `E2E_COUNTER|...|name=dismiss_snackbar_calls|value=...`
/// substring the `E2ePerfLog.bumpCounter` contract guarantees.
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

bool _hasSnackbarCounterLine(List<String> lines, int expectedValue) {
  final needle =
      'E2E_COUNTER|test=snackbar_perf_pin|name=dismiss_snackbar_calls'
      '|value=$expectedValue';
  return lines.any((line) => line == needle);
}

bool _hasAnySnackbarCounterLine(List<String> lines, {required String test}) {
  final prefix = 'E2E_COUNTER|test=$test|name=dismiss_snackbar_calls|';
  return lines.any((line) => line.startsWith(prefix));
}

/// Surfaces a SnackBar once after the first frame so test bodies can
/// assert against a steady state without driving `ScaffoldMessenger`
/// directly.
class _SnackBarHost extends StatefulWidget {
  const _SnackBarHost({required this.snackBar});

  final SnackBar snackBar;

  @override
  State<_SnackBarHost> createState() => _SnackBarHostState();
}

class _SnackBarHostState extends State<_SnackBarHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    ScaffoldMessenger.of(context).showSnackBar(widget.snackBar);
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

/// Builds a SnackBar that surfaces two action [TextButton]s. When
/// [coverFirstAction] is `true`, an [AbsorbPointer] overlay sits above
/// the first [TextButton] so the first button is **mounted but
/// non-hit-testable**; the second button remains hit-testable. This
/// exercises the hit-testable filter contract on a SnackBar with two
/// action [TextButton]s — exactly the regression surface the pre-lift
/// `snackAction.first` defect would expose.
SnackBar _twoActionSnackBar({required bool coverFirstAction}) {
  final firstButton = TextButton(
    onPressed: () {},
    child: const Text('first-action'),
  );
  final secondButton = TextButton(
    onPressed: () {},
    child: const Text('second-action'),
  );
  return SnackBar(
    duration: const Duration(seconds: 30),
    content: Row(
      children: [
        if (coverFirstAction)
          SizedBox(
            width: 120,
            height: 48,
            child: Stack(
              children: [
                firstButton,
                const Positioned.fill(
                  child: AbsorbPointer(
                    child: ColoredBox(color: Color(0xFFFF0000)),
                  ),
                ),
              ],
            ),
          )
        else
          firstButton,
        secondButton,
      ],
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('e2eDismissSnackBarIfPresent — no-SnackBar branch', () {
    testWidgets('returns false without tapping when no SnackBar is mounted', (
      WidgetTester tester,
    ) async {
      var siblingTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => siblingTaps++,
                child: const Text('sibling-action'),
              ),
            ),
          ),
        ),
      );

      final dismissed = await e2eDismissSnackBarIfPresent(tester);

      expect(
        dismissed,
        isFalse,
        reason:
            'Helper must short-circuit and return false when no SnackBar '
            'is mounted; otherwise a stray TextButton elsewhere in the '
            'tree would be tapped between phases.',
      );
      expect(
        siblingTaps,
        0,
        reason: 'No tap should fire when the SnackBar branch short-circuits.',
      );
    });
  });

  group('e2eDismissSnackBarIfPresent — single-action happy path', () {
    testWidgets(
      'taps the hit-testable SnackBar action and returns true after dismissal',
      (WidgetTester tester) async {
        var actionTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: SnackBar(
                duration: const Duration(seconds: 30),
                content: const Text('snack-content'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () => actionTaps++,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(SnackBar), findsOneWidget);

        final dismissed = await e2eDismissSnackBarIfPresent(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          dismissed,
          isTrue,
          reason:
              'Helper must return true after tapping the hit-testable '
              'SnackBar action so callers can short-circuit the broader '
              'dismissal sweep.',
        );
        expect(
          actionTaps,
          1,
          reason:
              'The SnackBar action must receive exactly one tap (regression '
              'guard against double-tap or missed-tap variants).',
        );
        expect(
          find.byType(SnackBar),
          findsNothing,
          reason:
              'After the action tap the SnackBar must leave the tree within '
              'the default 2 s dismiss budget.',
        );
      },
    );
  });

  group('e2eDismissSnackBarIfPresent — hit-testable filter contract', () {
    testWidgets('taps the second action when the first action is covered '
        '(non-hit-testable)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _SnackBarHost(
            snackBar: _twoActionSnackBar(coverFirstAction: true),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('first-action'),
        findsOneWidget,
        reason:
            'Fixture must keep the first action mounted (covered by an '
            'opaque overlay) so the hit-testable filter has a non-trivial '
            'choice to make.',
      );
      expect(find.text('second-action'), findsOneWidget);

      // Pre-lift behavior would tap `snackAction.first` (the first
      // TextButton, which is covered and non-hit-testable here); the
      // lifted form must instead tap the hit-testable filter's first
      // match (the second action). A regression that reverts to
      // `snackAction.first` would tap the covered button and the
      // SnackBar would never dismiss — the post-dismiss expectation
      // below would fail with the SnackBar still in the tree.
      final dismissed = await e2eDismissSnackBarIfPresent(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        dismissed,
        isTrue,
        reason:
            'Helper must return true even when the first TextButton is '
            'non-hit-testable, by tapping the hit-testable second action.',
      );
      expect(
        find.byType(SnackBar),
        findsNothing,
        reason:
            'The hit-testable second action must dismiss the SnackBar; if '
            'this fails the helper has regressed to `snackAction.first` '
            'and is tapping the covered, non-hit-testable first button.',
      );
    });
  });

  group('e2eDismissSnackBarIfPresent — no-hit-testable-action branch', () {
    testWidgets(
      'returns false when the SnackBar has no hit-testable TextButton',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: const SnackBar(
                duration: Duration(seconds: 30),
                content: Text('no-action-content'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.byType(SnackBar), findsOneWidget);

        final dismissed = await e2eDismissSnackBarIfPresent(tester);

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must return false when no hit-testable TextButton is '
              'present so callers can fall back to a broader dismissal '
              'strategy (handlePopRoute or AlertDialog/CtDialogShell '
              'sweep).',
        );
        expect(
          find.byType(SnackBar),
          findsOneWidget,
          reason:
              'The SnackBar must remain mounted when the helper returns '
              'false; a regression that tapped despite no hit-testable '
              'action would silently dismiss the bar and the next call '
              'would race the in-flight dismissal animation.',
        );
      },
    );
  });

  group('e2eDismissSnackBarIfPresent — perf counter bump pin', () {
    testWidgets(
      'emits exactly one E2E_COUNTER dismiss_snackbar_calls bump on success',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_perf_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: SnackBar(
                duration: const Duration(seconds: 30),
                content: const Text('snack-content'),
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        late bool dismissed;
        final lines = await _captureDebugPrints(() async {
          dismissed = await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          _hasSnackbarCounterLine(lines, 1),
          isTrue,
          reason:
              'Success path must emit exactly one '
              'E2E_COUNTER|...|name=dismiss_snackbar_calls|value=1 marker so '
              'observer dashboards can attribute the cost of stranded '
              'SnackBars per scenario. Captured lines: $lines',
        );
        final bumpCount = lines
            .where(
              (line) => line.startsWith(
                'E2E_COUNTER|test=snackbar_perf_pin|name=dismiss_snackbar_calls|',
              ),
            )
            .length;
        expect(
          bumpCount,
          1,
          reason:
              'Success path must bump dismiss_snackbar_calls exactly once; '
              'a regression that double-bumped would inflate downstream '
              'counter aggregations. Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_snackbar_calls when no SnackBar is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_perf_no_sb_pin');
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        expect(
          _hasAnySnackbarCounterLine(lines, test: 'snackbar_perf_no_sb_pin'),
          isFalse,
          reason:
              'No-SnackBar short-circuit must not emit the counter marker '
              '(the caller did not actually dismiss anything). Captured '
              'lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_snackbar_calls when no hit-testable action found',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_perf_no_action_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: const SnackBar(
                duration: Duration(seconds: 30),
                content: Text('no-action-content'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final lines = await _captureDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        expect(
          _hasAnySnackbarCounterLine(
            lines,
            test: 'snackbar_perf_no_action_pin',
          ),
          isFalse,
          reason:
              'No-hit-testable-action branch must not emit the counter '
              'marker (the helper returned false without tapping). Captured '
              'lines: $lines',
        );
      },
    );
  });

  group('e2eDismissSnackBarIfPresent — constant pin', () {
    test('kE2eDefaultSnackBarDismissTimeout matches legacy 2 s budget', () {
      // The legacy inline SnackBar branch of e2eDismissTransientUi used a
      // hardcoded 2 s timeout. A silent drift here would either inflate the
      // per-call dismiss window (regressing AC9 aggregate wall-clock) or
      // shrink it (risking false negatives when the SnackBar dismiss
      // animation runs slow under load).
      expect(
        kE2eDefaultSnackBarDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultSnackBarDismissTimeout must preserve the legacy 2 s '
            'inline budget to keep AC9 aggregate wall-clock attribution '
            'stable across the lift.',
      );
    });
  });

  // The following group pins the inner-helper perf attribution surface added
  // alongside the dispatcher-level [e2eDismissTransientUi] result-tag
  // taxonomy (Refs GitHub #2336 AC8 baseline timing). The integration suite
  // cannot validate the inner-helper attribution directly today
  // (`app_e2e_linux` is a no-op per `SPEC/program/e2e-integration-tests.md` §
  // CI), so this widget-test layer is the only per-PR pin for the new
  // inner-helper markers and their `result=...` taxonomy.
  group('e2eDismissSnackBarIfPresent perf attribution', () {
    test('phase constant matches the documented `dismiss_snackbar` label', () {
      expect(
        kE2eDefaultDismissSnackBarPhase,
        'dismiss_snackbar',
        reason:
            'Phase constant must stay byte-equivalent so the AC8 baseline '
            'timing pipeline can key on the same phase=... label as the '
            'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
            '(Dismiss-snackbar inner perf attribution bullet).',
      );
    });

    testWidgets(
      'emits result=not_present without the dispatcher counter when no '
      'SnackBar is mounted',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_phase_pin');
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        final timing = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissSnackBarPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timing,
          hasLength(1),
          reason:
              'Exactly one inner-helper `E2E_TIMING|phase=...` line must be '
              'emitted on the no-SnackBar short-circuit so suite aggregators '
              'do not double-count the inner wall-clock. Captured: $lines',
        );
        expect(
          timing.single,
          contains('|meta=result=not_present'),
          reason:
              'Empty-tree dismissal must report `result=not_present` so the '
              'AC8 timing pipeline can separate cheap no-op short-circuits '
              'from real dismissals.',
        );
        expect(
          _hasAnySnackbarCounterLine(lines, test: 'snackbar_phase_pin'),
          isFalse,
          reason:
              'No-SnackBar short-circuit must not bump '
              '`dismiss_snackbar_calls` (the helper returned false without '
              'tapping). Captured: $lines',
        );
      },
    );

    testWidgets(
      'emits result=no_action without the dispatcher counter when SnackBar '
      'has no hit-testable TextButton',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('snackbar_no_action_phase_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: const SnackBar(
                duration: Duration(seconds: 30),
                content: Text('no-action-content'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final lines = await _captureDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester, perf: perf);
        });

        final timing = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissSnackBarPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timing,
          hasLength(1),
          reason:
              'Exactly one inner-helper `E2E_TIMING|phase=...` line must be '
              'emitted on the no-hit-testable-action branch. Captured: '
              '$lines',
        );
        expect(
          timing.single,
          contains('|meta=result=no_action'),
          reason:
              'A SnackBar without a hit-testable action must report '
              '`result=no_action` so the AC8 timing pipeline can separate '
              'this cheap fallthrough path from a real action tap.',
        );
        expect(
          _hasAnySnackbarCounterLine(
            lines,
            test: 'snackbar_no_action_phase_pin',
          ),
          isFalse,
          reason:
              'No-action branch must not bump `dismiss_snackbar_calls` (the '
              'helper returned false without tapping). Captured: $lines',
        );
      },
    );

    testWidgets('emits result=tapped alongside the dispatcher counter when the '
        'hit-testable action is dismissed', (WidgetTester tester) async {
      final perf = E2ePerfLog('snackbar_tapped_phase_pin');
      await tester.pumpWidget(
        MaterialApp(
          home: _SnackBarHost(
            snackBar: SnackBar(
              duration: const Duration(seconds: 30),
              content: const Text('snack-content'),
              action: SnackBarAction(label: 'Undo', onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      late bool dismissed;
      final lines = await _captureDebugPrints(() async {
        dismissed = await e2eDismissSnackBarIfPresent(tester, perf: perf);
      });
      await tester.pump(const Duration(milliseconds: 50));

      expect(dismissed, isTrue);
      final timing = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultDismissSnackBarPhase') &&
                line.startsWith('E2E_TIMING|'),
          )
          .toList();
      expect(
        timing,
        hasLength(1),
        reason:
            'Exactly one inner-helper `E2E_TIMING|phase=...` line must be '
            'emitted on the success path. Captured: $lines',
      );
      expect(
        timing.single,
        contains('|meta=result=tapped'),
        reason:
            'A successful dismissal must report `result=tapped` so the '
            'AC8 timing pipeline can separate real action taps from the '
            'cheap no-op short-circuits.',
      );
    });

    testWidgets(
      'no perf line emitted when perf is null (default opt-out contract)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: SnackBar(
                duration: const Duration(seconds: 30),
                content: const Text('quiet'),
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final lines = await _captureDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(tester);
        });
        await tester.pump(const Duration(milliseconds: 50));

        final phaseLines = lines
            .where(
              (line) =>
                  line.startsWith('E2E_TIMING|') &&
                  line.contains('phase=$kE2eDefaultDismissSnackBarPhase'),
            )
            .toList();
        expect(
          phaseLines,
          isEmpty,
          reason:
              'Default `perf: null` must preserve the byte-quiet contract: '
              'no `E2E_TIMING|phase=dismiss_snackbar` line should be emitted '
              'for opt-out callers. Captured: $lines',
        );
      },
    );

    testWidgets(
      'custom phaseName reaches the inner-helper emission and does NOT also '
      'emit under the default label',
      (WidgetTester tester) async {
        const customPhase = 'snackbar_custom_phase_label';
        final perf = E2ePerfLog('snackbar_custom_phase_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: _SnackBarHost(
              snackBar: SnackBar(
                duration: const Duration(seconds: 30),
                content: const Text('custom-phase'),
                action: SnackBarAction(label: 'Undo', onPressed: () {}),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        final lines = await _captureDebugPrints(() async {
          await e2eDismissSnackBarIfPresent(
            tester,
            perf: perf,
            phaseName: customPhase,
          );
        });
        await tester.pump(const Duration(milliseconds: 50));

        final customTiming = lines
            .where(
              (line) =>
                  line.contains('phase=$customPhase|') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          customTiming,
          hasLength(1),
          reason:
              'Custom phaseName must be threaded through to the inner-helper '
              'E2E_TIMING emission so distinct dispatch sites can stay '
              'separable in perf-timing dumps. Captured: $lines',
        );
        final defaultTiming = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissSnackBarPhase|') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          defaultTiming,
          isEmpty,
          reason:
              'A custom phaseName must NOT also surface under the default '
              'phase label; otherwise scrapers that aggregate by the default '
              'phase would double-count custom-labelled calls.',
        );
      },
    );
  });
}
