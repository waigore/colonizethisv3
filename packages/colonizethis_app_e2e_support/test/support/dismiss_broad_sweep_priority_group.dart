// Close-candidate priority pins for
// `e2e_dismiss_ct_dialog_shell_broad_sweep_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_widget_tester_harness.dart';

void registerDismissBroadSweepPriorityGroup() {
  group(
    'e2eDismissCtDialogShellBroadSweepIfPresent — close-candidate priority',
    () {
      testWidgets('taps Cancel first when both Cancel and Close are mounted', (
        WidgetTester tester,
      ) async {
        var cancelTaps = 0;
        var closeTaps = 0;
        await tester.pumpWidget(
          wrapDismissCentered(
            DismissCtDialogShellHost(
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
            wrapDismissCentered(
              DismissCtDialogShellHost(
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
            wrapDismissCentered(
              DismissCtDialogShellHost(
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
            wrapDismissCentered(
              DismissCtDialogShellHost(
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
}
