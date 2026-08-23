// Extracted from e2e_dismiss_generic_ok_if_present_test.dart (#4598 Slice C).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'dismiss_widget_tester_harness.dart';

void registerE2eDismissGenericOkIfPresentGuardGroup() {
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
}
