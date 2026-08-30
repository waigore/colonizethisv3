// Extracted from e2e_dismiss_ct_dialog_shell_if_present_test.dart (#4598 Slice C).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

void registerE2eDismissCtDialogShellIfPresentGuardGroup() {
  group('e2eDismissCtDialogShellIfPresent — default constants', () {
    test('kE2eDefaultCtDialogShellCloseTimeout matches legacy 3 s budget', () {
      expect(
        kE2eDefaultCtDialogShellCloseTimeout,
        const Duration(seconds: 3),
        reason:
            'A silent budget bump would change wall-clock guarantees for '
            'every call site that relies on the default; require an explicit '
            'override at the call site instead. Refs GitHub #2336 / AC4.',
      );
    });

    test(
      'kE2eDefaultCtDialogShellClosePhase preserves the legacy E2E_TIMING phase',
      () {
        expect(
          kE2eDefaultCtDialogShellClosePhase,
          'pump_until_shell_closed_after_close_candidate',
          reason:
              'Phase string is consumed verbatim by log scrapers and dashboards '
              'that survived the inline → shared lift; renaming it would '
              'orphan downstream attribution.',
        );
      },
    );
  });
}
