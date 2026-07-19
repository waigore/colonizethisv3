// Smoke tests for the shared dismiss WidgetTester harness (Refs #4075 AC5).
//
// Pins the harness contract that every migrated `e2e_dismiss_*` suite relies
// on: debugPrint capture, counter-line matchers, MaterialApp wraps/pumps,
// post-frame dialog / SnackBar / CtDialogShell hosts, and absorbPointerCover.

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dismiss_widget_tester_harness.dart';

void main() {
  suppressLogsForTests();

  test('captureE2eDebugPrints restores debugPrint and records lines', () async {
    final original = debugPrint;
    final lines = await captureE2eDebugPrints(() async {
      debugPrint('harness-smoke-line');
    });
    expect(lines, contains('harness-smoke-line'));
    expect(debugPrint, same(original));
  });

  test('hasE2eCounterLine / hasAnyE2eCounterLine match exact needles', () {
    const lines = <String>[
      'E2E_COUNTER|test=smoke|name=dismiss_alert_dialog_calls|value=1',
      'noise',
    ];
    expect(
      hasE2eCounterLine(
        lines,
        test: 'smoke',
        name: 'dismiss_alert_dialog_calls',
        expectedValue: 1,
      ),
      isTrue,
    );
    expect(
      hasE2eCounterLine(
        lines,
        test: 'smoke',
        name: 'dismiss_alert_dialog_calls',
        expectedValue: 2,
      ),
      isFalse,
    );
    expect(
      hasAnyE2eCounterLine(
        lines,
        test: 'smoke',
        name: 'dismiss_alert_dialog_calls',
      ),
      isTrue,
    );
    expect(
      hasAnyE2eCounterLine(
        lines,
        test: 'other',
        name: 'dismiss_alert_dialog_calls',
      ),
      isFalse,
    );
  });

  testWidgets('pumpDismissCentered hosts a child under MaterialApp/Scaffold', (
    WidgetTester tester,
  ) async {
    await pumpDismissCentered(tester, const Text('centered-smoke'));
    expect(find.text('centered-smoke'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('DismissPostFrameDialogHost shows dialog after overlay settle', (
    WidgetTester tester,
  ) async {
    await pumpDismissMaterial(
      tester,
      DismissPostFrameDialogHost(
        dialogBuilder: (_) => const AlertDialog(
          title: Text('dialog-smoke'),
        ),
      ),
    );
    await pumpDismissOverlaySettle(tester);
    expect(find.text('dialog-smoke'), findsOneWidget);
  });

  testWidgets('DismissSnackBarHost surfaces a SnackBar after settle', (
    WidgetTester tester,
  ) async {
    await pumpDismissMaterial(
      tester,
      DismissSnackBarHost(
        snackBar: const SnackBar(
          duration: Duration(seconds: 30),
          content: Text('snack-smoke'),
        ),
      ),
    );
    await pumpDismissOverlaySettle(tester);
    expect(find.text('snack-smoke'), findsOneWidget);
  });

  testWidgets('DismissCtDialogShellHost mounts CtDialogShell with close', (
    WidgetTester tester,
  ) async {
    await pumpDismissCentered(
      tester,
      DismissCtDialogShellHost(
        builder: (context, close) => TextButton(
          onPressed: close,
          child: const Text('close-smoke'),
        ),
      ),
    );
    expect(find.byType(CtDialogShell), findsOneWidget);
    await tester.tap(find.text('close-smoke'));
    await tester.pump();
    expect(find.byType(CtDialogShell), findsNothing);
  });

  testWidgets('absorbPointerCover leaves child non-hit-testable', (
    WidgetTester tester,
  ) async {
    var taps = 0;
    await pumpDismissCentered(
      tester,
      SizedBox(
        width: 120,
        height: 48,
        child: absorbPointerCover(
          child: TextButton(
            onPressed: () => taps++,
            child: const Text('covered-smoke'),
          ),
        ),
      ),
    );
    expect(find.text('covered-smoke').hitTestable(), findsNothing);
    expect(taps, 0);
  });
}
