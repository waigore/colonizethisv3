// Extracted from e2e_dismiss_generic_ok_if_present_test.dart (#4598).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_generic_ok_counter_group.dart';
import 'dismiss_widget_tester_harness.dart';

void registerE2eDismissGenericOkIfPresentBranchGroup() {
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
                child: DismissCoveredOkLabel(
                  label: 'OK',
                  onTap: () => okTaps++,
                ),
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

}
