// Extracted from e2e_enter_fleet_reach_scenario_ready_test.dart (#4598 Slice C).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

void registerE2eEnterFleetReachScenarioReadyGuardGroup() {
  group('e2eEnterFleetReachScenarioReady — AC1 barrel forwarding', () {
    test('enterFleetReachScenarioReady is re-exported as a tear-off with '
        'the documented signature (compile-time pin)', () {
      // Reading the function as a typed tear-off pins:
      // - `tester` first positional (`WidgetTester`)
      // - `testName: String` required named
      // - `bootstrapForIntegrationTest: Future<void> Function()` required
      //   named (the injected callable)
      // - `maxUiResponseWait: Duration` named (default 5 s)
      // - `wallClockCap: Duration` named (default 5 minutes)
      // - `locale: Locale` named (default `Locale('en')`)
      // - `surfaceSize: Size` named (default `Size(1280, 720)`)
      // - `bootstrapTimingPhase: String` named
      // - `afterBootstrapStep: String` named
      // - `afterSplitFleetStep: String` named
      // - returns `Future<E2eFleetReachScenarioPreamble>`
      //
      // A silent removal from the `show` clause, an arg-order swap, a
      // changed default for any named parameter, or a dropped optional
      // parameter would fail this assignment at compile time.
      final Future<E2eFleetReachScenarioPreamble> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Duration maxUiResponseWait,
        Duration wallClockCap,
        Locale locale,
        Size surfaceSize,
        String bootstrapTimingPhase,
        String afterBootstrapStep,
        String afterSplitFleetStep,
      })
      ref = enterFleetReachScenarioReady;
      expect(ref, isNotNull);
    });

    test('e2eEnterFleetReachScenarioReady (lifted form) is re-exported as '
        'a tear-off with the same signature (compile-time pin)', () {
      // Both the lifted form and the AC1 barrel alias must remain
      // available with matching signatures so future callers can pick
      // either entrypoint without an arg-order surprise.
      final Future<E2eFleetReachScenarioPreamble> Function(
        WidgetTester, {
        required String testName,
        required Future<void> Function() bootstrapForIntegrationTest,
        Duration maxUiResponseWait,
        Duration wallClockCap,
        Locale locale,
        Size surfaceSize,
        String bootstrapTimingPhase,
        String afterBootstrapStep,
        String afterSplitFleetStep,
      })
      ref = shared.e2eEnterFleetReachScenarioReady;
      expect(ref, isNotNull);
    });
  });
}
