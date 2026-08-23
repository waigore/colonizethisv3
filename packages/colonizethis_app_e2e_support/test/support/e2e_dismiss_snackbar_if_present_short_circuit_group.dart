// Extracted from e2e_dismiss_snackbar_if_present_test.dart (#4598 Slice C).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'e2e_widget_pump_harness.dart';

void registerDismissSnackBarIfPresentShortCircuitGroup() {
  group('e2eDismissSnackBarIfPresent — no-SnackBar branch', () {
    testWidgets('returns false without tapping when no SnackBar is mounted', (
      WidgetTester tester,
    ) async {
      var siblingTaps = 0;
      await pumpE2eScaffold(
        tester,
        Center(
          child: TextButton(
            onPressed: () => siblingTaps++,
            child: const Text('sibling-action'),
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

  group('e2eDismissSnackBarIfPresent — constant pin', () {
    test('kE2eDefaultSnackBarDismissTimeout matches legacy 2 s budget', () {
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
}
