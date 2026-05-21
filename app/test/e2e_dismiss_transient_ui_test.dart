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

  testWidgets(
    'e2eDismissTransientUi taps a top-level OK button',
    (WidgetTester tester) async {
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
    },
  );

  testWidgets(
    'e2eDismissTransientUi taps a labelled Close action on an AlertDialog',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _AlertDialogHost(
            actions: [
              TextButton(
                onPressed: () => Navigator.of(tester.element(find.text('Close'))).pop(),
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
}
