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

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/dismiss_generic_ok_counter_group.dart';
import 'support/dismiss_generic_ok_perf_attribution_group.dart';
import 'support/dismiss_widget_tester_harness.dart';

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
        await pumpDismissPostTapSettle(tester);

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
        await pumpDismissPostTapSettle(tester);

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
                child: DismissCoveredOkLabel(label: 'OK', onTap: () => okTaps++),
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
        await pumpDismissPostTapSettle(tester);

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
        await pumpDismissPostTapSettle(tester);

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

  registerDismissGenericOkCounterGroup();
  registerDismissGenericOkPerfAttributionGroup();
}

