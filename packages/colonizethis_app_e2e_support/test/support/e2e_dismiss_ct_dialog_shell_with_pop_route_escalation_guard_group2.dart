// Extracted from e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_test.dart (#4598 Slice C).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

void registerE2eDismissCtDialogShellWithPopRouteEscalationGuardGroup2() {
  group('e2eDismissCtDialogShellWithPopRouteEscalation — AC1 barrel alias', () {
    test('AC1 barrel alias dismissCtDialogShellWithPopRouteEscalation '
        'matches the shared implementation signature', () {
      // Compile-time pin via tear-off assignment: forwards to the
      // shared implementation in
      // e2e_test_shared_dismiss_ct_dialog_shell_escalation.dart. A
      // regression that drifted the signature (added a required
      // parameter, dropped perf, etc.) would fail to compile here.
      final Future<bool> Function(
        WidgetTester tester, {
        E2ePerfLog? perf,
        Duration escalationTimeout,
        String escalationPhase,
      })
      tearOff = dismissCtDialogShellWithPopRouteEscalation;
      expect(tearOff, isNotNull);
    });
  });
}
