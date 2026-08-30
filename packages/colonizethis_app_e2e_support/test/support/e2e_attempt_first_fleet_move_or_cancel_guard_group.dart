// Extracted from e2e_attempt_first_fleet_move_or_cancel_test.dart (#4598 Slice C).
library;

// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

void registerE2eAttemptFirstFleetMoveOrCancelGuardGroup() {
  group('e2eAttemptFirstFleetMoveOrCancel — default constants', () {
    test(
      'kE2eDefaultFirstFleetMoveDialogOpenTimeout matches legacy 5 s cap',
      () {
        expect(
          kE2eDefaultFirstFleetMoveDialogOpenTimeout,
          const Duration(seconds: 5),
        );
      },
    );
    test(
      'kE2eDefaultFirstFleetMoveConfirmReadyTimeout matches legacy 2 s cap',
      () {
        expect(
          kE2eDefaultFirstFleetMoveConfirmReadyTimeout,
          const Duration(seconds: 2),
        );
      },
    );
    test(
      'kE2eDefaultFirstFleetMoveDialogCloseTimeout matches legacy 10 s cap',
      () {
        expect(
          kE2eDefaultFirstFleetMoveDialogCloseTimeout,
          const Duration(seconds: 10),
        );
      },
    );
  });
}
