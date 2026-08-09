// Constant and no-shell pins for
// `e2e_dismiss_ct_dialog_shell_broad_sweep_if_present_test.dart`
// (Slice C / AC5 of #4195).
//
// Refs #4195.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'dismiss_widget_tester_harness.dart';

void registerDismissBroadSweepBaselineGroup() {
  group('e2eDismissCtDialogShellBroadSweepIfPresent — constant pins', () {
    test('kE2eDefaultCtDialogShellBroadSweepDismissTimeout matches legacy 2 s '
        'budget', () {
      expect(
        kE2eDefaultCtDialogShellBroadSweepDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultCtDialogShellBroadSweepDismissTimeout must '
            'preserve the legacy 2 s inline budget to keep AC9 aggregate '
            'wall-clock attribution stable across the lift.',
      );
    });
  });

  group('e2eDismissCtDialogShellBroadSweepIfPresent — no-shell branch', () {
    testWidgets(
      'returns false without tapping or popping when no CtDialogShell is '
      'mounted',
      (WidgetTester tester) async {
        var siblingTaps = 0;
        await tester.pumpWidget(
          wrapDismissCentered(
            TextButton(
              onPressed: () => siblingTaps++,
              child: const Text('Cancel'),
            ),
          ),
        );

        final dismissed = await e2eDismissCtDialogShellBroadSweepIfPresent(
          tester,
        );

        expect(
          dismissed,
          isFalse,
          reason:
              'Helper must short-circuit and return false when no '
              'CtDialogShell is mounted; otherwise a stray Cancel '
              'TextButton elsewhere in the tree would be tapped between '
              'phases.',
        );
        expect(
          siblingTaps,
          0,
          reason:
              'No tap should fire when the CtDialogShell branch '
              'short-circuits.',
        );
      },
    );
  });
}
