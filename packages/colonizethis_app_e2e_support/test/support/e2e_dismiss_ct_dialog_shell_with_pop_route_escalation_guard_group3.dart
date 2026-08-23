// Extracted from e2e_dismiss_ct_dialog_shell_with_pop_route_escalation_test.dart (#4598 Slice C).
library;

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'dismiss_widget_tester_harness.dart';

void registerE2eDismissCtDialogShellWithPopRouteEscalationGuardGroup3() {
  group(
    'e2eDismissCtDialogShellWithPopRouteEscalation — escalation branch',
    () {
      testWidgets('shell that survives e2eDismissTransientUi triggers the '
          'handlePopRoute + bounded pump-until escalation under the '
          'legacy phase label (fail-fast contract preserved)', (
        WidgetTester tester,
      ) async {
        // Shell with no Cancel / Close / Icons.close / Icons.arrow_back
        // inside, and not routed via Navigator.push — so neither the
        // labelled-candidate arm nor the handlePopRoute fallback inside
        // e2eDismissTransientUi can unmount it. The escalation arm then
        // fires its own handlePopRoute (also a no-op here) and pumps
        // until the bounded timeout. The shared `e2ePumpUntil` helper
        // calls [fail] when the condition stays false past the
        // timeout, so the helper rethrows the same `TestFailure` the
        // pre-lift inline block produced — pinning the fail-fast
        // contract the production opener relies on.
        await tester.pumpWidget(
          wrapDismissCentered(
            DismissCtDialogShellHost(
              builder: (context, close) =>
                  const Text('no dismiss target inside this shell'),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final perf = E2ePerfLog('escalation_branch');
        final lines = await captureE2eDebugPrints(expectThrows: true, () async {
          await dismissCtDialogShellWithPopRouteEscalation(
            tester,
            perf: perf,
            // Tight escalation budget so the bounded pump-until exits
            // promptly when the shell ignores handlePopRoute (the
            // scenario under test); the production opener uses the
            // 5 s default but the contract is identical.
            escalationTimeout: const Duration(milliseconds: 200),
          );
        });

        final escalationEvents = lines
            .where(
              (l) =>
                  l.startsWith('E2E_TIMING') &&
                  l.contains('phase=$kE2eDefaultCtDialogShellEscalationPhase'),
            )
            .toList();
        expect(
          escalationEvents,
          hasLength(1),
          reason:
              'Escalation pump-until must emit exactly one '
              'E2E_TIMING line under the legacy '
              'pump_until_production_path_shell_cleared phase so '
              'downstream wall-clock attribution stays intact after '
              'the inline → shared lift.',
        );
        expect(
          escalationEvents.single,
          contains('meta=result=timeout'),
          reason:
              'When the shell stays mounted past the escalation '
              'budget, `e2ePumpUntil` must emit `meta=result=timeout` '
              'before failing — preserving the legacy attribution that '
              'identifies a stuck shell as the cause.',
        );
      });

      testWidgets(
        'escalation phase label can be overridden so future openers can '
        'attribute the wait under their own phase namespace',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            wrapDismissCentered(
              DismissCtDialogShellHost(
                builder: (context, close) =>
                    const Text('still no dismiss target'),
              ),
            ),
          );
          expect(find.byType(CtDialogShell), findsOneWidget);

          const overridePhase = 'pump_until_custom_opener_shell_cleared';
          final perf = E2ePerfLog('escalation_phase_override');
          final lines = await captureE2eDebugPrints(
            expectThrows: true,
            () async {
              await dismissCtDialogShellWithPopRouteEscalation(
                tester,
                perf: perf,
                escalationPhase: overridePhase,
                escalationTimeout: const Duration(milliseconds: 200),
              );
            },
          );

          expect(
            lines.any(
              (l) =>
                  l.startsWith('E2E_TIMING') &&
                  l.contains('phase=$overridePhase'),
            ),
            isTrue,
            reason:
                'Overriding the escalationPhase parameter must redirect '
                'the bounded pump-until perf-timing emission, so future '
                'opener bodies can keep per-opener attribution distinct '
                'from the production-opener default.',
          );
          expect(
            lines.any(
              (l) =>
                  l.contains('phase=$kE2eDefaultCtDialogShellEscalationPhase'),
            ),
            isFalse,
            reason:
                'A call that overrides escalationPhase must not also '
                'emit the default phase label; otherwise log scrapers '
                'would see double-attribution per call.',
          );
        },
      );

      testWidgets('perf is optional — escalation arm runs without emitting any '
          'E2E_TIMING when perf is null', (WidgetTester tester) async {
        await tester.pumpWidget(
          wrapDismissCentered(
            DismissCtDialogShellHost(
              builder: (context, close) =>
                  const Text('no dismiss target either'),
            ),
          ),
        );

        final lines = await captureE2eDebugPrints(expectThrows: true, () async {
          await dismissCtDialogShellWithPopRouteEscalation(
            tester,
            escalationTimeout: const Duration(milliseconds: 200),
          );
        });

        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=$kE2eDefaultCtDialogShellEscalationPhase'),
          ),
          isFalse,
          reason:
              'When perf is null the escalation pump-until must not '
              'emit a perf event; e2ePumpUntil already guards the '
              'null branch, but this pin guards against a regression '
              'that forwarded a synthetic perf log here.',
        );
      });
    },
  );
}
