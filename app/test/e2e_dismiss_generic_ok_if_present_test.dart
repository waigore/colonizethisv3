/// Pins the widget-tree contract of [e2eDismissGenericOkIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_generic_ok.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its top-level OK branch (the layer between SnackBar and
/// AlertDialog dismissal). The pre-lift inline block lived in
/// `e2eDismissTransientUi` and used `find.text('OK').hitTestable()`
/// **unscoped** — that is, an `OK` label anywhere in the widget tree
/// outside an AlertDialog context would be tapped. The lifted form
/// preserves this behaviour byte-for-byte (same finder, same 2 s budget,
/// same tap-then-pump-until-empty contract) but moves it behind a focused
/// helper so future scenarios can compose it without going through the
/// whole broad sweep.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin. This pin guards:
///
/// - **No-OK short-circuit**: helper returns `false` without tapping or
///   pumping when no hit-testable `Text('OK')` is mounted; sibling
///   widgets that happen to host other labels must not be tapped.
/// - **Top-level OK happy path**: helper taps a hit-testable `Text('OK')`
///   widget anywhere in the tree (not just inside an `AlertDialog`),
///   returns `true`, and the label leaves the tree.
/// - **Hit-testable filter contract**: an `OK` label covered by an opaque
///   `AbsorbPointer` overlay is **not** tapped; the helper short-circuits
///   to `false` so the caller can fall back to a broader dismissal
///   strategy. A regression that dropped the `.hitTestable()` filter
///   would tap the covered label and starve subsequent phases on a
///   missed dismissal.
/// - **Custom label override**: passing `label: 'Dismiss'` (or similar)
///   targets the custom label instead of the default `'OK'`, preserving
///   the API surface the legacy inline block never exposed but the
///   lifted form intentionally supports.
/// - **Constant pins**: `kE2eDefaultGenericOkDismissTimeout` matches the
///   legacy 2 s budget; `kE2eDefaultGenericOkLabel` is `'OK'`.
/// - **Perf counter pin**: a single `dismiss_generic_ok_calls` bump fires
///   on success only — the no-OK short-circuit and covered-OK branches
///   do not emit.
///
/// Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards. Mirrors the helper used by the existing
/// `e2e_dismiss_snackbar_if_present_test.dart` /
/// `e2e_dismiss_alert_dialog_if_present_test.dart` pins so this file
/// verifies counter emission against the same
/// `E2E_COUNTER|...|name=dismiss_generic_ok_calls|value=...` substring
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

bool _hasGenericOkCounterLine(
  List<String> lines, {
  required String test,
  required int expectedValue,
}) {
  final needle =
      'E2E_COUNTER|test=$test|name=dismiss_generic_ok_calls'
      '|value=$expectedValue';
  return lines.any((line) => line == needle);
}

bool _hasAnyGenericOkCounterLine(List<String> lines, {required String test}) {
  final prefix = 'E2E_COUNTER|test=$test|name=dismiss_generic_ok_calls|';
  return lines.any((line) => line.startsWith(prefix));
}

