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

import '../integration_test/e2e_helpers.dart';

class _ShellHost extends StatefulWidget {
  const _ShellHost({required this.builder});

  /// Builds the dialog contents; receives a [close] callback the inner
  /// widgets can invoke from their `onPressed` callbacks to unmount the
  /// shell. Avoids `tester.state` hops inside button taps that would
  /// otherwise add lookup noise unrelated to the helper contract.
  final Widget Function(BuildContext context, VoidCallback close) builder;

  @override
  State<_ShellHost> createState() => _ShellHostState();
}

class _ShellHostState extends State<_ShellHost> {
  bool open = true;

  void _close() {
    setState(() => open = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }
    return CtDialogShell(child: widget.builder(context, _close));
  }
}

Widget _wrap(Widget body) => MaterialApp(
  home: Scaffold(body: Center(child: body)),
);

/// Captures `debugPrint` lines while [body] runs so the test can assert on
/// `E2E_TIMING|...|phase=...` markers without leaking the override to the
/// rest of the suite. [body] may throw; captured lines are returned even
/// when it does, and the original `debugPrint` is restored before the
/// exception propagates.
Future<List<String>> _captureDebugPrint(
  Future<void> Function() body, {
  bool expectThrows = false,
}) async {
  final lines = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    lines.add(message ?? '');
  };
  try {
    await body();
    if (expectThrows) {
      throw StateError(
        'Expected body to throw but it returned normally; captured lines: '
        '$lines',
      );
    }
  } on TestFailure {
    if (!expectThrows) {
      rethrow;
    }
  } finally {
    debugPrint = original;
  }
  return lines;
}

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
          _wrap(
            TextButton(
              onPressed: () => unrelatedTaps++,
              child: const Text('Cancel'),
            ),
          ),
        );

        final perf = E2ePerfLog('no_shell_branch');
        final lines = await _captureDebugPrint(() async {
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
          _wrap(
            _ShellHost(
              builder: (context, close) =>
                  TextButton(onPressed: close, child: const Text('Cancel')),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final perf = E2ePerfLog('first_pass_dismiss');
        final lines = await _captureDebugPrint(() async {
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
          _wrap(
            _ShellHost(
              builder: (context, close) =>
                  const Text('no dismiss target inside this shell'),
            ),
          ),
        );
        expect(find.byType(CtDialogShell), findsOneWidget);

        final perf = E2ePerfLog('escalation_branch');
        final lines = await _captureDebugPrint(expectThrows: true, () async {
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
            _wrap(
              _ShellHost(
                builder: (context, close) =>
                    const Text('still no dismiss target'),
              ),
            ),
          );
          expect(find.byType(CtDialogShell), findsOneWidget);

          const overridePhase = 'pump_until_custom_opener_shell_cleared';
          final perf = E2ePerfLog('escalation_phase_override');
          final lines = await _captureDebugPrint(expectThrows: true, () async {
            await dismissCtDialogShellWithPopRouteEscalation(
              tester,
              perf: perf,
              escalationPhase: overridePhase,
              escalationTimeout: const Duration(milliseconds: 200),
            );
          });

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
          _wrap(
            _ShellHost(
              builder: (context, close) =>
                  const Text('no dismiss target either'),
            ),
          ),
        );

        final lines = await _captureDebugPrint(expectThrows: true, () async {
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
