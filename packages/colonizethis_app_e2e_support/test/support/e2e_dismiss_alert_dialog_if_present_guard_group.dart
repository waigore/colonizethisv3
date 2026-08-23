// Extracted from e2e_dismiss_alert_dialog_if_present_test.dart (#4598 Slice C).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'dismiss_widget_tester_harness.dart';

void registerE2eDismissAlertDialogIfPresentGuardGroup() {
  group('e2eDismissAlertDialogIfPresent — handlePopRoute fallback', () {
    testWidgets(
      'falls back to handlePopRoute when no labelled button is present',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapDismissMaterial(
            DismissPostFrameDialogHost(
              dialogBuilder: (context) => const AlertDialog(
                title: Text('no-buttons-pin'),
                content: Text('AlertDialog with no labelled actions'),
              ),
            ),
          ),
        );
        await pumpDismissOverlaySettle(tester);
        expect(find.byType(AlertDialog), findsOneWidget);

        final dismissed = await e2eDismissAlertDialogIfPresent(tester);
        await pumpDismissPostTapSettle(tester);

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
          wrapDismissMaterial(
            DismissPostFrameDialogHost(
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
        await pumpDismissOverlaySettle(tester);

        final dismissed = await e2eDismissAlertDialogIfPresent(
          tester,
          dismissLabels: const <String>['Dismiss'],
        );
        await pumpDismissPostTapSettle(tester);

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
}