/// Hosts an `OK` label inside a `Stack` with an opaque `AbsorbPointer`
/// overlay on top, so the label is **mounted but non-hit-testable**. The
/// helper must short-circuit to `false` in this fixture; a regression that
/// dropped `.hitTestable()` would tap the covered label and miss the
/// dismiss.
class _CoveredOkLabel extends StatelessWidget {
  const _CoveredOkLabel({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 48,
      child: Stack(
        children: [
          TextButton(onPressed: onTap, child: Text(label)),
          const Positioned.fill(
            child: AbsorbPointer(child: ColoredBox(color: Color(0xFFFF0000))),
          ),
        ],
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  group('e2eDismissGenericOkIfPresent — constant pins', () {
    test('kE2eDefaultGenericOkDismissTimeout matches legacy 2 s budget', () {
      // The legacy inline top-level OK branch of e2eDismissTransientUi used
      // a hardcoded 2 s timeout. A silent drift here would either inflate
      // the per-call dismiss window (regressing AC9 aggregate wall-clock)
      // or shrink it (risking false negatives when the dismiss animation
      // runs slow under load).
      expect(
        kE2eDefaultGenericOkDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultGenericOkDismissTimeout must preserve the legacy '
            '2 s inline budget to keep AC9 aggregate wall-clock attribution '
            'stable across the lift.',
      );
    });

    test('kE2eDefaultGenericOkLabel is the English literal OK', () {
      // Pre-lift literal in `e2eDismissTransientUi` was the bare English
      // 'OK'. A silent change would either miss the canonical confirmation
      // banner or tap the wrong label (for example a localised
      // 'OK'-equivalent that wasn't intentionally opted in).
      expect(
        kE2eDefaultGenericOkLabel,
        'OK',
        reason:
            'kE2eDefaultGenericOkLabel must preserve the legacy English '
            "'OK' literal so the broad-spectrum sweep continues to dismiss "
            'the canonical confirmation banner.',
      );
    });
  });

  group('e2eDismissGenericOkIfPresent — no-OK branch', () {
    testWidgets(
      'returns false without tapping when no hit-testable OK label is present',
      (WidgetTester tester) async {
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

        final dismissed = await e2eDismissGenericOkIfPresent(tester);

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must short-circuit and return false when no '
              'hit-testable OK label is present; otherwise a stray sibling '
              'TextButton elsewhere in the tree could be tapped between '
              'phases.',
        );
        expect(
          siblingTaps,
          0,
          reason:
              'No tap should fire when the generic-OK branch '
              'short-circuits.',
        );
      },
    );
  });

  group('e2eDismissGenericOkIfPresent — top-level OK happy path', () {
    testWidgets(
      'taps the hit-testable OK label, returns true, and removes it from '
      'the tree',
      (WidgetTester tester) async {
        var okTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => okTaps++,
                  child: const Text('OK'),
                ),
              ),
            ),
          ),
        );

        final dismissed = await e2eDismissGenericOkIfPresent(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          dismissed,
          isTrue,
          reason:
              'Helper must return true after tapping the hit-testable OK '
              'label so callers can short-circuit the broader dismissal '
              'sweep.',
        );
        expect(
          okTaps,
          1,
          reason:
              'The OK button must receive exactly one tap (regression '
              'guard against double-tap or missed-tap variants).',
        );
      },
    );

    testWidgets(
      'taps a top-level OK label even when no AlertDialog ancestor is '
      'present',
      (WidgetTester tester) async {
        var okTaps = 0;
        // The pre-lift inline block used `find.text('OK').hitTestable()`
        // **unscoped** — that is, an OK label anywhere in the widget tree
        // (outside an AlertDialog context) gets tapped. This pin guards
        // against a regression that accidentally scoped the finder to an
        // AlertDialog ancestor and silently stopped dismissing top-level
        // confirmation banners.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('host')),
              body: SafeArea(
                child: Container(
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => okTaps++,
                    child: const Text('OK'),
                  ),
                ),
              ),
            ),
          ),
        );

        final dismissed = await e2eDismissGenericOkIfPresent(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          okTaps,
          1,
          reason:
              'Top-level OK outside an AlertDialog must still be tapped '
              '(legacy inline block was unscoped). A regression that '
              'required an AlertDialog ancestor would silently stop '
              'dismissing canonical confirmation banners above the map HUD.',
        );
      },
    );
  });

  group('e2eDismissGenericOkIfPresent — hit-testable filter contract', () {
    testWidgets(
      'returns false when the OK label is mounted but covered by an opaque '
      'overlay',
      (WidgetTester tester) async {
        var okTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: _CoveredOkLabel(label: 'OK', onTap: () => okTaps++),
              ),
            ),
          ),
        );

        expect(
          find.text('OK'),
          findsOneWidget,
          reason:
              'Fixture must keep the OK label mounted (covered by an '
              'opaque overlay) so the hit-testable filter has a non-trivial '
              'choice to make.',
        );

        // A regression that drops `.hitTestable()` would resolve `OK` to
        // the covered button, tap it, and starve the next phase on a
        // missed dismissal. The lifted form filters covered labels out
        // up-front and returns `false` so the caller can fall back to a
        // broader dismissal strategy.
        final dismissed = await e2eDismissGenericOkIfPresent(tester);
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must return false when the only OK label is '
              'non-hit-testable; a regression that taps a covered button '
              'would silently miss the dismiss.',
        );
        expect(
          okTaps,
          0,
          reason:
              'No tap should fire when every OK candidate is '
              'non-hit-testable.',
        );
      },
    );
  });

  group('e2eDismissGenericOkIfPresent — custom label override', () {
    testWidgets(
      'taps the supplied custom label and ignores the default OK literal',
      (WidgetTester tester) async {
        var dismissTaps = 0;
        var okTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => okTaps++,
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () => dismissTaps++,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
        );

        final dismissed = await e2eDismissGenericOkIfPresent(
          tester,
          label: 'Dismiss',
        );
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          dismissTaps,
          1,
          reason:
              'Custom label override must tap the matching custom label '
              'exactly once.',
        );
        expect(
          okTaps,
          0,
          reason:
              'A custom label override must NOT fall back to the default '
              "'OK' literal; otherwise the override has no effect.",
        );
      },
    );
  });

  group('e2eDismissGenericOkIfPresent — perf counter bump pin', () {
    testWidgets(
      'emits exactly one E2E_COUNTER dismiss_generic_ok_calls bump on '
      'labelled-tap success',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_perf_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        late bool dismissed;
        final lines = await _captureDebugPrints(() async {
          dismissed = await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        expect(
          _hasGenericOkCounterLine(
            lines,
            test: 'generic_ok_perf_pin',
            expectedValue: 1,
          ),
          isTrue,
          reason:
              'Labelled-tap success must emit exactly one '
              'E2E_COUNTER|...|name=dismiss_generic_ok_calls|value=1 marker '
              'so observer dashboards can attribute the cost of stray '
              'top-level OK banners per scenario. Captured lines: $lines',
        );
        final bumpCount = lines
            .where(
              (line) => line.startsWith(
                'E2E_COUNTER|test=generic_ok_perf_pin|'
                'name=dismiss_generic_ok_calls|',
              ),
            )
            .length;
        expect(
          bumpCount,
          1,
          reason:
              'Success path must bump dismiss_generic_ok_calls exactly '
              'once; a regression that double-bumped would inflate '
              'downstream counter aggregations. Captured lines: $lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_generic_ok_calls when no OK label is present',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_perf_no_ok_pin');
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });

        expect(
          _hasAnyGenericOkCounterLine(lines, test: 'generic_ok_perf_no_ok_pin'),
          isFalse,
          reason:
              'No-OK short-circuit must not emit the counter marker (the '
              'helper returned false without tapping). Captured lines: '
              '$lines',
        );
      },
    );

    testWidgets(
      'does not emit dismiss_generic_ok_calls when the only OK is covered',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_perf_covered_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: _CoveredOkLabel(label: 'OK', onTap: () {}),
              ),
            ),
          ),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });

        expect(
          _hasAnyGenericOkCounterLine(
            lines,
            test: 'generic_ok_perf_covered_pin',
          ),
          isFalse,
          reason:
              'Covered-OK short-circuit must not emit the counter marker '
              '(the helper returned false without tapping). Captured '
              'lines: $lines',
        );
      },
    );
  });

  // The following group pins the inner-helper perf attribution surface added
  // alongside the dispatcher-level [e2eDismissTransientUi] result-tag
  // taxonomy (Refs GitHub #2336 AC8 baseline timing). The integration suite
  // cannot validate the inner-helper attribution directly today
  // (`app_e2e_linux` is a no-op per `SPEC/program/e2e-integration-tests.md` §
  // CI), so this widget-test layer is the only per-PR pin for the new
  // inner-helper markers and their `result=...` taxonomy.
  group('e2eDismissGenericOkIfPresent perf attribution', () {
    test(
      'phase constant matches the documented `dismiss_generic_ok` label',
      () {
        expect(
          kE2eDefaultDismissGenericOkPhase,
          'dismiss_generic_ok',
          reason:
              'Phase constant must stay byte-equivalent so the AC8 baseline '
              'timing pipeline can key on the same phase=... label as the '
              'docs in `SPEC/program/e2e-integration-tests.md` § Determinism '
              '(Dismiss-generic-OK inner perf attribution bullet).',
        );
      },
    );

    testWidgets(
      'emits result=not_present without the dispatcher counter when no '
      'hit-testable OK label is present',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_phase_not_present_pin');
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });

        final timing = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissGenericOkPhase') &&
                  line.startsWith('E2E_TIMING|'),
            )
            .toList();
        expect(
          timing,
          hasLength(1),
          reason:
              'Exactly one inner-helper `E2E_TIMING|phase=...` line must be '
              'emitted on the no-OK short-circuit. Captured: $lines',
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
          _hasAnyGenericOkCounterLine(
            lines,
            test: 'generic_ok_phase_not_present_pin',
          ),
          isFalse,
          reason:
              'No-OK short-circuit must not bump `dismiss_generic_ok_calls` '
              '(the helper returned false without tapping). Captured: $lines',
        );
      },
    );

    testWidgets(
      'emits result=tapped alongside the dispatcher counter when the OK '
      'label is dismissed',
      (WidgetTester tester) async {
        final perf = E2ePerfLog('generic_ok_phase_tapped_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        late bool dismissed;
        final lines = await _captureDebugPrints(() async {
          dismissed = await e2eDismissGenericOkIfPresent(tester, perf: perf);
        });
        await tester.pump(const Duration(milliseconds: 50));

        expect(dismissed, isTrue);
        final timing = lines
            .where(
              (line) =>
                  line.contains('phase=$kE2eDefaultDismissGenericOkPhase') &&
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
              'AC8 timing pipeline can separate real dismissals from cheap '
              'no-op short-circuits.',
        );
      },
    );

    testWidgets(
      'no perf line emitted when perf is null (default opt-out contract)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(tester);
        });
        await tester.pump(const Duration(milliseconds: 50));

        final phaseLines = lines
            .where(
              (line) =>
                  line.startsWith('E2E_TIMING|') &&
                  line.contains('phase=$kE2eDefaultDismissGenericOkPhase'),
            )
            .toList();
        expect(
          phaseLines,
          isEmpty,
          reason:
              'Default `perf: null` must preserve the byte-quiet contract: '
              'no `E2E_TIMING|phase=dismiss_generic_ok` line should be '
              'emitted for opt-out callers. Captured: $lines',
        );
      },
    );

    testWidgets(
      'custom phaseName reaches the inner-helper emission and does NOT also '
      'emit under the default label',
      (WidgetTester tester) async {
        const customPhase = 'generic_ok_custom_phase_label';
        final perf = E2ePerfLog('generic_ok_custom_phase_pin');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextButton(onPressed: () {}, child: const Text('OK')),
              ),
            ),
          ),
        );

        final lines = await _captureDebugPrints(() async {
          await e2eDismissGenericOkIfPresent(
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
                  line.contains('phase=$kE2eDefaultDismissGenericOkPhase|') &&
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
