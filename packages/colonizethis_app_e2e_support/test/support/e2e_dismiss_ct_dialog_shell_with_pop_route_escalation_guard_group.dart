// Extracted from e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_test.dart (#4598 Slice C).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

void registerE2eDismissCtDialogShellWithPopRouteEscalationGuardGroup() {
  group(
    'e2eDismissCtDialogShellWithPopRouteEscalation — default constants',
    () {
      test('kE2eDefaultCtDialogShellEscalationTimeout matches the legacy 5 s '
          'budget the inline production-opener block used', () {
        expect(
          kE2eDefaultCtDialogShellEscalationTimeout,
          const Duration(seconds: 5),
          reason:
              'A silent budget bump would change wall-clock guarantees '
              'for every call site that relies on the default; require '
              'an explicit override at the call site instead. Refs '
              'GitHub #2336 / AC4 / Bottleneck 7.',
        );
      });

      test('kE2eDefaultCtDialogShellEscalationPhase preserves the legacy '
          'E2E_TIMING phase the inline production-opener block emitted', () {
        expect(
          kE2eDefaultCtDialogShellEscalationPhase,
          'pump_until_production_path_shell_cleared',
          reason:
              'Phase string is consumed verbatim by log scrapers and '
              'dashboards that survived the inline → shared lift; '
              'renaming it would orphan downstream attribution and '
              'mask wall-clock regressions in the production opener.',
        );
      });
    },
  );
}
