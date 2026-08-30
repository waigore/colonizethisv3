/// Pins the widget-tree contract of
/// [e2eDismissCtDialogShellWithPopRouteEscalation]
/// (`app/integration_test/e2e_test_shared_dismiss_ct_dialog_shell_escalation.dart`).
///
/// The production-panel opener in `e2e_test_shared_panels.dart` calls this
/// helper exactly once per outer-loop iteration to clear a [CtDialogShell]
/// covering the empire production rail. A silent rename or behavioural
/// drift would either:
///
///   - Mask a stuck shell — by dropping the escalation arm — and leave the
///     opener spinning until the outer 20 s `Timed out opening production
///     panel` `fail()`; or
///   - Orphan the legacy `E2E_TIMING|...|phase=
///     pump_until_production_path_shell_cleared` perf-timing label so
///     downstream wall-clock attribution would lose the step entirely.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin.
///
/// Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'support/dismiss_widget_tester_harness.dart';
import 'support/e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_guard_group.dart';
import 'support/e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_guard_group2.dart';
import 'support/e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_guard_group3.dart';

void main() {
  suppressLogsForTests();

  group('e2eDismissCtDialogShellWithPopRouteEscalation — no shell branch', () {
    testWidgets(
      'returns false without invoking e2eDismissTransientUi when no shell',
      (WidgetTester tester) async {
        var unrelatedTaps = 0;
        // SnackBar / AlertDialog / BottomSheet / CtDialogShell are all
        // absent; if the helper accidentally called e2eDismissTransientUi
        // the broad-spectrum sweep would still no-op, but we additionally
        // pin that no perf event is emitted under the escalation phase
        // label so a future regression that always invoked the
        // escalation arm cannot pass silently.
        await tester.pumpWidget(
          wrapDismissCentered(
            TextButton(
              onPressed: () => unrelatedTaps++,
              child: const Text('Cancel'),
            ),
          ),
        );

        final perf = E2ePerfLog('no_shell_branch');
        final lines = await captureE2eDebugPrints(() async {
          final dismissed = await dismissCtDialogShellWithPopRouteEscalation(
            tester,
            perf: perf,
          );
          expect(
            dismissed,
            isFalse,
            reason:
                'Helper must short-circuit and return false when no '
                'CtDialogShell is mounted; otherwise a stray Cancel '
                'button elsewhere in the tree would be tapped between '
                'opener-loop iterations.',
          );
        });

        expect(
          unrelatedTaps,
          0,
          reason: 'No tap should fire when the shell is absent.',
        );
        expect(
          lines.any(
            (l) => l.contains('phase=$kE2eDefaultCtDialogShellEscalationPhase'),
          ),
          isFalse,
          reason:
              'Escalation arm must not run when no shell is mounted '
              'at entry; a regression that pumped the escalation phase '
              'on every call would burn 5 s of wall clock per '
              'outer-loop iteration in the production opener.',
        );
      },
    );
  });

  group(
    'e2eDismissCtDialogShellWithPopRouteEscalation — first-pass dismiss',
    () {
      testWidgets('broad-spectrum Cancel tap unmounts the shell and skips the '
          'escalation arm (returns true, no escalation phase emit)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          wrapDismissCentered(
            DismissCtDialogShellHost(
              builder: (context, close) =>
                  TextButton(onPressed: close, child: const Text('Cancel')),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final perf = E2ePerfLog('first_pass_dismiss');
        final lines = await captureE2eDebugPrints(() async {
          final dismissed = await dismissCtDialogShellWithPopRouteEscalation(
            tester,
            perf: perf,
          );
          expect(
            dismissed,
            isTrue,
            reason:
                'Helper must report dismissal when a shell was '
                'observed at entry, even if the broad-spectrum first '
                'pass cleared it without escalation.',
          );
        });

        expect(
          find.byType(CtDialogShell),
          findsNothing,
          reason:
              'Broad-spectrum first pass (Cancel tap) should unmount the '
              'shell; remaining mounted would indicate the helper '
              'skipped e2eDismissTransientUi entirely.',
        );
        expect(
          lines.any(
            (l) => l.contains('phase=$kE2eDefaultCtDialogShellEscalationPhase'),
          ),
          isFalse,
          reason:
              'Escalation pump-until phase must not emit when the first '
              'pass already cleared the shell; emitting it would orphan '
              'the legacy attribution and inflate the wall-clock budget '
              'by up to 5 s per call.',
        );
      });
    },
  );

  registerE2eDismissCtDialogShellWithPopRouteEscalationGuardGroup();

  registerE2eDismissCtDialogShellWithPopRouteEscalationGuardGroup2();

  registerE2eDismissCtDialogShellWithPopRouteEscalationGuardGroup3();
}
